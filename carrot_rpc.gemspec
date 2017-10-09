# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "carrot_rpc/version"

Gem::Specification.new do |spec|
  spec.name          = "carrot_rpc"
  spec.version       = CarrotRpc::VERSION
  spec.authors       = ["Scott Hamilton", "Luke Imhoff", "Jeff Utter"]
  spec.email         = ["shamil614@gmail.com", "Kronic.Deth@gmail.com", "jeff@jeffutter.com"]

  spec.summary       = "Remote Procedure Call (RPC) using the Bunny Gem over RabbitMQ"
  spec.description   = "Streamlined approach to setting up RPC over RabbitMQ."
  spec.homepage      = "https://github.com/C-S-D/carrot_rpc"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  unless spec.respond_to?(:metadata)
    fail "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Production requirements

  # Common extensions from Rails
  spec.add_dependency "activesupport", ">= 4.2", "< 6.x"
  # The RabbitMQ library
  spec.add_dependency "bunny", "~> 2.2"

  # Development / Test Gems

  # debugger
  spec.add_development_dependency "byebug"
  # Gemfile support for grouping gems for development-only or test-only
  spec.add_development_dependency "bundler", "~> 1.9"
  # Running commandline scripts
  spec.add_development_dependency "rake", "~> 10.0"
  # Unit test framework
  spec.add_development_dependency "rspec"
  # Style-checker
  spec.add_development_dependency "rubocop", "~> 0.36.0"
  # Documentation
  spec.add_development_dependency "yard", "~> 0.8"

  spec.required_ruby_version = "~> 2.2"
end
