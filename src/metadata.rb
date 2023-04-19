require "scale_rb"
require_relative "./utils"

def update_metadata(network_name, rpc, metadata_path)
  puts "updating #{network_name} metadata..."

  timed do
    block_hash = ScaleRb::HttpClient.chain_getBlockHash rpc
    metadata = ScaleRb::HttpClient.get_metadata(rpc, block_hash)
    metadata = JSON.pretty_generate(metadata)
    File.write(metadata_path, metadata)
  end
end
