const hre = require("hardhat");
const { hexify, toHordDenomination } = require('../test/setup');
const { getSavedContractAddresses, saveContractAddress } = require('./utils')
const config = require('./deploymentConfig.json');

async function main() {
  await hre.run('compile');

  const HordCongress = await hre.ethers.getContractFactory("HordCongress");
  const hordCongress = await HordCongress.deploy();
  await hordCongress.deployed();
  console.log("HordCongress contract deployed to:", hordCongress.address);
  saveContractAddress(hre.network.name, 'hordCongress', hordCongress.address);

  const HordCongressMembersRegistry = await hre.ethers.getContractFactory("HordCongressMembersRegistry");
  const hordCongressMembersRegistry = await HordCongressMembersRegistry.deploy(
      config.initialCongressMembers,
      hexify(config.initialCongressMembersNames),
      hordCongress.address
  );
  await hordCongressMembersRegistry.deployed();
  console.log("HordCongressMembersRegistry contract deployed to:", hordCongressMembersRegistry.address);
  saveContractAddress(hre.network.name, 'hordCongressMembersRegistry', hordCongressMembersRegistry.address);

  // We get the contract to deploy
  const Hord = await hre.ethers.getContractFactory("Hord");
  const hord = await Hord.deploy(
      config.hordTokenName,
      config.hordTokenSymbol,
      toHordDenomination(config.hordTotalSupply.toString()),
      hordCongress.address
  );
  await hord.deployed();
  console.log("Hord token deployed to:", hord.address);
  saveContractAddress(hre.network.name, 'hordToken', hord.address);

  await hordCongress.setMembersRegistry(hordCongressMembersRegistry.address);
  console.log('HordCongress.setMembersRegistry(',hordCongressMembersRegistry.address,') set successfully.');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
