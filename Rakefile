require "scale_rb"
require "./src/utils"
require "./src/stat"
require "./src/track-goerli"
require "./src/track-pangolin"
require "./config/config.rb"
config = get_config

task default: %w[gen_data_loop]

desc "Generate the statistic data"
task :gen_data do
  generate_crab_data
end

desc "Generate the statistic data loop"
task :gen_data_loop do
  loop_do { generate_crab_data }
end

desc "Update metadata"
task :update_metadata do
  update_crab_metadata
end

desc "Update metadata loop"
task :update_metadata_loop do
  loop_do { update_crab_metadata }
end

desc "Update Goerli > Pangolin2 Messages"
task :update_goerli_pangolin2_messages do
  track_goerli
end

desc "Update Pangolin2 > Goerli Messages"
task :update_pangolin2_goerli_messages do
  track_pangolin
end
