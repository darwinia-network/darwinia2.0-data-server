require "eth"
require "json"
include Eth

class EvmTrackHelper
  #build EvmTrackHelper instance
  def initialize(url)
    @client = Eth::Client::Http.new(url)
  end

  def client
    @client
  end

  def get_latest_block_number
    client.eth_block_number()["result"].to_i(16) - 12
  end

  def get_block_by_number(number)
    block = client.eth_get_block_by_number(number, true)["result"]
    return if block.nil?

    block["number"] = block["number"].to_i(16)
    block
  end

  def get_latest_block
    start = Time.now
    latest_block_number = get_latest_block_number
    block = get_block_by_number(latest_block_number)
    time_elapsed = Time.now - start
    puts "time elapsed: #{time_elapsed} ms"
    block
  end

  def track_block(start_from_block = nil)
    last_tracked_block =
      (
        if start_from_block.nil?
          get_latest_block
        else
          get_block_by_number(start_from_block)
        end
      )

    loop do
      block_number_to_track = last_tracked_block["number"] + 1

      # run too fast, sleep ns and retry
      if block_number_to_track > get_latest_block_number
        seconds_to_sleep = 5
        # puts "run too fast, sleep #{seconds_to_sleep}s and retry"
        sleep seconds_to_sleep
        next
      end

      new_block = get_block_by_number(block_number_to_track)

      # do something with new_block
      puts "new block: #{new_block["number"]}"
      yield new_block

      # update last_tracked_block
      last_tracked_block = new_block
    rescue StandardError => e
      puts "error: #{e}"
    end
  end

  def get_transactions(block, to, method_id)
    raise "Wrong method id" if method_id.length != 10

    block["transactions"].select do |tx|
      tx["to"] == to.downcase && tx["input"].start_with?(method_id.downcase)
    end
  end

  # tx attributes: [
  #   "blockHash",
  #   "blockNumber",
  #   "hash",
  #   "accessList",
  #   "chainId",
  #   "from",
  #   "gas",
  #   "gasPrice",
  #   "input",
  #   "maxFeePerGas",
  #   "maxPriorityFeePerGas",
  #   "nonce",
  #   "r",
  #   "s",
  #   "to",
  #   "transactionIndex",
  #   "type",
  #   "v",
  #   "value"
  # ]
  # method_id: selector, for example: 0x8f0e6d6b
  def track_transactions(to, method_id, start_from_block = nil)
    track_block(start_from_block) do |new_block|
      transactions = get_transactions(new_block, to, method_id)
      transactions.each { |tx| yield tx }
    end
  end

  # A transaction with a log with topics [A, B] will be matched by the following topic filters:
  #   [] “anything”
  #   [A] “A in first position (and anything after)”
  #   [null, B] “anything in first position AND B in second position (and anything after)”
  #   [A, B] “A in first position AND B in second position (and anything after)”
  #   [[A, B], [A, B]] “(A OR B) in first position AND (A OR B) in second position (and anything after)”
  #
  # From: https://docs.alchemy.com/docs/deep-dive-into-eth_getlogs
  def get_logs(addresses, topics, from_block, to_block)
    resp =
      client.eth_get_logs(
        {
          address: addresses,
          from_block: from_block.to_s(16),
          to_block: to_block.to_s(16),
          topics: topics,
        },
      )
    raise resp["error"].to_json if resp["error"]
    resp["result"]
  end

  def track_blocks_range(
    get_last_tracked_block,
    set_last_tracked_block,
    span = 0
  )
    loop do
      from_block = get_last_tracked_block.call + 1
      if span == 0
        to_block = get_latest_block_number
      else
        span_to_block = from_block + span - 1
        latest_block_number = get_latest_block_number
        # ----from_block----span_to_block----latest_block_number
        # ----from_block----latest_block_number----span_to_block
        to_block = [span_to_block, latest_block_number].min
      end

      # make sure from_block < to_block
      if from_block >= to_block
        seconds_to_sleep = 60
        puts "run too far, sleep #{seconds_to_sleep}s and retry"
        sleep seconds_to_sleep
        next
      end

      puts "track from block: #{from_block} to block: #{to_block}."
      yield from_block, to_block

      set_last_tracked_block.call(to_block)
    rescue StandardError => e
      puts "error: #{e}"
    end
  end

  def track_events(
    contract_addresses,
    topics,
    get_last_tracked_block,
    set_last_tracked_block,
    span = 0
  )
    track_blocks_range(
      get_last_tracked_block,
      set_last_tracked_block,
      span,
    ) do |from_block, to_block|
      get_logs(contract_addresses, topics, from_block, to_block).each do |log|
        # log fields: ["address", "blockHash", "blockNumber", "data", "logIndex", "removed", "topics", "transactionHash", "transactionIndex"]
        log["blockNumber"] = log["blockNumber"].to_i(16)
        log["logIndex"] = log["logIndex"].to_i(16)
        yield log
      end
    end
  end

  # 1. Ethereum
  #     contract: `Outboundlane`
  #     event: `event MessageAccepted(uint64 indexed nonce, address source, address target, bytes encoded);`
  #     topic: `0x98c95af5732ea9f6898d677074a303d37cbf80a533c81aafef61e3414624624e`
  # 2. Darwinia
  #     contract: `Inboundlane`
  #     event: `event MessageDispatched(uint64 nonce, bool result);`
  #     topic:
  # 3. Ethereum
  #     contract: `Outboundlane`
  #     event: `event MessagesDelivered(uint64 indexed begin, uint64 indexed end);`
  #     topic: `0xb11cf15eb96c6c0e544143cec0aa5944efc0e5d311263e73ccfe0f80231e0ac8`
  #
  # ethereum_darwinia_message: {
  #   direction: 0|1, # 0: ethereum > darwinia, 1: darwinia > ethereum
  #   nonce: 0,
  #   status: accepted|dispatched|delivered,
  #   dispatch_result: true|false,
  #   failure_reason: "",
  #   from: address,
  #   to: address,
  #   payload: encoded_message,
  # }
  def track_messages(
    contracts_to_track,
    get_last_tracked_block,
    set_last_tracked_block,
    span = 0
  )
    # Prepare the topics to track
    abi = JSON.parse File.read("./config/abi/lane-events.json")
    message_accepted_abi, message_accepted_topic =
      EvmTrackHelper.find_event_interface abi, "MessageAccepted"
    message_dispatched_abi, message_dispatched_topic =
      EvmTrackHelper.find_event_interface abi, "MessageDispatched"
    message_delivered_abi, message_delivered_topic =
      EvmTrackHelper.find_event_interface abi, "MessagesDelivered"
    # the first topic can be one of the following:
    topics_to_track = [
      [
        message_accepted_topic,
        message_dispatched_topic,
        message_delivered_topic,
      ],
    ]

    # Track the events
    track_events(
      contracts_to_track,
      topics_to_track,
      get_last_tracked_block,
      set_last_tracked_block,
      span,
    ) do |log|
      block = get_block_by_number(log["blockNumber"])
      timestamp = block["timestamp"].to_i(16)
      tx_hash = log["transactionHash"]

      case log["topics"][0]
      when message_accepted_topic
        p message_accepted_abi["name"]
        _, args =
          Abi::Event.decode_log(
            message_accepted_abi["inputs"],
            log["data"],
            log["topics"],
          )
        message = {
          nonce: args[:nonce],
          status: 0,
          accepted_at: timestamp,
          accepted_tx: tx_hash,
          from: args[:source],
          to: args[:target],
          payload: args[:encoded].bytes.to_hex,
        }
        yield message_accepted_abi["name"], message
      when message_dispatched_topic
        p message_dispatched_abi["name"]
        _, args =
          Abi::Event.decode_log(
            message_dispatched_abi["inputs"],
            log["data"],
            log["topics"],
          )
        message = {
          nonce: args[:nonce],
          status: 1,
          dispatch_result: args[:result],
          dispatched_at: timestamp,
          dispatched_tx: tx_hash,
        }
        yield(message_dispatched_abi["name"], message)
      when message_delivered_topic
        p message_delivered_abi["name"]
        _, args =
          Abi::Event.decode_log(
            message_delivered_abi["inputs"],
            log["data"],
            log["topics"],
          )
        (args[:begin]..args[:end]).each do |nonce|
          message = {
            nonce: nonce,
            status: 2,
            delivered_at: timestamp,
            delivered_tx: tx_hash,
          }
          yield(message_delivered_abi["name"], message)
        end
      end
    end
  end

  class << self
    def find_event_interface(abi, name)
      event_abi = abi.find { |i| i["type"] == "event" && i["name"] == name }
      raise "Event ABI not found: #{name}" unless event_abi

      [event_abi, Abi::Event.compute_topic(event_abi)]
    end
  end
end
