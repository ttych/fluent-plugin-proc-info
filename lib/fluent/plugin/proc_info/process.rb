# frozen_string_literal: true

require 'procfs2'

module Fluent
  module Plugin
    module ProcInfo
      class Process
        attr_reader :eventer, :logger

        def initialize(pid: nil, pid_file: nil, eventer: nil, logger: nil)
          @pid = pid
          @pid_file = pid_file
          @eventer = eventer
          @logger = logger

          validate_pid
        end

        def probe(probes: [])
          events = []

          probes.each do |probe|
            events += send("probe_#{probe}")
          rescue StandardError => e
            log.error("Process probe error with probe `#{probe}`: #{e}")
          end

          events
        end

        def probe_net
          probe_net_tcp + probe_net_udp
        end

        def probe_net_tcp
          net_inodes = proc.pid(pid).fd.select { |fd| fd.type == 'socket' }.map(&:inode)
          proc_net_tcp = proc.net.tcp
          tcp_sockets = net_inodes.map { |net_inode| proc_net_tcp.by_inode(net_inode) }.compact

          incomings = {}
          outgoings = {}
          remainings = []

          local_port_groups = tcp_sockets.group_by(&:local_port)
          local_port_groups.each_value do |sockets|
            next if sockets.empty?

            if sockets.size == 1 && sockets.first.state_str != 'LISTEN'
              remainings << sockets.first
              next
            end
            incomings.update(sockets.group_by { |socket| [socket.local_port, socket.state_str] })
          end

          r_tcp_sockets = remainings
          remainings = []
          remote_port_groups = r_tcp_sockets.group_by(&:remote_port)
          remote_port_groups.each_value do |sockets|
            next if sockets.empty?

            if sockets.size == 1
              remainings << sockets.first
              next
            end
            outgoings.update(sockets.group_by { |socket| [socket.remote_port, socket.state_str] })
          end

          remainings = remainings.group_by(&:state_str)

          events = incomings.map do |group_attrs, sockets|
            eventer.generate_event(
              name: 'connection_count',
              value: sockets.size,
              metadata: {
                protocol: 'tcp',
                direction: 'in',
                port: group_attrs[0],
                state: group_attrs[1]
              }
            )
          end
          outgoings.each do |group_attrs, sockets|
            events << eventer.generate_event(
              name: 'connection_count',
              value: sockets.size,
              metadata: {
                protocol: 'tcp',
                direction: 'out',
                port: group_attrs[0],
                state: group_attrs[1]
              }
            )
          end
          remainings.each do |state, sockets|
            events << eventer.generate_event(
              name: 'connection_count',
              value: sockets.size,
              metadata: {
                protocol: 'tcp',
                direction: 'unknown',
                port: nil,
                state: state
              }
            )
          end

          events
        end

        def probe_net_udp
          []
        end

        private

        def validate_pid
          return if (@pid && !@pid_file) || (!@pid && @pid_file)

          raise 'process definition should have pid XOR pid_file entry'
        end

        def pid
          return @pid if @pid

          begin
            return File.read(@pid_file).strip
          rescue StandardError => e
            log&.warn("error while loading pid file #{@pid_file}: #{e}")
          end

          nil
        end

        def log
          logger
        end

        def proc
          Procfs2.proc
        end
      end
    end
  end
end
