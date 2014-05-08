#
# Cookbook Name:: luks
# Provider:: key
#
# Copyright 2013, Digital Measures LLC
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

require 'tempfile'

include CryptSetup
include KeyHash

action :save do
  if @current_resource.enabled && @current_resource.matches
    Chef::Log.info "#{@new_resource} key slot enabled and matches hash - nothing to do."
  else
    if @new_resource.key
      @new_resource.key_file_temp = create_temp_file(@new_resource.key)
      @new_resource.key_file(new_resource.key_file_temp.path)
    end
    if @new_resource.new_key
      @new_resource.new_key_file_temp = create_temp_file(@new_resource.new_key)
      @new_resource.new_key_file(@new_resource.new_key_file_temp.path)
    end
    if @current_resource.enabled
      converge_by("Changing key for #{@new_resource}") do
        cryptsetup_key_change(
          @new_resource.block_device,
          @new_resource.key_slot,
          @new_resource.key_file,
          @new_resource.new_key_file
        )
      end
    else
      converge_by("Adding key for #{@new_resource}") do
        cryptsetup_key_add(
          @new_resource.block_device,
          @new_resource.key_slot,
          @new_resource.key_file,
          @new_resource.new_key_file
        )
      end
    end
    if @new_resource.key_file_temp
      @new_resource.key_file_temp.close!()
      @new_resource.key_file_temp = nil
    end
    if @new_resource.new_key_file_temp
      @new_resource.new_key_file_temp.close!()
      @new_resource.new_key_file_temp = nil
    end
    save_hash(
      @run_context.node[:luks][:key_hash_path],
      @new_resource.uuid,
      @new_resource.key_slot,
      @new_resource.new_key_hash
    )
  end
end

action :remove do
  if !@current_resource.enabled
    Chef::Log.info "#{@new_resource} already disabled - nothing to do."
  else
    if @new_resource.key
      @new_resource.key_file_temp = create_temp_file(@new_resource.key)
      @new_resource.key_file(@new_resource.key_file_temp.path)
    end
    converge_by("Removing key for #{@new_resource}") do
      cryptsetup_key_remove(
        @new_resource.block_device,
        @new_resource.key_slot,
        @new_resource.key_file
      )
    end
    if @new_resource.key_file_temp
      @new_resource.key_file_temp.close!()
      @new_resource.key_file_temp = nil
    end
  end
end

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::LuksKey.new(@new_resource.name)
  @current_resource.block_device(@new_resource.block_device)
  @current_resource.key_slot(@new_resource.key_slot)
  
  # Set up new resource here (rather than in the resource) as Chef may need to create files.
  if @new_resource.key
    @new_resource.key_hash = hash @new_resource.key
  elsif @new_resource.key_file
    @new_resource.key_hash = hash_file @new_resource.key_file
  end
  if @new_resource.new_key
    @new_resource.new_key_hash = hash @new_resource.new_key
  elsif @new_resource.new_key_file
    @new_resource.new_key_hash = hash_file @new_resource.new_key_file
  end
  @new_resource.uuid = cryptsetup_get_uuid(@new_resource.block_device)
    
  @current_resource.uuid = @new_resource.uuid

  @current_resource.key_hash = load_hash(
    @run_context.node[:luks][:key_hash_path],
    @current_resource.uuid,
    @current_resource.key_slot)
  
  @current_resource.enabled = cryptsetup_key_slot_enabled?(
    @current_resource.block_device,
    @current_resource.key_slot)
  @current_resource.matches = (
    @current_resource.key_hash == @new_resource.new_key_hash
  )
end

def create_temp_file(contents)
  file = Tempfile.new 'crypt'
  file.write contents
  file.flush
  file
end
