module Supply
  module Ring
    class << self
      def get_total_insurance(rpc, metadata)
        ScaleRb::HttpClient.get_storage2(
          rpc,
          'Balances',
          'TotalIssuance',
          nil,
          metadata
        ) / 10**18
      end

      def get_reserved_ring(rpc, metadata)
        accounts =
          ScaleRb::HttpClient.get_storage2(rpc, 'System', 'Account', nil, metadata)
        accounts.reduce(0) do |sum, account|
          sum + account[:storage][:data][:reserved]
        end / 10**18
      end

      def get_locked_ring(rpc, metadata)
        # LOCKED
        locks =
          ScaleRb::HttpClient.get_storage2(rpc, 'Balances', 'Locks', nil, metadata)
        locks.reduce(0) do |sum, lock|
          lock[:storage].reduce(sum) { |sum, item| sum + item[:amount] }
        end / 10**18
      end
    end
  end
end
