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

include CryptSetup
include CryptTab

action :enable do
  if @current_resource.enabled
    Chef::Log.info "#{@new_resource} is already enabled - nothing to do."
  else
    converge_by("Enabling #{@new_resource}") do
      crypttab_enable(
        @run_context.node[:luks][:crypttab_path],
        new_resource.block_device,
        new_resource.luks_name,
        new_resource.key_file,
        new_resource.key_slot
      )
    end
  end
end

action :open do
  if @current_resource.opened
    Chef::Log.info "#{@new_resource} is already open - nothing to do."
  else
    action_format
    converge_by("Opening #{@new_resource}") do
      cryptsetup_device_open(
        new_resource.block_device,
        new_resource.luks_name,
        new_resource.key_file,
        new_resource.key_slot
      )
    end
  end
end

action :format do
  if @current_resource.formatted
    Chef::Log.info "#{@new_resource} is already formatted - nothing to do."
  else
    converge_by("Formatting #{@new_resource}") do
      cryptsetup_device_format(
        new_resource.block_device,
        new_resource.key_file,
        new_resource.key_slot
      )
    end
  end
end

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::LuksDevice.new(@new_resource.name)
  @current_resource.block_device(@new_resource.block_device)
  @current_resource.key_file(@new_resource.key_file)
  @current_resource.luks_name(@new_resource.luks_name)

  if cryptsetup_device_formatted? @current_resource.block_device
    @current_resource.formatted = true
    
    if cryptsetup_device_opened? @current_resource.luks_name
      @current_resource.opened = true
    end
  end
  @current_resource.enabled = crypttab_enabled?(
    @run_context.node[:luks][:crypttab_path],
    @current_resource.block_device,
    @current_resource.luks_name,
    @current_resource.key_file
  )
end
