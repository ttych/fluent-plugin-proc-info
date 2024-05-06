# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/in_proc_info'

class ProcInfoInTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case 'configuration' do
    test 'default configuration' do
      driver = create_driver
      input = driver.instance

      assert input
      # to be completed ...
    end

    test 'tag should not be empty' do
      assert_raise(Fluent::ConfigError) do
        create_driver('')
      end
    end
  end

  private

  BASE_CONF = %(
    tag test
  )

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::ProcInfoInput).configure(conf)
  end
end
