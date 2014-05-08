class Chef::Exceptions::LUKS < RuntimeError; end

module CryptSetup
  include Chef::Mixin::ShellOut
  
  def cryptsetup_device_opened?(luks_name)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          'status', luks_name
    ).run_command
    cmd.exitstatus == 0
  end
  
  def cryptsetup_device_open(block_device, luks_name, key_file, key_slot=nil)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          '--batch-mode',
          '--key-file', key_file,
          *(key_slot ? ['--key_slot', key_slot] : []),
          'luksOpen', block_device, luks_name
    ).run_command

    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  end
  
  def cryptsetup_device_formatted?(block_device)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          'isLuks', block_device
    ).run_command

    cmd.exitstatus == 0
  end
  
  def cryptsetup_device_format(block_device, key_file, key_slot)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
        '--batch-mode',
        *(key_slot ? ['--key_slot', key_slot] : []),
        'luksFormat', block_device, key_file
    ).run_command
  
    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  end
  
  def cryptsetup_get_uuid(block_device)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          'luksUUID', block_device
    ).run_command
  
    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  
    cmd.stdout.strip
  end
  
  def cryptsetup_key_slot_enabled?(block_device, key_slot)
    slots_enabled = cryptsetup_key_slots_enabled?(block_device)
    slots_enabled.find { |slot| key_slot.to_s == slot }
  end
  
  def cryptsetup_key_slots_enabled?(block_device)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          'luksDump', block_device
    ).run_command
  
    slots_enabled = []
    if cmd.exitstatus == 0
      regex = Regexp.new("^Key Slot ([0-7]):\s+ENABLED")
      cmd.stdout.each_line do |line|
        matches = regex.match(line)
        slots_enabled << matches[1] if matches
      end
    end
    slots_enabled  
  end
  
  def cryptsetup_key_change(block_device, key_slot, key_file, new_key_file)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          '--batch-mode',
          '--key-file', key_file,
          '--key-slot', key_slot.to_s,
          'luksChangeKey', block_device, new_key_file
    ).run_command
    
    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  end
  
  def cryptsetup_key_add(block_device, key_slot, key_file, new_key_file)
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          '--batch-mode',
          '--key-file', key_file,
          '--key-slot', key_slot.to_s,
          'luksAddKey', block_device, new_key_file
    ).run_command
    
    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  end
  
  def cryptsetup_key_remove(block_device, key_slot, key_file)
    key_slots = cryptsetup_key_slots_enabled?(block_device)
    if key_slots.count == 1 and key_slots.first == key_slot
      raise Chef::Exceptions::LUKS.new "Attempted to remove last key slot #{key_slot} from device #{block_device}!"
    end
    
    cmd = Mixlib::ShellOut.new(
      '/sbin/cryptsetup',
          '--batch-mode',
          '--key-file', key_file,
          'luksKillSlot', block_device, key_slot.to_s
    ).run_command
    
    raise Chef::Exceptions::LUKS.new cmd.stderr if cmd.exitstatus != 0
  end
end