const {
    encodeParameters
} = require('../test/ethereum');


async function main() {
    let types = process.argv[2];
    let values = process.argv[3];
    console.log('Encoded: ',encodeParameters(types.split(','), values.split(',')));
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
