# darwinia2.0-data-server

A server that provides various data related to Darwinia.

# APIs

1. Retrieve arbitrary storage's data. For now, there is no cache for this api. so if the storage's data is large, it will take a while to load, especially for the `1.4`'s result.

   - no param. for example:

     ```
     /crab/balances/total_issuance
     ```

   - single map. for example:

     ```
     /crab/vesting/vesting/0x3d6A81177e17d5DbBD36f23Ea5328aCdF3471209
     ```

   - double map. for example:

     ```
     /crab/assets/account/0/0x0a1287977578F888bdc1c7627781AF1cc000e6ab
     ```

     - `0` is the first param;
     - `0x0a1287977578F888bdc1c7627781AF1cc000e6ab` is the second param;

   - map without param. it will retrieve all storages under it. for example, this will return all unmigrated deposits:
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

- server.rb  
  server which provide http api.

- data.rb  
  the `get_data()` function in this file is to get the newest data.

## Docker

```bash
# 0. set env to correct value in the dockerfile

# 1. build the docker image
docker build . -t darwinia2dataserver

# 3. run
docker run -it --rm -v "${PWD}":/usr/src/app darwinia2dataserver rake update_metadata_loop
docker run -it --rm -v "${PWD}":/usr/src/app darwinia2dataserver rake gen_data_loop
docker run -it --rm -v "${PWD}":/usr/src/app darwinia2dataserver rake update_goerli_pangolin2_messages
docker run -it --rm -v "${PWD}":/usr/src/app darwinia2dataserver rake update_pangolin2_goerli_messages
docker run -it --rm -v "${PWD}":/usr/src/app -p 4567:4567 darwinia2dataserver ruby server.rb
```
