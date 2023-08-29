def to_camel(str)
  if str.include?('_')
    splits = str.split('_')
    splits[0] + splits[1..].collect(&:capitalize).join
  else
    str[0].downcase + str[1..]
  end
end

def to_pascal(str)
  str.split('_').collect(&:capitalize).join
end

# convert key
def c(key)
  if key.start_with?('0x')
    key.to_bytes
  elsif key.to_i.to_s == key # check if key is a number
    key.to_i
  else
    key
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

def matches_time_span_pattern?(input_string)
  regex = /\b(?:\d+d|\d+h|\d+m|\d+s)\b/
  !!(input_string =~ regex)
end

# https://github.com/darwinia-network/darwinia2.0-staking-ui/blob/8f9d88b4c874c36cedf140f0a288250507d3b293/src/utils/misc.ts#L5
def calc_power(staked_ring, staked_kton, ring_pool, kton_pool)
  raise 'ring_pool is zero' if ring_pool.zero?

  d = kton_pool.zero? ? 0 : ring_pool.to_f / kton_pool
  1_000_000_000 * (staked_ring + staked_kton * d) / (ring_pool * 2)
end

def write_data_to_file(data, filename)
  data_dir = './data'
  FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
  File.write(
    File.join(data_dir, filename),
    { generated_at: Time.now, data: }.to_json
  )
end

# puts matches_time_span_pattern?('12')

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
