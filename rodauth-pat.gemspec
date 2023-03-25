# frozen_string_literal: true

require_relative "lib/rodauth/pat/version"

Gem::Specification.new do |spec|
  spec.name = "rodauth-pat"
  spec.version = Rodauth::Pat::VERSION
  spec.authors = ["Jonas Mueller"]
  spec.email = ["jonas@tigger.cloud"]

  spec.summary = "Implementation of personal access tokens oon top of rodauth."
  spec.description = "Implementation of personal access tokens oon top of rodauth."
  spec.homepage = "https://github.com/muellerj/rodauth-pat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "rodauth", "~> 2.0"
end
