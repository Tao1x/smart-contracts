const hre = require('hardhat')

const { getSavedContractAddresses } = require('./utils')

async function main() {
  const contracts = getSavedContractAddresses()[bre.network.name]

  let contractsToPush = []
  Object.keys(contracts).forEach(name => {
    contractsToPush.push({
      name: name,
      address: contracts[name]
    })
  })
  await hre.tenderly.push(...contractsToPush)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
