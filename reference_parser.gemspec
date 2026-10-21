# frozen_string_literal: true

require_relative "lib/reference_parser/version"

Gem::Specification.new do |spec|
  spec.name = "reference_parser"
  spec.version = ReferenceParser::VERSION
  spec.authors = [""]
  spec.email = [""]

  spec.summary = "Common public reference extraction & linking."
  spec.description = "Common public reference extraction & linking."
  spec.homepage = "https://github.com/criticaljuncture/reference_parser"
  spec.required_ruby_version = Gem::Requirement.new(">= 4.0.0")

  spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/criticaljuncture/reference_parser"
  spec.metadata["changelog_uri"] = "https://github.com/criticaljuncture/reference_parser"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "actionview"
  spec.add_dependency "htmlentities"
end
