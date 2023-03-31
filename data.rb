require "scale_rb"

def get_data
  # prepare darwinia metadata
  metadata_content = File.read(File.join(__dir__, 'config', 'crab2.json'))
  metadata = JSON.parse(metadata_content)

  url = 'https://crab-rpc.darwinia.network'

  # ==
  crab_reserved_in_staking = ScaleRb::HttpClient.get_storage2(url, 'DarwiniaStaking', 'RingPool', nil, metadata)
  crab_reserved_in_staking = (crab_reserved_in_staking / 10**18).floor

  # ==
  ckton_reserved_in_staking = ScaleRb::HttpClient.get_storage2(url, 'DarwiniaStaking', 'KtonPool', nil, metadata)
  ckton_reserved_in_staking = (ckton_reserved_in_staking / 10**18).floor

  # ==
  deposits = ScaleRb::HttpClient.get_storage2(url, 'Deposit', 'Deposits', nil, metadata)
  crab_in_deposit = deposits.reduce(0) do |sum, deposit|
    sum +
      deposit[:storage].reduce(0) do |sum_of_account, item|
        sum_of_account + item[:value]
      end
  end
  crab_in_deposit = (crab_in_deposit / 10**18).floor

  #
  total_issuance = ScaleRb::HttpClient.get_storage2(url, 'Balances', 'TotalIssuance', nil, metadata)
  total_issuance = (total_issuance / 10**18).floor
  

  {
    crab_reserved_in_staking: crab_reserved_in_staking,
    ckton_reserved_in_staking: ckton_reserved_in_staking,
    crab_in_deposit: crab_in_deposit,
    total_issuance: total_issuance
  }
end
