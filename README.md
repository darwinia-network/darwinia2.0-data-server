# darwinia2.0-data-server

A server that provides various services related to Darwinia.

# APIs

1. Retrieve arbitrary storage's data. For now, there is no cache for this api. so if the storage's data is large, it will take a while to load, especially for the `1.4`'s result. 
      * no param. for example:  
        ```
        /crab/balances/total_issuance
        ```

      * single map. for example:  
        ```
        /crab/vesting/vesting/0x3d6A81177e17d5DbBD36f23Ea5328aCdF3471209
        ```

      * double map. for example:    
        ```
        /crab/assets/account/0/0x0a1287977578F888bdc1c7627781AF1cc000e6ab
        ```
        * `0` is the first param;
        * `0x0a1287977578F888bdc1c7627781AF1cc000e6ab` is the second param;  

      * map without param. it will retrieve all storages under it. for example, this will return all unmigrated deposits:  
        ```
        /crab/account_migration/deposits
        ``` 

2. Retrieve the latest decoded metadata.  
   ```
   /crab/metadata
   ```

3. Crab's statistical data.  
   ```
   /crab/stat
   ```

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
      bundle exec rake update_metadata_loop
      bundle exec rake gen_data_loop
      APP_ENV=production bundle exec rackup -o 0.0.0.0 -p 4567
      ```

      ```bash
      curl http://127.0.0.1:4567/crab/stat
      ```

## Https for dev env

https://cors.kahub.in/http://123.58.217.13:4567/crab
