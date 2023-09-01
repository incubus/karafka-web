# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Metrics
          module Charts
            # Model for preparing data about topics states
            class Topics
              # @param topics_data [Hash] topics aggregated metrics data
              # @param period [Symbol] period that we are interested in
              def initialize(topics_data, period)
                @data = topics_data.to_h.fetch(period)
              end

              # @return [String] JSON with lags of each of the topics + total lag of all the topics
              #   from all the consumer groups.
              def lags_stored
                total = Hash.new { |h, v| h[v] = 0 }

                @data.to_h.each_value do |metrics|
                  metrics.each do |metric|
                    time = metric.first
                    lag_stored = metric.last[:lag_stored]

                    if lag_stored
                      total[time] ||= 0
                      total[time] += lag_stored
                    else
                      next if total.key?(time)

                      total[time] = nil
                    end
                  end
                end

                # Extract the lag stored only from all the data
                per_topic = @data.to_h.map do |topic, metrics|
                  extracted = metrics.map { |metric| [metric.first, metric.last[:lag_stored]] }

                  [topic, extracted]
                end.to_h

                # We name it with a space because someone may have a topic called "total" and we
                # want to avoid collisions
                per_topic.merge('total sum' => total.to_a).to_json
              end

              # @return [String] JSON with producers pace that represents high-watermarks sum for
              #   each topic
              def topics_pace
                topics = {}

                @data.to_h.each do |topic, metrics|
                  topic_without_cg = topic.split('[').first

                  # If we've already seen this topic data, we can skip
                  next if topics.include?(topic_without_cg)

                  topics[topic_without_cg] = metrics.map do |current|
                    [current.first, current.last[:pace]]
                  end
                end

                topics.each_value(&:compact!)
                topics.to_json
              end
            end
          end
        end
      end
    end
  end
end