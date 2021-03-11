# Smart Contracts

Implementation of hord.fund protocol 


### Developer instructions
#### Instal dependencies
`yarn install`

#### Create .env file and make sure it's having following information:
```
PK=YOUR_PRIVATE_KEY 
```

#### Compile code
`npx hardhat compile`

#### Deploy code 
- `npx hardhat node` (run hardhat node server)
- `npx hardhat run --network localhost scripts/{desired_deployment_script}`

