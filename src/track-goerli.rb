require "dotenv/load"
require "scale_rb"
require_relative "./evm-track-helper"
require_relative "./mongodb-helper"

def track_goerli
  # Prepare the contracts to track
  # --------------------------------------------------------
  contracts_to_track = [
    "0x21D4A3c5390D098073598d30FD49d32F9d9E355E", # outbound lane
    "0x5881f5CF92bf616fdD10eA82DF8f9e709EC5a81D", # inbound lane
  ]

  # Prepare how to persist the last tracked block
  # --------------------------------------------------------
  get_last_tracked_block = -> do
    if MongodbHelper.get_config("last_tracked_block").nil?
      0
    else
      MongodbHelper.get_config("last_tracked_block")
    end
  end

  set_last_tracked_block = ->(number) do
    MongodbHelper.set_config("last_tracked_block", number)
  end

  # Main
  # --------------------------------------------------------
  evm_tracker_helper = EvmTrackHelper.new(ENV["GOERLI_ENDPOINT"])
  evm_tracker_helper.track_messages(
    contracts_to_track,
    get_last_tracked_block,
    set_last_tracked_block,
  ) do |event_name, data|
    case event_name
    when "MessageAccepted"
      message = { direction: 0 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    when "MessageDispatched"
      message = { direction: 1 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    when "MessageDelivered"
      message = { direction: 0 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    end
  end
end
