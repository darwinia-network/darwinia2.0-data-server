require "mongo"
require "eth"
require "json"
include Eth
require "dotenv/load"

def get_balance(eth_client, address)
  eth_client.eth_balance(address)["result"].to_i(16)
end

def get_nonce(eth_client, address)
  eth_client.eth_get_transaction_count(address)["result"].to_i(16)
end

# address, network:index, dropped_at, username:index
def drop_allowed?(mongo_client, username, network)
  db = mongo_client[:drops]
  drop = db.find({ username: username, network: network }).first

  !drop || drop[:dropped_at] + 24 * 60 * 60 < Time.now.to_i
end

def do_drop(evm_client, address, network)
  tx = build_drop_tx(evm_client, address, network)
  evm_client.eth_send_raw_transaction(tx.hex)["result"]
end

def build_drop_tx(evm_client, address, network)
  payload = {
    chain_id: network == "pangolin" ? 43 : 45,
    nonce: get_nonce(evm_client, "#{ENV["DROP_ADDRESS"]}"),
    gas_price: 2000 * Eth::Unit::GWEI,
    gas_limit: 210_000,
    to: address,
    value: 50 * Eth::Unit::ETHER,
  }
  tx = Eth::Tx.new payload
  signer_key = Eth::Key.new priv: "#{ENV["DROP_PRIVATE_KEY"]}"
  tx.sign signer_key
  tx
end

def insert_or_update_drop_record(mongo_client, address, network, username, tx_hash)
  db = mongo_client[:drops]

  drop = db.find({ address: address.downcase, network: network }).first

  if drop
    db.update_one(
      { address: address.downcase, network: network }, 
      { "$set" => { dropped_at: Time.now.to_i, username: username, tx_hash: tx_hash } }
    )
  else 
    db.insert_one({
      address: address.downcase,
      network: network,
      dropped_at: Time.now.to_i,
      username: username,
      tx_hash: tx_hash
    }) 
  end
end

def drop(evm_client, mongo_client, address, network, username)
  tx_hash = do_drop(evm_client, address, network)
  insert_or_update_drop_record(mongo_client, address, network, username, tx_hash)
  tx_hash
end

# channel for 
def run_drop(address, network, username)
  mongo_client = Mongo::Client.new(
    ENV["MONGODB_URI"],
    server_api: {
      version: "1",
    },
  )

  if drop_allowed?(mongo_client, username, network)
    evm_client = 
      if network == "pangolin"
        Eth::Client::Http.new(ENV["PANGOLIN_ENDPOINT"])
      else
        Eth::Client::Http.new(ENV["PANGORO_ENDPOINT"])
      end

    drop(evm_client, mongo_client, address, network, username)
  else
    raise "already received it today, please come back tomorrow."
  end
end

# client = Eth::Client::Http.new("https://pangolin-rpc.darwinia.network")
# tx = build_drop_tx(client, "0xDa97bC5EE02F33B92A0665620fFE956E21BAEf0f", "pangolin")
# # puts tx.hash
# # puts client.eth_send_raw_transaction(tx.hex)["result"]

# puts run_drop("0xDa97bC5EE02F33B92A0665620fFE956E21BAEf0f", "pangolin", "test")
