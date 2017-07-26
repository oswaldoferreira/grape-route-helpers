require File.join(Dir.pwd, 'lib', 'grape-route-helpers', 'version')

Gem::Specification.new do |gem|
  gem.name        = 'grape-route-helpers'
  gem.version     = GrapeRouteHelpers::VERSION
  gem.licenses    = ['MIT']
  gem.summary     = 'Route helpers for Grape'
  gem.description = 'Route helpers for Grape'
  gem.authors     = ['Harper Henn']
  gem.email       = 'harper.henn@legitscript.com'
  gem.files       = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.homepage    = 'https://github.com/reprah/grape-route-helpers'

  gem.add_runtime_dependency 'grape', '>= 0.19.0'
  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'rake', '>= 11.0.0'

  gem.add_development_dependency 'pry'

  # Avoiding "NoMethodError: undefined method `last_comment' for #<Rake::Application:0x00000002b90698>"
  # See https://github.com/rspec/rspec-core/commit/8e723fc805e901ac4fa5483837138b175d411d6e
  gem.add_development_dependency 'rspec', '>= 3.5.0'
  gem.add_development_dependency 'rubocop'
end
