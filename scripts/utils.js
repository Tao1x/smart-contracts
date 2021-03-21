const fs = require('fs')
const path = require('path')

function getSavedContractAddresses(env) {
    if(!env) {
        env = 'local'
    }

    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-addresses-${env}.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json)
}

function saveContractAddress(network, contract, address, env) {
    if(!env) {
        env = 'local'
    }
    const addrs = getSavedContractAddresses()
    addrs[network] = addrs[network] || {}
    addrs[network][contract] = address
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-addresses-${env}.json`), JSON.stringify(addrs, null, '    '))
}

function getSavedContractBytecodes(env) {
    if(!env) {
        env = 'local'
    }
    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../deployments/contract-bytecodes-${env}.json`))
    } catch (err) {
        json = '{}'
    }
    return JSON.parse(json)
}

function saveContractBytecode(network, contract, bytecode, env) {
    if(!env) {
        env = 'local'
    }
    const bytecodes = getSavedContractBytecodes()
    bytecodes[network] = bytecodes[network] || {}
    bytecodes[network][contract] = bytecode
    fs.writeFileSync(path.join(__dirname, `../deployments/contract-bytecodes-${env}.json`), JSON.stringify(bytecodes, null, '    '))
}

module.exports = {
    getSavedContractAddresses,
    saveContractAddress,
    getSavedContractBytecodes,
    saveContractBytecode
}
