require 'graphlient'

module TxFee
  class << self
    def query(client, id_gt = '0', try = 0)
      try += 1

      query_str = <<~GRAPHQL
        query($id_gt: String) {
          extrinsics(limit: 1000, where: {fee_gt: 0, id_gt: $id_gt}, orderBy: id_ASC) {
            id
            fee
            block {
              timestamp
            }
          }
        }
      GRAPHQL

      response = client.query(query_str, { id_gt: })
      response.data.extrinsics.map(&:to_h)
    rescue StandardError => e
      puts "try #{try}"
      puts e.message
      raise e unless try <= 2

      puts 'sleep 2s and retry...'
      sleep 2
      query(client, id_gt, try)
    end

    # return: {
    #   total_fee: 123,
    #   tx_amount: 123,
    #   first_block: 'xxx', last_block: 'xxx',
    #   first_timestamp: 123, last_timestamp: 123
    # }
    def calc(client, id_gt = '0', result = { tx_amount: 0, total_fee: 0 })
      page = query(client, id_gt)

      result[:first_block] = page.first['id'].split('-').first.to_i if id_gt == '0'
      result[:first_timestamp] = page.first['block']['timestamp'] if id_gt == '0'
      result[:tx_amount] += page.length
      result[:total_fee] = page.reduce(result[:total_fee]) { |acc, tx| tx['fee'].to_i + acc }

      if page.length < 1000 # last page
        result[:last_block] = page.last['id'].split('-').first.to_i
        result[:last_timestamp] = page.last['block']['timestamp']
        result
      else
        calc(client, page.last['id'], result)
      end
    end

    def darwinia_fee
      calc(darwinia_client)
    end

    def crab_fee
      calc(crab_client)
    end

    private

    def darwinia_client
      Graphlient::Client.new(
        'https://darwinia.explorer.subsquid.io/graphql',
        headers: {
          "User-Agent": 'Darwinia Datahub'
        }
      )
    end

    def crab_client
      Graphlient::Client.new(
        'https://crab.explorer.subsquid.io/graphql',
        headers: {
          "User-Agent": 'Darwinia Datahub'
        }
      )
    end
  end
end

# puts TxFee.darwinia_fee
# puts TxFee.crab_fee
