# encoding: ascii-8bit

# Copyright 2021 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder

require 'cosmos/microservices/microservice'
require 'cosmos/topics/topic'

module Cosmos

  class DecomLogMicroservice < Microservice

    METRIC_NAME = "decom_log_duration_seconds"

    def run
      plws = setup_plws
      while true
        break if @cancel_thread
        Topic.read_topics(@topics) do |topic, msg_id, msg_hash, redis|
          break if @cancel_thread
          decom_log_data(plws, topic, msg_id, msg_hash, redis)
        end
      end
    end

    def setup_plws
      plws = {}
      @topics.each do |topic|
        topic_split = topic.split("__")
        scope = topic_split[0]
        target_name = topic_split[2]
        packet_name = topic_split[3]
        remote_log_directory = "#{scope}/decomlogs/tlm/#{target_name}/#{packet_name}"
        label = "#{scope}__#{target_name}__#{packet_name}__decom"
        # NOTE: Setting a cycle time of 3600s means the DecomMicroservice must allow for at LEAST
        # 3600s worth of data in the Redis stream. This is due to how the streaming_api works
        # when switching between a closed log file and the active Redis stream.
        plws[topic] = PacketLogWriter.new(remote_log_directory, label, true, 3600, nil)
      end
      return plws
    end

    def decom_log_data(plws, topic, msg_id, msg_hash, redis)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      topic_split = topic.split("__")
      target_name = topic_split[2]
      packet_name = topic_split[3]

      plws[topic].write(:JSON_PACKET, :TLM, target_name, packet_name, msg_hash["time"].to_i, ConfigParser.handle_true_false(msg_hash["stored"]), msg_hash["json_data"], nil)
      @count += 1
      diff = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start # seconds as a float
      metric_labels = { "packet" => packet_name, "target" => target_name }
      @metric.add_sample(name: METRIC_NAME, value: diff, labels: metric_labels)
    rescue => err
      @error = err
      Logger.error("DecomLog error: #{err.formatted}")
    end

  end
end

Cosmos::DecomLogMicroservice.run if __FILE__ == $0