lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-http-pull"
  spec.version = "0.3.0"
  spec.authors = ["filepang"]
  spec.email   = ["filepang@gmail.com"]

  spec.summary       = %q{fluent-plugin-http-pull}
  spec.description   = %q{The input plugin of fluentd to pull log from rest api}
  spec.homepage      = "https://github.com/HatsuneMiku3939/fluent-plugin-http-pull"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1'

  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "test-unit-rr", "~> 1.0", "~> 1.0.2"
  spec.add_development_dependency "coveralls", "~> 0.7"

  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  spec.add_runtime_dependency "rest-client", [">= 2.0.0", "< 3"]
end
