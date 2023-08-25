require 'scale_rb'
require_relative 'utils'

def get_storage(rpc, metadata, pallet_name, storage_name, key_part1, key_part2)
  pallet_name = to_pascal pallet_name
  storage_name = to_pascal storage_name

  puts "#{pallet_name}.#{storage_name}(#{[key_part1, key_part2].compact.join(', ')})"

  if pallet_name == 'AccountMigration' && key_part1 &&
     key_part1.start_with?('5')
    key_part1 = "0x#{Address.decode(key_part1, 42, true)}"
  end

  key = [key_part1, key_part2].compact.map { |part_of_key| c(part_of_key) }

  ScaleRb::HttpClient.get_storage2(
    rpc,
    pallet_name,
    storage_name,
    key,
    metadata
  )
end

def get_storage2(rpc, metadata, pallet_name, storage_name, key_part1: nil, key_part2: nil, at: nil)
  if pallet_name == 'account_migration' && key_part1 && key_part1.start_with?('5')
    key_part1 = "0x#{Address.decode(key_part1, 42, true)}"
  end

  ScaleRb::HttpClient.get_storage3(
    rpc,
    metadata,
    pallet_name,
    storage_name,
    key_part1:,
    key_part2:,
    at:
  )
end

require_relative '../config/config'
config = get_config
crab_metadata = JSON.parse(File.read(config[:metadata][:crab]))
crab_rpc = config[:crab_rpc]

p get_storage2(
  crab_rpc,
  crab_metadata,
  'deposit',
  'deposits',
  key_part1: '0x0a1287977578F888bdc1c7627781AF1cc000e6ab',
  at: '0xfdd0465158c85d8fc8b77d866a2fc7e542b78d48f1b37a0d7bb7ec4378d43b08'
)
