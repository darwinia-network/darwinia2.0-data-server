#!/bin/bash

nohup bundle exec rake update_metadata_loop &
nohup bundle exec rake gen_data_loop &
nohup bundle exec rake update_goerli_pangolin2_messages &
nohup bundle exec rake update_pangolin2_goerli_messages &
bundle exec ruby server.rb
