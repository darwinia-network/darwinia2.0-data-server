require "scale_rb"
require_relative "utils"

def get_storage(rpc, metadata, pallet_name, storage_name, key_part1, key_part2)
  pallet_name = to_camel pallet_name
  storage_name = to_camel storage_name

  puts "#{pallet_name}.#{storage_name}(#{[key_part1, key_part2].compact.join(", ")})"

  if pallet_name == "AccountMigration" && key_part1 &&
       key_part1.start_with?("5")
    key_part1 = "0x#{Address.decode(key_part1, 42, true)}"
  end

  key = [key_part1, key_part2].compact.map { |part_of_key| c(part_of_key) }

  ScaleRb::HttpClient.get_storage2(
    rpc,
    pallet_name,
    storage_name,
    key,
    metadata,
  )
end

# require_relative "../config/config.rb"
# config = get_config
# crab_metadata = JSON.parse(File.read(config[:metadata][:crab]))
# crab_rpc = config[:crab_rpc]

# puts get_storage(
#        crab_rpc,
#        crab_metadata,
#        "deposit",
#        "deposits",
#        "0x0a1287977578F888bdc1c7627781AF1cc000e6ab",
#        nil,
#      )
