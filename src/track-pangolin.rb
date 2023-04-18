require "dotenv/load"
require "scale_rb"
require_relative "./evm-track-helper"
require_relative "./mongodb-helper"

def track_pangolin
  # Prepare the contracts to track
  # --------------------------------------------------------
  contracts_to_track = [
    "0xcF2A32c182A73D93fBa0C5e515e3C5ec7944a471", # outbound lane
    "0x12224D83884009782F8F25fa709B33DEA6ad0fE7", # inbound lane
  ]

  # Prepare how to persist the last tracked block
  # --------------------------------------------------------
  get_last_tracked_block = -> do
    if MongodbHelper.get_config("last_tracked_block_darwinia").nil?
      0
    else
      MongodbHelper.get_config("last_tracked_block_darwinia")
    end
  end

  set_last_tracked_block = ->(number) do
    MongodbHelper.set_config("last_tracked_block_darwinia", number)
  end

  # Main
  # --------------------------------------------------------
  evm_tracker_helper = EvmTrackHelper.new(ENV["PANGOLIN_ENDPOINT"])
  evm_tracker_helper.track_messages(
    contracts_to_track,
    get_last_tracked_block,
    set_last_tracked_block,
    20_000,
  ) do |event_name, data|
    case event_name
    when "MessageAccepted"
      message = { direction: 1 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    when "MessageDispatched"
      message = { direction: 0 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    when "MessageDelivered"
      message = { direction: 1 }.merge(data)
      MongodbHelper.save_or_update_message(message)
    end
  end
end
