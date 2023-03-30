require_relative './data'

task default: %w[gen_data]

desc 'Generate the staking data'
task :gen_data do
  loop do
    File.write(File.join(__dir__, 'data.json'), get_data.to_json)
    sleep 60 * 5
  rescue StandardError => e
    puts e.message
    puts e.backtrace.join("\n")
  end
end

desc 'Generate the staking data once'
task :gen_data_once do
  b = Time.now
  File.write(File.join(__dir__, 'data.json'), get_data.to_json)
  e = Time.now
  puts "elapsed: #{e - b}"
end

