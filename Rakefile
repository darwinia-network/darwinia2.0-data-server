require 'scale_rb'
require './config/config.rb'
require './data'
require './utils'

task default: %w[gen_data_loop]

desc 'Generate the statistic data'
task :gen_data do
  generate_data
end

desc 'Generate the statistic data loop'
task :gen_data_loop do
  loop_do do
    generate_data
  end
end

desc 'Update metadata'
task :update_metadata do
  update_metadata
end

desc 'Update metadata loop'
task :update_metadata_loop do
  loop_do do
    update_metadata
  end
end