module Supply
  module Kton
    class << self
      def get_kton_total_insurance(rpc, metadata)
        ScaleRb::HttpClient
          .get_storage2(rpc, 'Assets', 'Asset', nil, metadata)
          .find do |item|
            item[:storage_key] ==
              '0x682a59d51ab9e48a8c8cc418ff9708d2d34371a193a751eea5883e9553457b2e15ffd708b25d8ed5477f01d3f9277c360204000000000000'
          end
          .dig(:storage, :supply) / 10**18
      end
    end
  end
end
