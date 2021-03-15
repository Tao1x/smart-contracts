// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { toHordDenomination } = require('../test/setup');

async function main() {

  // await hre.run('compile');

  // We get the contract to deploy
  const Hord = await hre.ethers.getContractFactory("Hord");
  const hord = await Hord.deploy(
      "HORD token",
      "HORD",
      toHordDenomination(320000000)
  );

  await hord.deployed();

  console.log("Hord token deployed to:", hord.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
