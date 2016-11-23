# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_collection/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_collection"
  spec.version       = RedisCollection::VERSION
  spec.authors       = ["Maxim Chernyak"]
  spec.email         = ["max@crossfield.com"]

  spec.summary       = %q{Sync an iterable ruby object with a redis namespace.}
  spec.homepage      = "https://github.com/crossfield/redis_collection"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mock_redis", "~> 0.17"
end
