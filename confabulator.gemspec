require File.expand_path("../lib/confabulator/version", __FILE__)

Gem::Specification.new do |gem|
    gem.name          = "cotag-confabulator"
    gem.version       = Confabulator::VERSION
    gem.license       = 'MIT'
    gem.authors       = ['Dan Nolan', "Stephen von Takach"]
    gem.email         = ["steve@cotag.me"]
    gem.homepage      = "https://github.com/cotag/confabulator"
    gem.summary       = "Video transcoding"
    gem.description   = "Opinionated video transcoding for the cloud"

    gem.required_ruby_version = '>= 1.9.2'
    gem.require_paths = ["lib"]

    gem.add_runtime_dependency     'libuv', '>= 0.11.20'
    gem.add_runtime_dependency     'streamio-ffmpeg'

    gem.add_development_dependency 'rspec', '>= 2.14'
    gem.add_development_dependency 'rake', '>= 10.1'
    gem.add_development_dependency 'yard'

    gem.files = Dir["{lib}/**/*"] + %w(Rakefile confabulator.gemspec README.md LICENSE)
    gem.test_files = Dir["spec/**/*"]
    gem.extra_rdoc_files = ["README.md"]
end
