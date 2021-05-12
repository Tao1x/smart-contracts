const {
    address,
    encodeParameters
} = require('../ethereum');
const config = require('../../deployments/deploymentConfig.json');
const { ethers, expect, isEthException, awaitTx, toHordDenomination, hexify } = require('../setup')


let hordCongress, hordToken, accounts, owner, ownerAddr, anotherAccount, anotherAccountAddr, r
let nonCongressAcc, nonCongressAccAddr
let targets, values, signatures, calldatas, description, proposalId, numberOfProposals

async function setupContractAndAccounts () {
    
}

describe('NFTs', () => {
    before('setup contracts', async () => {
        await setupContractAndAccounts();
    });
});
