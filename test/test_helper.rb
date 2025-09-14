ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Configure shoulda-matchers
require "shoulda-matchers"
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

class ActiveSupport::TestCase
  extend Shoulda::Matchers::ActiveModel
  extend Shoulda::Matchers::ActiveRecord
end

# Configure mocha for mocking
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
