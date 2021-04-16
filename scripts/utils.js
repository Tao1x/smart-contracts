const fs = require('fs')
const path = require('path')

function getSavedContractAddresses(network) {
    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-addresses-${network}.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json)
}

function saveContractAddress(network, contract, address) {
    const addrs = getSavedContractAddresses(network)
    addrs[network] = addrs[network] || {}
    addrs[network][contract] = address
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-addresses-${network}.json`), JSON.stringify(addrs, null, '    '))
}

function getSavedContractBytecodes(network) {
    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-bytecodes-${network}.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json)
}

function saveContractBytecode(network, contract, bytecode) {
    const bytecodes = getSavedContractBytecodes(network)
    bytecodes[network] = bytecodes[network] || {}
    bytecodes[network][contract] = bytecode
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-bytecodes-${network}.json`), JSON.stringify(bytecodes, null, '    '))
}

module.exports = {
    getSavedContractAddresses,
    saveContractAddress,
    getSavedContractBytecodes,
    saveContractBytecode
}
