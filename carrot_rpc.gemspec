# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carrot_rpc/version'

Gem::Specification.new do |spec|
  spec.name          = "carrot_rpc"
  spec.version       = CarrotRpc::VERSION
  spec.authors       = ["Scott Hamilton"]
  spec.email         = ["shamil614@gmail.com"]

  spec.summary       = %q{Remote Procedure Call (RPC) using the Bunny Gem over RabbitMQ}
  spec.description   = %q{Streamlined approach to setting up RPC over RabbitMQ.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['carrot_rpc']
  spec.require_paths = ["lib"]

  # Production requirements
  spec.add_dependency "bunny", "~> 2.2"

  # Development / Test Gems
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug"
end
