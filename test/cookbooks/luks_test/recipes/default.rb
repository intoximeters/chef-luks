directory '/mnt/test' do
  action :create
end

execute 'create-loopback-device' do
  command <<-EOF
dd of=/luks-test bs=1G count=0 seek=1
losetup /dev/loop0 /luks-test
EOF
end

execute 'create-loopback-device-1' do
  command <<-EOF
dd of=/luks-delete-test bs=1G count=0 seek=1
losetup /dev/loop1 /luks-delete-test
EOF
end

execute 'format-luks' do
  action :nothing
  command 'mkfs.ext2 -L luks-test /dev/mapper/luks-test'
end

luks_device '/dev/loop0' do
  action :create
  notifies :run, 'execute[format-luks]', :immediately
  luks_name 'luks-test'
end

luks_device '/dev/loop1' do
  action [:create, :delete]
  luks_name 'luks-delete-test'
end

mount '/mnt/test' do
  action [:mount, :enable]

  device '/dev/mapper/luks-test'
end
