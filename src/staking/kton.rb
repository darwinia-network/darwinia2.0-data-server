module Staking
  module Kton
    class << self
      ####################################################
      # unmigrated accounts
      ####################################################
      def get_staking_kton_unmigrated(rpc, metadata)
        ledgers = get_storage(rpc, metadata, 'account_migration', 'ledgers', nil, nil)
        ledgers.reduce(0) do |sum, ledger|
          sum + ledger[:storage][:staked_kton]
        end
      end

      ####################################################
      # migrated accounts
      ####################################################
      def get_staking_kton(rpc, metadata)
        ledgers = get_storage(rpc, metadata, 'darwinia_staking', 'ledgers', nil, nil)
        ledgers.reduce(0) do |sum, ledger|
          sum + ledger[:storage][:staked_kton]
        end
      end
    end
  end
end

##########################################
# require 'json'
# require 'scale_rb'
# require_relative '../storage'
#
# require_relative '../../config/config'
# config = get_config
# metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
# rpc = config[:darwinia_rpc]
#
# puts get_staking_kton_unmigrated(rpc, metadata)
# puts get_staking_kton(rpc, metadata)
