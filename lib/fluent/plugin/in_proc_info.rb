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

module Fluent
  module Plugin
    class ProcInfoInput < Fluent::Plugin::Input
      NAME = 'proc_info'

      Fluent::Plugin.register_input(NAME, self)

      helpers :event_emitter, :timer

      desc 'tag to emit events on'
      config_param :tag, :string, default: nil

      def configure(conf)
        super

        return unless @tag.nil?

        raise Fluent::ConfigError, 'out_record_splitter: `tag` must be specified'
      end
    end
  end
end
