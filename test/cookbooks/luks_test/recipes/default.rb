include_recipe 'luks'

directory '/mnt/test' do
  action :create
end

execute 'create-block-device' do
  command 'dd if=/dev/urandom of=/luks-test bs=1M count=10'
  not_if { ::File.exists?('/luks-test') }
end

execute 'create-loopback-device' do
  command 'losetup /dev/loop0 /luks-test'
  not_if 'losetup /dev/loop0'
end

luks_device 'luks-open' do
  block_device '/dev/loop0'
  luks_name 'luks-test'
  action :open
  notifies :run, 'execute[format-luks]', :immediately
end

execute 'format-luks' do
  action :nothing
  command 'mkfs.ext2 -L luks-test /dev/mapper/luks-test'
end

luks_device 'luks-enable' do
  block_device '/dev/loop0'
  action :enable
  luks_name 'luks-test'
  key_slot 0
end

mount '/mnt/test' do
  action [:mount, :enable]

  device '/dev/mapper/luks-test'
end

file '/tmp/key_file' do
  content 'qwertyuiopqwertyuiop'
end

luks_key 'add-key-1' do
  block_device '/dev/loop0'
  key_file Chef::Config[:encrypted_data_bag_secret]
  new_key_file '/tmp/key_file'
  key_slot 1
end

luks_key 'add-key-2' do
  block_device '/dev/loop0'
  key 'qwertyuiopqwertyuiop'
  new_key 'poiuytrewqpoiuytrewq'
  key_slot 2
end

luks_key 'remove-key-2' do
  block_device '/dev/loop0'
  action :remove
  key_file '/tmp/key_file'
  key_slot 2
end

luks_key 'change-key' do
  block_device '/dev/loop0'
  key_file '/tmp/key_file'
  new_key 'poiuytrewqpoiuytrewq'
  key_slot 1
end

luks_key 'remove-key-1' do
  block_device '/dev/loop0'
  action :remove
  key_file Chef::Config[:encrypted_data_bag_secret]
  key_slot 1
end

