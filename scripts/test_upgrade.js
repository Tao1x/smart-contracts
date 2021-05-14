const hre = require("hardhat");
let c = require('../deployments/deploymentConfig.json');
const { getSavedContractAddresses, getSavedContractProxies } = require('./utils');
const { toHordDenomination } = require('../test/setup');


async function main() {

    await hre.run('compile');
    const config = c[hre.network.name];
    const contracts = getSavedContractAddresses()[hre.network.name];
    const proxies = getSavedContractProxies()[hre.network.name];

    // Deploying
    const HordTicketFactory= await hre.ethers.getContractFactory("HordTicketFactory");
    const instance = await upgrades.deployProxy(HordTicketFactory, [
        contracts["HordCongress"],
        proxies['MaintainersRegistry'],
        contracts["HordToken"],
        config['minTimeToStake'],
        toHordDenomination(config['minAmountToStake'])
    ]);
    await instance.deployed();

    // Upgrading
    const HordTicketFactoryV2 = await ethers.getContractFactory("HordTicketFactoryV2");
    const upgraded = await upgrades.upgradeProxy(instance.address, HordTicketFactoryV2);


    const resp = await upgraded.addTokenSupply();
    if(resp === 'This was used to add supply in V1') {
        console.log('Upgrade tested successfully.');
    } else {
        console.log('Upgrade has an issue.');
    }

    const admin = await upgrades.admin.getInstance();
    const owner = await admin.owner();

    console.log('Current owner', owner);

    await admin.transferOwnership(contracts["HordCongress"]);
    console.log('Transferred ownership to HordCongress contract: ', contracts["HordCongress"]);

    const newOwner = await admin.owner();
    console.log('New owner is: ', newOwner);



}

main();
