# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'foodcritic', :cookbook_paths => '.', :all_on_start => false do
  watch(%r{^attributes/(.+)\.rb$})
  watch(%r{^providers/(.+)\.rb})
  watch(%r{^recipes/(.+)\.rb$})
  watch(%r{^resources/(.+)\.rb})
  watch(%r{^templates/(.+)})
  watch('metadata.rb')
end

guard 'rspec', cmd: 'bundle exec rspec', :all_on_start => false do
  watch(%r{^spec/(.+)_spec\.rb$})
  watch(%r{^(recipes)/(.+)\.rb$})   { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/spec_helper.rb$})  { 'spec' }
  watch(%r{^recipes/(.+)\.rb$})     { 'spec' }
  watch(%r{^attributes/(.+)\.rb$})  { 'spec' }
  watch(%r{^files/(.+)})            { 'spec' }
  watch(%r{^templates/(.+)})        { 'spec' }
  watch(%r{^providers/(.+)\.rb})    { 'spec' }
  watch(%r{^resources/(.+)\.rb})    { 'spec' }
end

guard 'kitchen' do
  watch(%r{^.kitchen.yml$})
  watch(%r{test/.+})
  watch(%r{^recipes/(.+)\.rb$})
  watch(%r{^attributes/(.+)\.rb$})
  watch(%r{^files/(.+)})
  watch(%r{^templates/(.+)})
  watch(%r{^providers/(.+)\.rb})
  watch(%r{^resources/(.+)\.rb})
end

guard 'bundler' do
  watch('Gemfile')
end
