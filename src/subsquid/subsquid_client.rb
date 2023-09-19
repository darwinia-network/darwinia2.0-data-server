
module SubsquidClient
  class << self
    def darwinia
      Graphlient::Client.new(
        'https://darwinia.explorer.subsquid.io/graphql',
        headers: {
          "User-Agent": 'Darwinia Datahub'
        }
      )
    end

    def crab
      Graphlient::Client.new(
        'https://crab.explorer.subsquid.io/graphql',
        headers: {
          "User-Agent": 'Darwinia Datahub'
        }
      )
    end

    def pangolin
      Graphlient::Client.new(
        'https://pangolin.explorer.subsquid.io/graphql',
        headers: {
          "User-Agent": 'Darwinia Datahub'
        }
      )
    end
  end
end
