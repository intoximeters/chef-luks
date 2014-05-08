require 'spec_helper'

describe 'luks_test' do
  it 'should install the required packages for LUKS on rhel' do
    if ['RedHat', 'RedHat7', 'Fedora'].include?(property[:os_by_host]['localhost'][:family])
      expect(package('util-linux')).to be_installed
      expect(package('device-mapper')).to be_installed
      expect(package('cryptsetup-luks')).to be_installed
    end
  end

  it 'should install the required packages for LUKS on debian' do
    if ['Debian', 'Ubuntu'].include?(property[:os_by_host]['localhost'][:family])
      expect(package('util-linux')).to be_installed
      expect(package('dmsetup')).to be_installed
      expect(package('cryptsetup')).to be_installed
    end
  end
  
  it 'should have a cryptsetup binary' do
    expect(command('which cryptsetup')).to return_exit_status 0
  end
  
  it 'should have a LUKS volume on /dev/loop0' do
    expect(command('blkid -t TYPE=crypto_LUKS -o device | grep \'/dev/loop0\'')).to return_exit_status 0
    expect(command('cryptsetup isLuks /dev/loop0')).to return_exit_status 0
  end
  
  it 'should update /etc/crypttab' do
    expect(file('/etc/crypttab')).to contain(/^luks-test/)
  end
  
  it 'should update /etc/fstab' do
    expect(file('/etc/fstab')).to contain(/^\/dev\/mapper\/luks-test/)
  end
  
  it 'should be mounted and writable' do
    expect(command('echo working > /mnt/test/there_it_is')).to return_exit_status 0
    expect(file('/mnt/test/there_it_is')).to be_file
  end
end
