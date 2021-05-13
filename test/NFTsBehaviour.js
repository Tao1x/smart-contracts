const {
    address,
    encodeParameters
} = require('./ethereum');
const configuration = require('../deployments/deploymentConfig.json');
const { ethers, expect, isEthException, awaitTx, toHordDenomination, hexify } = require('./setup')
const hre = require("hardhat");


let hordCongress, hordCongressAddress, accounts, owner, ownerAddr, maintainer, maintainerAddr,
    user, userAddress, config,
    hordToken, maintainersRegistryContract, ticketFactoryContract, ticketManagerContract,
    championId, supplyToMint, tx, tokenId, lastAddedId

async function setupAccounts () {
    config = configuration[hre.network.name];
    let accounts = await ethers.getSigners()
    owner = accounts[0];
    ownerAddr = await owner.getAddress()

    // Mock hord congress
    hordCongress = accounts[7];
    hordCongressAddress = await hordCongress.getAddress();
    // Mock maintainer address
    maintainer = accounts[8]
    maintainerAddr = await maintainer.getAddress()

    user = accounts[9]
    userAddress = await user.getAddress()
}

async function setupContracts () {
    const Hord = await hre.ethers.getContractFactory("HordToken");

    hordToken = await Hord.deploy(
        config.hordTokenName,
        config.hordTokenSymbol,
        toHordDenomination(config.hordTotalSupply.toString()),
        ownerAddr
    );
    await hordToken.deployed()

    hordToken = hordToken.connect(owner)


    const MaintainersRegistry = await ethers.getContractFactory('MaintainersRegistry')
    const maintainersRegistry = await upgrades.deployProxy(MaintainersRegistry, [[maintainerAddr], hordCongressAddress]);
    await maintainersRegistry.deployed()
    maintainersRegistryContract = maintainersRegistry.connect(owner);


    const HordTicketManager = await ethers.getContractFactory('HordTicketManager');
    const hordTicketManager = await upgrades.deployProxy(HordTicketManager, [
            hordCongressAddress,
            maintainersRegistry.address,
            hordToken.address,
            config['minTimeToStake'],
            toHordDenomination(config['minAmountToStake'])
        ]
    );
    await hordTicketManager.deployed()
    ticketManagerContract = hordTicketManager.connect(owner);

    const HordTicketFactory = await ethers.getContractFactory('HordTicketFactory')
    const hordTicketFactory = await upgrades.deployProxy(HordTicketFactory, [
            hordCongressAddress,
            maintainersRegistry.address,
            hordTicketManager.address,
            config["maxFungibleTicketsPerPool"],
            config["uri"]
        ]
    );
    await hordTicketFactory.deployed()
    ticketFactoryContract = hordTicketFactory.connect(maintainer);

    supplyToMint = 20;

    await hordTicketManager.setHordTicketFactory(hordTicketFactory.address);
}

describe('NFTs', () => {
    before('setup contracts', async () => {
        await setupAccounts();
        await setupContracts()
    });

    describe('Minting from maintainer', async() => {
        it('should mint token', async() => {
            lastAddedId = await ticketFactoryContract.lastMintedTokenId();
            tokenId = parseInt(lastAddedId,10) + 1;
            championId = 1;
            tx = await awaitTx(ticketFactoryContract.mintNewHPoolNFT(tokenId, supplyToMint, championId));
        });

        it('should check MintedNewNFT event', async() => {
            expect(tx.events.length).to.equal(2)
            expect(tx.events[1].event).to.equal('MintedNewNFT')
            expect(parseInt(tx.events[1].args.tokenId)).to.equal(tokenId)
            expect(parseInt(tx.events[1].args.championId)).to.equal(championId)
            expect(parseInt(tx.events[1].args.initialSupply)).to.equal(supplyToMint)
        });

        it('should check that all minted tokens are on TicketManager contract', async () => {
            let balance = await ticketFactoryContract.balanceOf(ticketManagerContract.address, tokenId);
            expect(balance).to.be.equal(supplyToMint);
        })

        it('should check token supply', async() => {
            let tokenSupply = await ticketFactoryContract.getTokenSupply(tokenId);
            expect(parseInt(tokenSupply,10)).to.equal(supplyToMint, "Wrong supply minted.");
        });

        it('should check champion minted ids', async() => {
            let championMintedIds = await ticketManagerContract.getChampionTokenIds(championId);
            expect(parseInt(championMintedIds.slice(-1)[0])).to.equal(championId, "Champion ID does not match.");
        });
    });

    describe('Minting from address which is not maintainer', async() => {
       it('should not be able to mint from non-maintainer user', async() => {
           ticketFactoryContract = ticketFactoryContract.connect(user);
           lastAddedId = await ticketFactoryContract.lastMintedTokenId();
           tokenId = parseInt(lastAddedId,10) + 1;
           championId = 1;

           expect(
               await isEthException(ticketFactoryContract.mintNewHPoolNFT(tokenId, supplyToMint, championId))
           ).to.be.true
       });

       it('should not be able to mint non-ordered token id', async() => {
           ticketFactoryContract = ticketFactoryContract.connect(maintainer);
           tokenId = tokenId + 1;
           expect(
               await isEthException(ticketFactoryContract.mintNewHPoolNFT(tokenId, supplyToMint, championId))
           ).to.be.true
       });

       it('should not be able to mint more than max supply', async() => {
           ticketFactoryContract = ticketFactoryContract.connect(maintainer);
           tokenId = tokenId + 1;
           let _supplyToMint = config["maxFungibleTicketsPerPool"] + 1;
           expect(
               await isEthException(ticketFactoryContract.mintNewHPoolNFT(tokenId, supplyToMint, championId))
           ).to.be.true
       });
    });
});
