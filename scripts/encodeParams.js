const {
    encodeParameters
} = require('../test/ethereum');


async function main() {
    encodeParameters(process.argv[1], process.argv[2]);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
