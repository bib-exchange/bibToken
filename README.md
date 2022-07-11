# bib token

# BIB Token

## Introduction

This project(`BIB token` smart contract) is based on the evm chain.

## Getting Started

This is a hardhat project. To install required node.js modules

```bash
npm ci
```

To compile the solidity source code

```bash
yarn compile
```

To run ERC20 unit test

```bash
yarn test
```

To run ERC721/NFT unit test

```bash
yarn test
```

To deploy the smart contract on Ethereum ropsten testnet

```bash
yarn deploy

npx hardhat run deploy/deploy_bibtoken.js --network rinkeby


yarn deploy_crowdsale
npx hardhat run deploy/deploy_crowdsale.js --network rinkeby
```



## Test report

Unit test and performance(gas consumption) results, please see [test report](docs/test_report.txt) and [gas consumption test report](docs/performance_test.txt).

## Version history

Change, please see [Change log](docs/CHANGELOG.md) for changes.

## Contribute

Any contribution is welcomed to make it better.

If you have any questions, please create an [issue]().

## Security report

If you have any security issue, please send to <security@bib.io>.

## License



[MIT LICENSE](LICENSE)
