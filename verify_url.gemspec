# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'verify_url/version'

Gem::Specification.new do |spec|
  spec.name          = "verify_url"
  spec.version       = VerifyUrl::VERSION
  spec.authors       = ["Adam Booth"]
  spec.email         = ["4rlm@protonmail.ch"]

  spec.summary       = %q{Follows URL redirects to retrieve final address and status}
  spec.description   = %q{Follows URL redirects to retrieve final address and status}
  spec.homepage      = "https://github.com/4rlm/verify_url"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry", "~> 0.10.4"

end
