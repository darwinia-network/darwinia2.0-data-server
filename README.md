# darwinia2.0-data-server

Server providing data of Darwina data

## Important Files

* server.rb  
  server which provide http api.

* data.rb  
  the `get_data()` function in this file is to get the newest data.

## Pre
```bash
# install build tools
sudo apt update 
sudo apt install build-essential 

# install ruby and bundler
# use your own way to install ruby 2.7.2

gem install bundler

# install rust, needed by gem `blake2b_rs`
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Install

```bash
git clone https://github.com/darwinia-network/darwinia2.0-data-server
cd darwinia2.0-data-server
bundle install
```

## Run Server
   1. (Optional) install `puma` app server in production
      ```bash
      gem install puma
      ```

   2. Run server
      ```bash
      ./run.sh
      ```

      ```bash
      curl http://127.0.0.1:4567/crab
      curl http://127.0.0.1:4567/crab?t=crab_reserved_in_staking
      curl http://127.0.0.1:4567/crab?t=ckton_reserved_in_staking
      curl http://127.0.0.1:4567/crab?t=crab_in_deposit
      ```

## Https for dev env

https://cors.kahub.in/http://123.58.217.13:4567/crab
