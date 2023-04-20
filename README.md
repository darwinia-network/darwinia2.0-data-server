# Darwinia data hub

A server that provides various data related to Darwinia, Crab, Pangolin, and Pangoro.

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

## RINGS of an account

<img width="878" alt="DARWINI_RING" src="https://user-images.githubusercontent.com/1608576/232960651-4fba7c92-4c8f-4420-be36-1cc4d14974bc.png">

## Docker

### prepare a .env with:

```bash
GOERLI_ENDPOINT=https://eth-goerli.g.alchemy.com/v2/<your-api-key>
PANGOLIN_ENDPOINT=https://pangolin-rpc.darwinia.network
CRAB_ENDPOINT=https://crab-rpc.darwinia.network
MONGODB_URI==mongodb+srv://<username>:<password>@<your-cluster-url>/goerli_pangolin?retryWrites=true&w=majority
```

### run

```bash
docker-compose up
```
