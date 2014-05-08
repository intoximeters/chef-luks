#
# Cookbook Name:: luks
# Resource:: key
#
# Copyright 2014, Digital Measures LLC
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
include KeyHash


actions :save, :remove
default_action :save

attribute :block_device,
  :name_attribute => true,
  :kind_of => String,
  :required => true

attribute :key,
  :kind_of => String
  
attribute :key_file,
  :kind_of => String,
  :default => Chef::Config[:encrypted_data_bag_secret]

attribute :new_key,
  :kind_of => String

attribute :new_key_file,
  :kind_of => String
  
attribute :key_slot,
  :kind_of => Integer,
  :required => true

attr_accessor :uuid
attr_accessor :key_hash
attr_accessor :key_file_temp
attr_accessor :new_key_hash
attr_accessor :new_key_file_temp
attr_accessor :enabled
attr_accessor :matches