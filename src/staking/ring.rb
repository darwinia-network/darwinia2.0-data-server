module Staking
  module Ring
    class << self
      ####################################################
      # unmigrated accounts
      ####################################################
      def get_all_staking_ring_unmigrated(rpc, metadata)
        ledgers = get_storage(rpc, metadata, 'account_migration', 'ledgers', nil, nil)
        staking_ring = calc_staking_ring(ledgers)

        all_deposits = get_all_deposits(
          get_storage(rpc, metadata, 'account_migration', 'deposits', nil, nil)
        )
        staking_ring_in_deposits = calc_staking_ring_in_deposits(ledgers, all_deposits)

        {
          staking_ring:,
          staking_ring_in_deposits:,
          total: staking_ring + staking_ring_in_deposits
        }
      end

      ####################################################
      # migrated accounts
      ####################################################
      def get_all_staking_ring(rpc, metadata)
        ledgers = get_storage(rpc, metadata, 'darwinia_staking', 'ledgers', nil, nil)
        staking_ring = calc_staking_ring(ledgers)

        all_deposits = get_all_deposits(
          get_storage(rpc, metadata, 'deposit', 'deposits', nil, nil)
        )
        staking_ring_in_deposits = calc_staking_ring_in_deposits(ledgers, all_deposits)

        {
          staking_ring:,
          staking_ring_in_deposits:,
          total: staking_ring + staking_ring_in_deposits
        }
      end

      private

      def calc_staking_ring(ledgers)
        ledgers.reduce(0) do |sum, ledger|
          sum + ledger[:storage][:staked_ring]
        end
      end

      def get_deposit(deposits, id)
        deposits.each do |deposit|
          return deposit if deposit[:id] == id
        end
      end

      def calc_staking_ring_in_deposits(ledgers, all_deposits)
        sum = 0

        ledgers.each do |ledger|
          account = "0x#{ledger[:storage_key][-40..]}"

          # get the deposit ids of the account
          deposit_ids = ledger[:storage][:staked_deposits]

          # get all deposits of the account
          deposits = all_deposits[account]

          # calculate the staking ring in deposits
          deposit_ids.each do |deposit_id|
            deposit = get_deposit(deposits, deposit_id)
            sum += deposit[:value] if deposit[:in_use]
          end
        end

        sum
      end

      # return:
      #   {
      #     0x161fbbe61E224C1Aaa9BD0B3444e45AF7FfF779d => [
      #       {
      #         :id=>0,
      #         :value=>3200000000000000000000,
      #         ...
      #       },
      #       ...
      #     ],
      #     ...
      #   }
      def get_all_deposits(storages)
        storages.each_with_object({}) do |storage, acc|
          # storage:
          #   {
          #     :storage_key=>"0x1fb3231abc71c5a12c573bc57e9d12d174a614db8021c6bd0a028aafdf29dd080091926c50a7544a24728ea18e183845ce11f8d5737b5f0783c072fa15e38f64e338f844d4135bd0c311e1ea95513f25",
          #     :storage=>[
          #       {:id=>0, :value=>100000000000000000000000, :start_time=>1605600300003, :expired_time=>1667808300003, :in_use=>true}
          #     ]
          #   }
          account = "0x#{storage[:storage_key][-40..]}"
          items = storage[:storage]
          items.each do |item|
            if acc[account]
              acc[account] << item
            else
              acc[account] = [item]
            end
          end
        end
      end
    end
  end
end

##########################################
# require 'json'
# require 'scale_rb'
# require_relative '../storage'
# require_relative '../../config/config'
# config = get_config
# metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
# rpc = config[:darwinia_rpc]
# staking_1 = get_all_staking_ring_unmigrated(rpc, metadata)
# staking_2 = get_all_staking_ring(rpc, metadata)
#
# puts (staking_1[:total] + staking_2[:total]) / 10**18
