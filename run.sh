#!/bin/bash

nohup bundle exec rake gen_data &
bundle exec rackup -o 0.0.0.0 -p 4567
