require 'scale_rb'
require './src/utils'
require './src/supplies'
require './src/metadata'
require './src/storage'
require './src/account'
require './src/staking/ring'
require './src/staking/kton'
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

task :update_staking_data_loop do
  loop_do do
    Rake::Task['gen_staking_data'].reenable
    Rake::Task['gen_staking_data'].invoke('darwinia')
    Rake::Task['gen_staking_data'].reenable
    Rake::Task['gen_staking_data'].invoke('crab')
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
# Multi networks
##########################################
require 'logger'
require_relative 'src/subsquid/subsquid_client'
require_relative 'src/subsquid/commission_updates'
# nominee = active collators + waiting collators + other nominees who have nominations backing
task :update_nominees, [:network_name] do |_t, args|
  logger = Logger.new($stdout)
  logger.level = Logger::DEBUG

  timed do
    network_name = args[:network_name]
    logger.debug "updating #{network_name} nominees..."

    rpc = config["#{network_name}_rpc".to_sym]
    metadata = JSON.parse(File.read(config[:metadata][network_name.to_sym]))

    ring_pool = get_storage(rpc, metadata, 'darwinia_staking', 'ring_pool', nil, nil)
    kton_pool = get_storage(rpc, metadata, 'darwinia_staking', 'kton_pool', nil, nil)
    collator_commissions = get_collator_commissions(rpc, metadata) # includes active and waiting collators
    active_collator_addresses = get_active_collators(rpc, metadata)
    current_exposures = get_current_exposures(rpc, metadata)
    collators_no_session_key = current_exposures - active_collator_addresses
    identities = get_identities(rpc, metadata) # address => name
    commission_updates_count = CommissionUpdates.commission_updates_count(SubsquidClient.send(network_name))

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

        nominee_address = item[:storage]
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
      commission = collator_commissions[nominee_address]
      commission = commission.nil? ? nil : commission / 100.0

      power_weighted_by_commission =
        if power.nil? || commission.nil?
          nil
        else
          power * (1 - commission)
        end

      [nominee_address, [power, power_weighted_by_commission]]
    end.to_h

    # 5. Set the collators committee
    # ---------------------------------------
    all_nominee_addresses = (nominee_powers.keys + collator_commissions.keys).uniq
    waiting_collator_addresses = collator_commissions.keys - active_collator_addresses
    result = all_nominee_addresses.map do |nominee_address|
      power, power_weighted_by_commission = nominee_powers[nominee_address]
      [
        nominee_address,
        {
          name: identities[nominee_address],
          power:,
          power_weighted_by_commission:,
          commission: collator_commissions[nominee_address],
          commission_updates_count: commission_updates_count[nominee_address]&.[](:count) || 0,
          commission_max_increase: commission_updates_count[nominee_address]&.[](:max_increase),
          status: get_nominee_status(active_collator_addresses, waiting_collator_addresses, nominee_address),
          no_session_key: collators_no_session_key.include?(nominee_address)
        }
      ]
    end.to_h
    # logger.debug JSON.pretty_generate(result)

    # 6. write to file
    # ---------------------------------------
    logger.debug "writing #{network_name} nominees to file..."
    write_data_to_file(result, "#{network_name}-nominees.json")
  end
end

task :gen_staking_data, [:network_name] do |_t, args|
  timed do
    network_name = args[:network_name]
    puts "generate #{network_name} staking data..."

    rpc = config["#{network_name}_rpc".to_sym]
    metadata = JSON.parse(File.read(config[:metadata][network_name.to_sym]))

    staking_ring = Staking::Ring.get_all_staking_ring(rpc, metadata)
    staking_ring_unmigrated = Staking::Ring.get_all_staking_ring_unmigrated(rpc, metadata)
    result = {
      ring: {
        migrated: {
          staking: staking_ring[:staking_ring],
          staking_in_deposits: staking_ring[:staking_ring_in_deposits],
          total: staking_ring[:total]
        },
        unmigrated: {
          staking: staking_ring_unmigrated[:staking_ring],
          staking_in_deposits: staking_ring_unmigrated[:staking_ring_in_deposits],
          total: staking_ring_unmigrated[:total]
        },
        total: staking_ring[:total] + staking_ring_unmigrated[:total]
      },
      kton: {
        staking: Staking::Kton.get_staking_kton(rpc, metadata),
        unmigrated: Staking::Kton.get_staking_kton_unmigrated(rpc, metadata)
      }
    }

    write_data_to_file(result, "#{network_name}-staking.json")
  end
end
