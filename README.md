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

## RING Supply

Total Supply: Balances.totalInssurance
Circulating Supply: Total Supply - Reserved

### Reserved

1. Ecosystem Multisig Account(Ecosystem Development Fund)  
   https://etherscan.io/address/0xfa4fe04f69f87859fcb31df3b9469f4e6447921c
   
2. Treasury  
   https://darwinia.subscan.io/account/0x6d6f646c64612f74727372790000000000000000

## RINGS of an account

<img width="878" alt="DARWINI_RING" src="https://user-images.githubusercontent.com/1608576/232960651-4fba7c92-4c8f-4420-be36-1cc4d14974bc.png">

## Docker

### prepare a .env with:

```bash
# alchemy nodes has been tested
ETHEREUM_ENDPOINT=https://eth-mainnet.g.alchemy.com/v2/<your-api-key>
GOERLI_ENDPOINT=https://eth-goerli.g.alchemy.com/v2/<your-api-key>
# darwinia nodes
DARWINIA_ENDPOINT=http://g1.dev.darwinia.network:10000
CRAB_ENDPOINT=https://crab-rpc.darwinia.network
PANGOLIN_ENDPOINT=https://pangolin-rpc.darwinia.network
# mongodb
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster-url>/goerli_pangolin?retryWrites=true&w=majority
```

### run

```bash
docker-compose up
```
