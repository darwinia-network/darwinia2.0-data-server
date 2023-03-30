#!/bin/bash

nohup bundle exec rake gen_data &
bundle exec ruby server.rb -s puma
