require 'digest'
require 'fileutils'

module KeyHash
  def hash(key)
    Digest::SHA256.hexdigest key
  end
  def hash_file(filename)
    hash File.read filename
  end
  
  def load_hash(key_hash_path, uuid, key_slot)
    hash_file = _to_hash_filename(key_hash_path, uuid, key_slot)
    File.readable?(hash_file) ? File.read(hash_file) : nil
  end
  
  def save_hash(key_hash_path, uuid, key_slot, key_hash)
    FileUtils.mkdir_p(key_hash_path)
    
    hash_file = _to_hash_filename(key_hash_path, uuid, key_slot)
    
    File.open(hash_file, 'w') {|f| f.write(key_hash) }
  end
  
  def del_hash(key_hash_path, uuid, key_slot)
    hash_file = _to_hash_filename(key_hash_path, uuid, key_slot)
    if File.exists?
      File.delete(hash_file)
    end
  end
  
  def _to_hash_filename(key_hash_path, uuid, key_slot)
    File.join(key_hash_path, "#{uuid}-#{key_slot}")
  end
end