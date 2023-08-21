require 'scale_rb'
require './src/utils'
require './src/supplies'
require './src/metadata'
require './src/track-goerli'
require './src/track-pangolin'
require './src/storage'
require './src/account'
require './config/config'
config = get_config

task default: %w[gen_supplies_data_loop]

task :update_metadata_loop do
  loop_do do
    Rake::Task['update_darwinia_metadata'].reenable
    Rake::Task['update_darwinia_metadata'].invoke
    Rake::Task['update_crab_metadata'].reenable
    Rake::Task['update_crab_metadata'].invoke
    Rake::Task['update_pangolin_metadata'].reenable
    Rake::Task['update_pangolin_metadata'].invoke
  end
end

task :gen_supplies_data_loop do
  loop_do do
    Rake::Task['gen_darwinia_supplies_data'].reenable
    Rake::Task['gen_darwinia_supplies_data'].invoke
  end
end

task :update_nominees_loop do
  loop_do(60 * 2) do
    Rake::Task['update_nominees'].reenable
    Rake::Task['update_nominees'].invoke('darwinia')
    Rake::Task['update_nominees'].reenable
    Rake::Task['update_nominees'].invoke('crab')
  end
end

##########################################
# Darwinia
##########################################
task :gen_darwinia_supplies_data do
  ethereum_rpc = config[:ethereum_rpc]
  darwinia_rpc = config[:darwinia_rpc]
  darwinia_metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
  generate_supplies('darwinia', ethereum_rpc, darwinia_rpc, darwinia_metadata)
end

task :update_darwinia_metadata do
  darwinia_rpc = config[:darwinia_rpc]
  darwinia_metadata_path = config[:metadata][:darwinia]
  update_metadata('darwinia', darwinia_rpc, darwinia_metadata_path)
end

##########################################
# Crab
##########################################
task :update_crab_metadata do
  crab_rpc = config[:crab_rpc]
  crab_metadata_path = config[:metadata][:crab]
  update_metadata('crab', crab_rpc, crab_metadata_path)
end

##########################################
# Pangolin
##########################################
task :update_pangolin_metadata do
  pangolin_rpc = config[:pangolin_rpc]
  pangolin_metadata_path = config[:metadata][:pangolin]
  update_metadata('pangolin', pangolin_rpc, pangolin_metadata_path)
end

##########################################
# Goerli <> pangolin
##########################################
task :update_goerli_pangolin_messages do
  track_goerli
end

task :update_pangolin_goerli_messages do
  track_pangolin
end

require 'logger'
task :update_nominees, [:network_name] do |_t, args|
  logger = Logger.new($stdout)
  logger.level = Logger::DEBUG

  network_name = args[:network_name]
  logger.debug "updating #{network_name} nominees..."

  rpc = config["#{network_name}_rpc".to_sym]
  metadata = JSON.parse(File.read(config[:metadata][network_name.to_sym]))

  ring_pool = get_storage(rpc, metadata, 'darwinia_staking', 'ring_pool', nil, nil)
  kton_pool = get_storage(rpc, metadata, 'darwinia_staking', 'kton_pool', nil, nil)

  # 1. Get all nominators with their nominees
  # ---------------------------------------
  # { nominator: nominee }
  nominators =
    get_storage(
      rpc,
      metadata,
      'darwinia_staking',
      'nominators',
      nil,
      nil
    )

  nominator_nominee_mapping =
    nominators.map do |item|
      nominator_address = "0x#{item[:storage_key][-40..]}"
      nominee_address = item[:storage].to_hex
      [nominator_address, nominee_address]
    end.to_h

  # 2. Get all nominators' staking info
  # ---------------------------------------
  # {
  #   "nominator" => {:staked_ring=>10000000000000000000, :staked_kton=>0},
  # }
  nominator_addresses = nominator_nominee_mapping.keys
  nominator_staking_infos = get_accounts_staking_info(rpc, metadata, nominator_addresses)

  # 3. Sum up nominators' staking info of each nominee
  # ---------------------------------------
  # {
  #   "nominee" => {:staked_ring=>total, :staked_kton=>total},
  # }
  result =
    nominator_addresses.each_with_object({}) do |nominator_address, acc|
      nominator_staking_info = nominator_staking_infos[nominator_address]
      nominee_address = nominator_nominee_mapping[nominator_address]
      acc[nominee_address] =
        {
          staked_ring: (acc[nominee_address]&.[](:staked_ring) || 0) + nominator_staking_info[:staked_ring],
          staked_kton: (acc[nominee_address]&.[](:staked_kton) || 0) + nominator_staking_info[:staked_kton]
        }
    end

  # 4. Calculate power of each nominee
  # ---------------------------------------
  nominee_powers = result.map do |nominee_address, staking_info|
    power = calc_power(staking_info[:staked_ring], staking_info[:staked_kton], ring_pool, kton_pool)
    [nominee_address, power]
  end.to_h
  logger.debug JSON.pretty_generate(nominee_powers)

  # 5. write to file
  # ---------------------------------------
  logger.debug "writing #{network_name} nominees to file..."
  write_data_to_file(nominee_powers, "#{network_name}-nominees.json")
end
