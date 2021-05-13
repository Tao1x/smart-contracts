const hre = require("hardhat");
const { hexify, toHordDenomination } = require('../test/setup');
const { saveContractAddress } = require('./utils')
let c = require('../deployments/deploymentConfig.json');

async function main() {
  await hre.run('compile');

  const config = c[hre.network.name];

  const HordCongress = await hre.ethers.getContractFactory("HordCongress");
  const hordCongress = await HordCongress.deploy();
  await hordCongress.deployed();
  console.log("HordCongress contract deployed to:", hordCongress.address);
  saveContractAddress(hre.network.name, 'HordCongress', hordCongress.address);

  const HordCongressMembersRegistry = await hre.ethers.getContractFactory("HordCongressMembersRegistry");
  const hordCongressMembersRegistry = await HordCongressMembersRegistry.deploy(
      config.initialCongressMembers,
      hexify(config.initialCongressMembersNames),
      hordCongress.address
  );
  await hordCongressMembersRegistry.deployed();
  console.log("HordCongressMembersRegistry contract deployed to:", hordCongressMembersRegistry.address);
  saveContractAddress(hre.network.name, 'HordCongressMembersRegistry', hordCongressMembersRegistry.address);


  const HordToken = await hre.ethers.getContractFactory("HordToken");
  const hord = await HordToken.deploy(
      config.hordTokenName,
      config.hordTokenSymbol,
      toHordDenomination(config.hordTotalSupply.toString()),
      hordCongress.address
  );
  await hord.deployed();
  console.log("Hord token deployed to:", hord.address);
  saveContractAddress(hre.network.name, 'HordToken', hord.address);

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
