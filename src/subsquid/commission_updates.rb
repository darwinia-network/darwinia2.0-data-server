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

    def commission_updates_count(client)
      # get the timestamp of a week ago
      timestamp_gt = (Time.now - 7 * 24 * 60 * 60).strftime("%Y-%m-%dT%H:%M:%S.000000Z")
      updates = query(client, timestamp_gt)
      updates.group_by { |update| update["args"]["who"] }.transform_values do |updates|
        updates.length
      end
    end
  end
end

# puts CommissionUpdates.commission_updates_count(SubsquidClient.send("darwinia"))

