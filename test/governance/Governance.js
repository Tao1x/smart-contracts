const {
    address,
    encodeParameters
} = require('../ethereum');
const config = require('../../deployments/deploymentConfig.json');
const { ethers, expect, isEthException, awaitTx, toHordDenomination, hexify } = require('../setup')

let hordCongress, hordCongressMembersRegistry, hordToken, accounts, owner, ownerAddr, anotherAccount, anotherAccountAddr, r
let initialMembers, initialNames, ownerName

async function setupContractAndAccounts () {
    accounts = await ethers.getSigners()
    owner = accounts[0]
    ownerAddr = await owner.getAddress()
    anotherAccount = accounts[8]
    anotherAccountAddr = await anotherAccount.getAddress()

    const HordCongress = await hre.ethers.getContractFactory("HordCongress");
    hordCongress = await HordCongress.deploy();
    await hordCongress.deployed();

    initialMembers = [ownerAddr.toString().toLowerCase(), anotherAccountAddr.toString().toLowerCase()];
    initialNames = hexify(['Nikola', 'eiTan']);

    const HordCongressMembersRegistry = await hre.ethers.getContractFactory("HordCongressMembersRegistry");
    hordCongressMembersRegistry = await HordCongressMembersRegistry.deploy(
        initialMembers,
        initialNames,
        hordCongress.address
    );

    await hordCongressMembersRegistry.deployed();
    await hordCongress.setMembersRegistry(hordCongressMembersRegistry.address);

    const Hord = await hre.ethers.getContractFactory("Hord");
    hordToken = await Hord.deploy(
        config.hordTokenName,
        config.hordTokenSymbol,
        toHordDenomination(config.hordTotalSupply.toString()),
        hordCongress.address
    );
    await hordToken.deployed()
    hordToken = hordToken.connect(owner)
}

describe('Governance', () => {
    before('setup contracts', async () => {
        await setupContractAndAccounts();
    });

    describe('HordCongressMembersRegistry::setup',async() => {
        describe('initial constructor setup', async() => {
            it('should check number of initial members', async() => {
                const numberOfMembers = await hordCongressMembersRegistry.getNumberOfMembers();
                expect(parseInt(numberOfMembers.toString())).to.be.equal(initialMembers.length);
            });

            it('should check addresses of initial members', async() => {
               let allMembers = await hordCongressMembersRegistry.getAllMemberAddresses();
               for(let i=0 ; i<allMembers.length; i++) {
                   expect(allMembers[i].toLowerCase()).to.be.equal(initialMembers[i].toLowerCase());
               }
            });

            it('should check that minimal quorum is correctly set', async() => {
                let minimalQuorum = await hordCongressMembersRegistry.getMinimalQuorum();
                expect(parseInt(minimalQuorum.toString())).to.be.equal(initialMembers.length-1);
            })
        })
    });

    describe('HordCongress::setup', async() => {
       it('should check that congress members registry address is set properly', async() => {
           let congressMembersRegistry = await hordCongress.getMembersRegistry();
           expect(congressMembersRegistry.toLowerCase()).to.be.equal(hordCongressMembersRegistry.address.toLowerCase())
       })
    });
});
