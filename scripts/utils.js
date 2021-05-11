const fs = require('fs')
const path = require('path')

function getSavedContractAddresses() {
    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-addresses.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json)
}

function saveContractAddress(network, contract, address) {
    const addrs = getSavedContractAddresses()
    addrs[network] = addrs[network] || {}
    addrs[network][contract] = address
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-addresses.json`), JSON.stringify(addrs, null, '    '))
}

function getDeploymentBlockchain() {
    let json
    try {
        json = fs.readFileSync(path.join(__dirname,'../tenderly/deployNetwork.json'))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json);
}

function saveDeploymentBlockchain(blockchain) {
    let current = getDeploymentBlockchain();
    current['network'] = blockchain;
    fs.writeFileSync(path.join(__dirname, `../tenderly/deployNetwork.json`), JSON.stringify(current, null, '    '))
}

function getSavedContractBytecodes(env) {
    if(!env) {
        env = 'local'
    }
    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-bytecodes.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json[env])
}

function saveContractBytecode(network, contract, bytecode, env) {
    if(!env) {
        env = 'local'
    }
    const bytecodes = getSavedContractBytecodes()
    bytecodes[network] = bytecodes[network] || {}
    bytecodes[network][contract] = bytecode
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-bytecodes.json`), JSON.stringify(bytecodes, null, '    '))
}


module.exports = {
    getSavedContractAddresses,
    saveContractAddress,
    getSavedContractBytecodes,
    saveContractBytecode,
    getDeploymentBlockchain,
    saveDeploymentBlockchain
}
