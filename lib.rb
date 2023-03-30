module Crab
  class << self
    # returns: [ring_staking_amount, kton_staking_amount]
    def deposits(url, metadata)
      items = Substrate::Client.get_storage3(url, 'System', 'Account', nil, metadata, nil)
      p items
    end
  end
end
