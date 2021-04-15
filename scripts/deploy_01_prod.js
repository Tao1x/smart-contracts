const hre = require("hardhat");
const { hexify, toHordDenomination } = require('../test/setup');
const { getSavedContractAddresses, saveContractAddress, getSavedContractBytecodes, saveContractBytecode } = require('./utils')
const config = require('../deployments/deploymentConfig.json');

async function main() {
    await hre.run('compile');

    const HordCongress = await hre.ethers.getContractFactory("HordCongress");
    const hordCongress = await HordCongress.deploy();
    await hordCongress.deployed();
    console.log("HordCongress contract deployed to:", hordCongress.address);
    saveContractAddress(hre.network.name, 'hordCongress', hordCongress.address,'master');
    saveContractBytecode(hre.network.name,'hordCongress', (await hre.artifacts.readArtifact("HordCongress")).bytecode, 'master');

    const HordCongressMembersRegistry = await hre.ethers.getContractFactory("HordCongressMembersRegistry");
    const hordCongressMembersRegistry = await HordCongressMembersRegistry.deploy(
        config.initialCongressMembers,
        hexify(config.initialCongressMembersNames),
        hordCongress.address
    );
    await hordCongressMembersRegistry.deployed();
    console.log("HordCongressMembersRegistry contract deployed to:", hordCongressMembersRegistry.address);
    saveContractAddress(hre.network.name, 'hordCongressMembersRegistry', hordCongressMembersRegistry.address, 'master');
    saveContractBytecode(hre.network.name,'hordCongressMembersRegistry', (await hre.artifacts.readArtifact("HordCongressMembersRegistry")).bytecode,'master');


    const HordToken = await hre.ethers.getContractFactory("HordToken");
    const hord = await HordToken.deploy(
        config.hordTokenName,
        config.hordTokenSymbol,
        toHordDenomination(config.hordTotalSupply.toString()),
        hordCongress.address
    );
    await hord.deployed();
    console.log("Hord token deployed to:", hord.address);
    saveContractAddress(hre.network.name, 'hordToken', hord.address, 'master');
    saveContractBytecode(hre.network.name,'hordToken', (await hre.artifacts.readArtifact("HordToken")).bytecode, 'master');


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
