require "scale_rb"
require "./config/config.rb"
require "./data"
require "./utils"
require "./src/track-ethereum"
require "./src/track-darwinia"

task default: %w[gen_data_loop]

desc "Generate the statistic data"
task :gen_data do
  generate_data
end

desc "Generate the statistic data loop"
task :gen_data_loop do
  loop_do { generate_data }
end

desc "Update metadata"
task :update_metadata do
  update_metadata
end

desc "Update metadata loop"
task :update_metadata_loop do
  loop_do { update_metadata }
end

desc "Update Goerli > Pangolin2 Messages"
task :update_goerli_pangolin2_messages do
  upload_goerli
end

desc "Update Pangolin2 > Goerli Messages"
task :update_pangolin2_goerli_messages do
  upload_pangolin
end
