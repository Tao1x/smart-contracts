# Smart Contracts

Implementation of hord.fund protocol 


### Developer instructions
#### Instal dependencies
`yarn install`

#### Create .env file and make sure it's having following information:
```
PK=YOUR_PRIVATE_KEY 
USERNAME=HORD
PROJECT=HORD_FUND
```

#### Create file for local and public deployments
- `mkdir deployments`

#### Compile code
- `npx hardhat clean` (Clears the cache and deletes all artifacts)
- `npx hardhat compile` (Compiles the entire project, building all artifacts)

#### Deploy code 
- `npx hardhat node` (Starts a JSON-RPC server on top of Hardhat Network)
- `npx hardhat run --network localhost scripts/{desired_deployment_script}`

#### Flatten contracts
- `npx hardhat flatten` (Flattens and prints contracts and their dependencies)


