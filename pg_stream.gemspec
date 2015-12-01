# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_stream/version'

Gem::Specification.new do |spec|
  spec.name          = 'pg_stream'
  spec.version       = PgStream::VERSION
  spec.authors       = ['Rob Froetscher', 'Andrew Xue']
  spec.email         = ['rfroetscher@lumoslabs.com', 'andrew@lumoslabs.com']

  spec.summary       = %q{Stream data from postgres or Redshift}
  spec.homepage      = 'https://github.com/lumoslabs/pg_stream'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0.0'

  spec.add_dependency 'pg', '~> 0.18.2'
end
