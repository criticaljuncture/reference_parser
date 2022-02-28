# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "reference_parser"
require "rspec-html-matchers"
require "spec_helper"
require "byebug"
require "rainbow"

# Dir[('./lib/**/*.rb')].each { |f| require f }
# require "reference_parser"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  config.include RSpecHtmlMatchers

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
