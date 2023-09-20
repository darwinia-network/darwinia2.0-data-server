require 'graphlient'
require_relative 'subsquid_client'

module CommissionUpdates
  class << self
    def query(client, timestamp_gt = "2023-07-07T00:00:00.000000Z", id_gt = '0', try = 0)
      try += 1

      query_str = <<~GRAPHQL
        query($id_gt: String, $timestamp_gt: DateTime) {
          events(
            limit: 1000, 
            where: {
              name_eq: "DarwiniaStaking.CommissionUpdated", 
              id_gt: $id_gt, 
              block: { timestamp_gt: $timestamp_gt }
            },
            orderBy: id_ASC
          ) {
            id
            args
            block {
              timestamp
            }
          }
        }
      GRAPHQL

      response = client.query(query_str, { id_gt:, timestamp_gt: })
      response.data.events.map(&:to_h)
    rescue StandardError => e
      puts e.message
      raise e unless try < 5

      puts 'sleep 2s and retry...'
      sleep 2
      query(client, timestamp_gt, id_gt, try)
    end

    # [{
    #   block_timestamp: '2023-09-13 12:00:00',
    #   commission: 0.1
    # },
    # ...
    # ]
    def commission_increase_degree(data)
      return 0 if data.empty? || data.size == 1

      # 将commission数据按照时间进行排序
      sorted_data = data.sort_by { |entry| entry[:block_timestamp] }

      max_increase = 0.0
      previous_commission = sorted_data.first[:commission]

      sorted_data.each do |entry|
        current_commission = entry[:commission]
        
        # 如果当前的commission大于之前的commission，计算增加的程度
        if current_commission > previous_commission
          increase = current_commission - previous_commission
          max_increase = [max_increase, increase].max
        end

        previous_commission = current_commission
      end

      max_increase
    end

    # [
    #   {
    #     count: 123,
    #     max_increase: 0.1
    #   },
    #   ...
    # ]
    def commission_updates_count(client)
      # get the timestamp of a week ago
      timestamp_gt = (Time.now - 7 * 24 * 60 * 60).strftime("%Y-%m-%dT%H:%M:%S.000000Z")
      updates = query(client, timestamp_gt)
      # {
      #   address: [{}, {}, ...]
      # }
      updates_by_address = updates.group_by { |update| update["args"]["who"] }

      updates_by_address.transform_values do |updates|
        updates2 = 
          updates.map do |update|
            {
              block_timestamp: update["block"]["timestamp"],
              commission: update["args"]["commission"].to_f
            }
          end
        { count: updates.length, max_increase: commission_increase_degree(updates2) / 10_000_000 }
      end
    end
  end
end

# puts CommissionUpdates.commission_updates_count(SubsquidClient.send("darwinia"))

