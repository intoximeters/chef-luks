#
# Cookbook Name:: luks
# Provider:: device
#
# Copyright 2013, Intoximeters, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


class Chef::Exceptions::LUKS < RuntimeError; end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    converge_by("Create #{@new_resource}") do
      luks_format_device
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete #{@new_resource}") do
      luks_delete_device
    end
  else
    Chef::Log.info "#{@new_resource} doesn't exist - nothing to do."
  end
end

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::LuksDevice.new(@new_resource.name)
  @current_resource.key_file(@new_resource.key_file)

  if is_luks_device? @current_resource.block_device
    @current_resource.exists = true
  end
end

def is_luks_device?(block_device)
  cmd = Mixlib::ShellOut.new(
    '/sbin/cryptsetup', 'isLuks', block_device
    ).run_command

  cmd.exitstatus == 0
end

def append_to_crypttab(block_device, luks_name, key_file, options={})
  ::File.open('/etc/crypttab', 'a') do |crypttab|
    crypttab.puts("#{luks_name}\t#{block_device}\t#{key_file}")
  end
end

def remove_from_crypttab(luks_name, options={})
  ::File.open('/etc/crypttab', 'r+') do  |crypttab|
    filtered_crypttab_lines = crypttab.readlines.find_all { |line| line.index(new_resource.luks_name) != 0}
    crypttab.rewind
    filtered_crypttab_lines.each do |fline|
      crypttab.write fline
    end
    crypttab.flush
    crypttab.truncate(crypttab.pos)
  end
end

def luks_open_device
  cmd = Mixlib::ShellOut.new(
    '/sbin/cryptsetup', '-q', '-d', new_resource.key_file, 'luksOpen',
    new_resource.block_device, new_resource.luks_name).run_command

  raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0

  append_to_crypttab new_resource.block_device,
    new_resource.luks_name, new_resource.key_file
end

def luks_close_device
  cmd = Mixlib::ShellOut.new(
    '/sbin/cryptsetup', 'luksClose', new_resource.luks_name).run_command
  raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  cmd.exitstatus == 0
end


def luks_format_device
  cmd = Mixlib::ShellOut.new(
    '/sbin/cryptsetup', '-q', 'luksFormat',
    new_resource.block_device, new_resource.key_file).run_command

  if cmd.exitstatus == 0
    luks_open_device
  else
    raise Chef::Exceptions::LUKS.new cmd.stderr
  end
end

def luks_delete_device
  if(luks_close_device)
    luks_destroy_header
    remove_from_crypttab new_resource.block_device
  end
end

def luks_destroy_header

  ::File.open('/dev/urandom', 'r') do |randombytes|
    ::File.open(new_resource.block_device, "r+") do |block_device|
      totalbytes = 10 * (1024 ** 2)
      while(block_device.pos < totalbytes)
        Chef::Log.debug "%.2f percent complete\n" %  ((block_device.pos.to_f / totalbytes) * 100)
        block_device.write randombytes.read(4096)
      end
    end
  end
end
