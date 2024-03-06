# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "reference_parser"
require "rspec-html-matchers"
require "spec_helper"
require "byebug"
require "rainbow"
require_relative "helpers/cfr_helper"
require_relative "helpers/example_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  config.include RSpecHtmlMatchers
  config.extend ExampleHelper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
