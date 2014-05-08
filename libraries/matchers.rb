if defined?(ChefSpec)
  def save_luks_key(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:luks_key, :save, resource_name)
  end
  def remove_luks_key(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:luks_key, :remove, resource_name)
  end
  
  def open_luks_device(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:luks_device, :open, resource_name)
  end  
  def enable_luks_device(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:luks_device, :enable, resource_name)
  end  
  def format_luks_device(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:luks_device, :device, resource_name)
  end
end