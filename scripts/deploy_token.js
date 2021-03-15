const hre = require("hardhat");
const { toHordDenomination } = require('../test/setup');
const { getSavedContractAddresses, saveContractAddress } = require('./utils')

async function main() {

  await hre.run('compile');

  // We get the contract to deploy
  const Hord = await hre.ethers.getContractFactory("Hord");
  const hord = await Hord.deploy("HORD token", "HORD", toHordDenomination(320000000));
  await hord.deployed();

  console.log("Hord token deployed to:", hord.address);
  saveContractAddress(hre.network.name, 'hordToken', hord.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
