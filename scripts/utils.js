const fs = require('fs')
const path = require('path')

function getSavedContractAddresses(env) {
    if(!env) {
        env = 'local'
    }

    let json
    try {
        json = fs.readFileSync(path.join(__dirname, `../contract-addresses-${env}.json`))
    } catch (err) {
        json = '{}'
    }
    const addrs = JSON.parse(json)
    return addrs
}

function saveContractAddress(network, contract, address, env) {
    if(!env) {
        env = 'local'
    }
    const addrs = getSavedContractAddresses()
    addrs[network] = addrs[network] || {}
    addrs[network][contract] = address
    fs.writeFileSync(path.join(__dirname, `../contract-addresses-${env}.json`), JSON.stringify(addrs, null, '    '))
}

module.exports = {
    getSavedContractAddresses,
    saveContractAddress,
}
