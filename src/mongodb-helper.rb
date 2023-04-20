require "mongo"
require_relative "../config/config.rb"

module MongodbHelper
  class << self
    def client
      @client ||=
        Mongo::Client.new(
          get_config[:mongodb_uri],
          server_api: {
            version: "1",
          },
        )
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

    def save_or_update_message(attrs)
      db = client[:messages]
      message_id = { direction: attrs[:direction], nonce: attrs[:nonce] }
      message = find_message(message_id)
      if message
        new_message = message.merge(attrs)
        if (attrs[:status] < message[:status]) # old status is higher
          new_message[:status] = message[:status] # keep the old status
        end
        update_message(message_id, new_message)
      else
        save_message(attrs)
      end
    end

    # { "key": "value", "key2": "value2" }
    def get_setting(key)
      db = client[:config]
      db.find.first ? db.find.first[key] : nil
    end

    def set_setting(key, value)
      db = client[:config]
      if db.find.first
        db.update_one({}, { "$set" => { key => value } })
      else
        db.insert_one({ key => value })
      end
    end
  end
end

# MongodbHelper.set_setting("last_tracked_block", 1)
# p MongodbHelper.get_setting("last_tracked_block")
