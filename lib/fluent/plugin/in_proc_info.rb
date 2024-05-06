# frozen_string_literal: true

#
# Copyright 2024- Thomas Tych
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/input'

require_relative 'proc_info'

module Fluent
  module Plugin
    class ProcInfoInput < Fluent::Plugin::Input
      NAME = 'proc_info'

      DEFAULT_TAG = NAME
      DEFAULT_INTERVAL = 60
      DEFAULT_PROBES = [].freeze
      DEFAULT_TIMESTAMP_KEY = 'timestamp'
      DEFAULT_TIMESTAMP_FORMAT = :iso

      Fluent::Plugin.register_input(NAME, self)

      helpers :event_emitter, :timer

      desc 'tag to emit events on'
      config_param :tag, :string, default: DEFAULT_TAG

      desc 'interval for probe execution'
      config_param :interval, :time, default: DEFAULT_INTERVAL

      config_section :process, param_name: :processes, multi: true do
        desc 'from pid'
        config_param :pid, :string, default: nil
        desc 'from pid file content'
        config_param :pid_file, :string, default: nil
      end

      desc 'probes to collect'
      config_param :probes, :array, default: DEFAULT_PROBES, value_type: :string

      desc 'timestamp key'
      config_param :timestamp_key, :string, default: DEFAULT_TIMESTAMP_KEY
      desc 'timestamp format'
      config_param :timestamp_format, :enum, list: %i[iso epochmillis],
                                             default: DEFAULT_TIMESTAMP_FORMAT

      desc 'data field prefix'
      config_param :event_prefix, :string, default: ''
      desc 'metadata field prefix'
      config_param :metadata_prefix, :string, default: ''

      attr_reader :info_processes, :eventer

      def configure(conf)
        super

        raise Fluent::ConfigError, "#{NAME}: `tag` must be specified" if tag.nil? || tag.empty?
        raise Fluent::ConfigError, "#{NAME}: `interval` must >= 1" if interval < 1
        raise Fluent::ConfigError, "#{NAME}: `probes` must not be empty" if probes.empty?

        configure_eventer
        configure_processes
      end

      def configure_eventer
        if timestamp_key.empty?
          raise Fluent::ConfigError,
                "#{NAME}: `timestamp_key` must not be empty"
        end

        @eventer = ProcInfo::Eventer.new(
          timestamp_key: timestamp_key,
          timestamp_format: timestamp_format,
          event_prefix: event_prefix,
          metadata_prefix: metadata_prefix
        )
      end

      def configure_processes
        raise Fluent::ConfigError, "#{NAME}: no `process` definition found" if processes.empty?

        @info_processes = processes.map do |process|
          ProcInfo::Process.new(pid: process.pid, pid_file: process.pid_file, eventer: eventer,
                                logger: log)
        rescue StandardError => e
          raise Fluent::ConfigError, "#{NAME}: #{e}"
        end
      end

      def multi_workers_ready?
        true
      end

      def start
        super

        timer_execute(:run_first, 1, repeat: false, &method(:run)) if interval > 60
        timer_execute(:run_interval, interval, repeat: true, &method(:run))
      end

      def run
        info_processes.each do |info_process|
          events = info_process.probe(probes: probes)
          emit_events(events)
        end
      end

      def emit_events(events)
        return if events.nil? || events.empty?

        time = Fluent::Engine.now
        mes = MultiEventStream.new
        events.each do |event|
          event = reformat_event(event)
          mes.add(time, event)
        end
        router.emit_stream(tag, mes)
      end

      def reformat_event(event)
        # FIXME
        # - prefix data
        # - prefix metadata
        # - timestamp
        event
      end
    end
  end
end
