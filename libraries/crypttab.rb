require 'fileutils'

module CryptTab
  def crypttab_enabled?(crypttab_file, block_device, luks_name, key_file)
    lines = File.open(crypttab_file, &:readlines)
    !lines.grep(Regexp.new("^#{luks_name}\s+#{block_device}\s+#{key_file}\s+luks[^\s]*\s*$")).empty?
  end

  def crypttab_enable(crypttab_file, block_device, luks_name, key_file, key_slot=nil)
    lines = File.open(crypttab_file, &:readlines)
    
    lines_new = _edit_crypttab_lines(lines, block_device, luks_name, key_file, key_slot)
    changed = !lines_new.nil?
    if changed
      crypttab_backup = "#{crypttab_file}.old"
      FileUtils.cp(crypttab_file, crypttab_backup, :preserve => true)
      File.open(crypttab_file, 'w') do |file|
        lines_new.each do |line|
          file.puts(line)
        end
        file.flush
      end
    end
    changed
  end

  def _edit_crypttab_lines(lines, block_device, luks_name, key_file, key_slot=nil)
    # Not using Chef::Util::FileEdit, as it's missing some methods to support true idempotence
    lines_new = []
    
    regexp_exact_match = Regexp.new("^#{luks_name}\s+#{block_device}\s+#{key_file}\s+luks.*$")
    regexp_block_device = Regexp.new("^[^\s]+(\s+)#{block_device}(\s+)[^s]+(\s+)luks.*$")
    
    changed = false
    found = false
    lines.each do |line|
      if line !~ regexp_exact_match && match = regexp_block_device.match(line)
        lines_new << "#{luks_name}#{match[1]}#{block_device}#{match[2]}#{key_file}#{match[3]}luks#{key_slot ? ",key-slot=#{key_slot}" : ''}"
        found = true
        changed = true
      else
        lines_new << line
      end
    end
    
    if !found
      lines_new << "#{luks_name}\t#{block_device}\t#{key_file}\tluks#{key_slot ? ",key-slot=#{key_slot}" : ''}"
      changed = true
    end
    
    changed ? lines_new : nil
  end
  
  def crypttab_disable(block_device)
    file = Chef::Util::FileEdit.new('/etc/crypttab')
  
    file.search_file_delete_line(
      Regexp.new("\s+#{block_device}\s")
    )
    file.write_file
    file.file_edited?
  end
end