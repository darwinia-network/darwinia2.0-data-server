require "dotenv/load"
require "mongo"

module MongodbHelper
  class << self
    def client
      @client ||=
        Mongo::Client.new(ENV["MONGODB_URI"], server_api: { version: "1" })
    end

    def find_message(query)
      db = client[:messages]
      db.find(query).first
    end

    def save_message(message)
      db = client[:messages]
      db.insert_one(message)
    end

    def update_message(query, set)
      db = client[:messages]
      db.update_one(query, { "$set" => set })
    end

    def save_or_update_message(message)
      db = client[:messages]
      message_id = { direction: message[:direction], nonce: message[:nonce] }
      if find_message(message_id)
        update_message(message_id, message)
      else
        save_message(message)
      end
    end

    # { "key": "value", "key2": "value2" }
    def get_config(key)
      db = client[:config]
      db.find.first ? db.find.first[key] : nil
    end

    def set_config(key, value)
      db = client[:config]
      if db.find.first
        db.update_one({}, { "$set" => { key => value } })
      else
        db.insert_one({ key => value })
      end
    end
  end
end

# MongodbHelper.set_config("last_tracked_block", 1)
# p MongodbHelper.get_config("last_tracked_block")
