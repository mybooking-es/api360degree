
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "api360degree/version"

Gem::Specification.new do |spec|
  spec.name          = "api360degree"
  spec.version       = Api360degree::VERSION
  spec.authors       = ["mybooking"]
  spec.email         = ["info@mybooking.es"]

  spec.summary       = %q{Send WhatsApp messages using 360 degree API.}
  spec.description   = <<-DESCRIPTION
    The purpose of this class is not to interact with the entire 360degree api. 
    Instead, it is designed as a start-pack that will quickly allow you to send 
    template based message (with placeholders) to your users. The only supported 
    template type is text in the body.
    Please note that you cannot initiate a freetext message with WhatsappAPI. 
    Instead, you must use a pre-approved template.
  DESCRIPTION
    
  spec.homepage      = "https://mybooking.es"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency "faraday"
end
