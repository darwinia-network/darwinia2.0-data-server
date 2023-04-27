def to_camel(str)
  if str.include?("_")
    splits = str.split("_")
    splits[0] + splits[1..].collect(&:capitalize).join
  else
    str[0].downcase + str[1..]
  end
end

def to_pascal(str)
  str.split("_").collect(&:capitalize).join
end

# convert key
def c(key)
  if key.start_with?("0x")
    key.to_bytes
  elsif key.to_i.to_s == key # check if key is a number
    key.to_i
  else
    key
  end
end

def render_json(data)
  content_type :json
  if data
    { code: 0, data: data }.to_json
  else
    { code: 1, message: "not found" }.to_json
  end
end

def timed
  b = Time.now
  yield
  e = Time.now
  puts "#{e - b}s"
end

def loop_do(sleep_time = 60 * 5)
  loop do
    yield
    puts "sleep #{sleep_time}s"
    sleep sleep_time
  rescue StandardError => e
    puts e.message
    puts e.backtrace.join("\n")
    sleep sleep_time
  end
end

# require "scale_rb"
# require "eth"
# include Eth
# puts "------------------------------"
# # 0x04a1b8420000000000000000000000001f7e9d02ca0813a35b707f88440024bf3bab5355000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002
# p Util.bin_to_hex(
#     Abi.encode(
#       ["address", "bytes"], 
#       [
#         "0x4568Ac0B2f9e8E247CC507f1B020567B29416059",
#         Util.hex_to_bin("0x0000000000000000000000000000000000000000000000000000000000000002")
#       ]
#     )
#   )