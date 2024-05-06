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

    test 'tag has a default value set to proc_info' do
      driver = create_driver
      input = driver.instance

      assert_equal 'proc_info', input.tag
    end

    test 'tag should not be empty' do
      assert_raise(Fluent::ConfigError) do
        create_driver('probes net')
      end
    end

    test 'probes should not be empty' do
      assert_raise(Fluent::ConfigError) do
        create_driver('tag test')
      end
    end

    test 'interval has a default to 60' do
      driver = create_driver
      input = driver.instance

      assert_equal 60, input.interval
    end

    test 'interval should be greater than 1' do
      assert_raise(Fluent::ConfigError) do
        create_driver(%(
          #{BASE_CONF}
          interval 0
        ))
      end
    end

    test 'timestamp_key should not be empty' do
      assert_raise(Fluent::ConfigError) do
        create_driver(%(
          #{BASE_CONF}
          timestamp_key
        ))
      end
    end

    test 'event_prefix is empty by default' do
      driver = create_driver
      input = driver.instance

      assert_equal '', input.event_prefix
    end

    test 'metadata_prefix is empty by default' do
      driver = create_driver
      input = driver.instance

      assert_equal '', input.metadata_prefix
    end
  end

  private

  BASE_CONF = %(
    probes net

    <process>
      pid self
    </process>
  )

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::ProcInfoInput).configure(conf)
  end
end
