def to_camel(str)
  if str.include?('_')
    splits = str.split('_')
    splits[0..].collect(&:capitalize).join
  else
    str[0].upcase + str[1..]
  end
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

def render_json(data)
  content_type :json
  if data  
    {
      code: 0,
      data: data
    }.to_json
  else
    { 
      code: 1, 
      message: 'not found' 
    }.to_json
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
  end
end

def generate_data
  timed do
    puts "generate statistic data..."
    File.write(File.join(__dir__, 'data.json'), get_data.to_json)
  end
end

def update_metadata
  timed do
    puts "update metadata..."
    block_hash = ScaleRb::HttpClient.chain_getBlockHash config[:url]
    metadata = ScaleRb::HttpClient.get_metadata(config[:url], block_hash)
    metadata = JSON.pretty_generate(metadata)
    File.write(
      config[:metadata][:crab2], 
      metadata
    )
  end
end