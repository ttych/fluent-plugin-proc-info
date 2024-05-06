# frozen_string_literal: true

require 'procfs2'

module Fluent
  module Plugin
    module ProcInfo
      class Eventer
        attr_reader :timestamp_key, :timestamp_format, :event_prefix, :metadata_prefix

        def initialize(timestamp_key:,
                       timestamp_format:,
                       event_prefix:,
                       metadata_prefix:)
          @timestamp_key = timestamp_key
          @timestamp_format = timestamp_format
          @event_prefix = event_prefix
          @metadata_prefix = metadata_prefix
        end

        def generate_event(name:, value:, metadata: {})
          base.update({
                        "#{event_prefix}name" => name,
                        "#{event_prefix}value" => value
                      })
              .update(metadata.transform_keys { |k| "#{metadata_prefix}#{k}" })
        end

        private

        def base
          { timestamp_key.to_s => timestamp }
        end

        def timestamp
          send("timestamp_#{timestamp_format}")
        end

        def timestamp_epochmillis
          (Time.now.utc.to_f * 1000).to_i
        end

        def timestamp_iso
          Time.now.utc.iso8601(3)
        end
      end
    end
  end
end
