import { task, types, subtask } from 'hardhat/config';
import { exit } from 'process';
const promptUser = require('prompt-sync')();
import fs from 'fs';
import { Contract } from 'ethers';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import { getContract, getEthersSigners } from '../../helpers/contracts-helpers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { string } from 'hardhat/internal/core/params/argumentTypes';

// NOTE the deployed name and corresponding artifact name do not match so we'll need to include both here
const listOfOwnableContractsForProduction = [
  {
    deployedName: "SoccerStarNft",
    artifactName: "SoccerStarNft"
  },
  {
    deployedName: "ComposedSoccerStarNft",
    artifactName: "ComposedSoccerStarNft"
  },
  {
    deployedName: "SoccerStarNftMarket",
    artifactName: "SoccerStarNftMarket"
  },
  {
    deployedName: "StakedDividendTracker",
    artifactName: "StakedDividendTracker"
  },
  {
    deployedName: "StakedSoccerStarNftV2",
    artifactName: "StakedSoccerStarNftV2"
  },
  {
    deployedName: "BIBNode",
    artifactName: "BIBNode"
  },
  {
    deployedName: "BIBDividend",
    artifactName: "BIBDividend"
  },
  {
    deployedName: "BIBStaking",
    artifactName: "BIBStaking"
  },
  {
    deployedName: "DividendCollector",
    artifactName: "DividendCollector"
  }
];

const listOfOwnableContractsForTestnet = [
...listOfOwnableContractsForProduction
];

const listOfProxyContractsForProduction = [
  {
    deployedName: "example",
    artifactName: "InitializableAdminUpgradeabilityProxy"
  }
];

const listOfProxyContractsForTestnet = [
  {
    deployedName: "BIBToken",
    artifactName: "InitializableAdminUpgradeabilityProxy"
  }
];

function getJSON(fileName: string){
  let jsonString = '';
  let outputJSON = {};
  try {
    jsonString = fs.readFileSync(fileName, 'utf-8');
  } catch (err) {
    console.log(`🚨 Error retrieving "${fileName}" :`, err);
    exit();
  }
  try {
    outputJSON = JSON.parse(jsonString);
  } catch (err) {
    console.log(`🚨 Error parsing "${fileName}" json: `, err);
    exit();
  }

  return outputJSON;
}

subtask(
  'transfer-ownership',
  'Transfers ownership of all ownable contracts in module for a specific network'
)
  .addFlag('debug', 'Print all blockchain transaction information')
  .setAction(async ({ debug }, localBRE) => {
    const DRE: HardhatRuntimeEnvironment = await localBRE.run('set-dre');

    let owner = promptUser(`❓ enter the owner to replace:`);
    if(!owner || "" === owner){
      console.error(`Invalid owner`);
      exit(1);
    }

    // get deployment json
    let deploymentJSON = getJSON('deployed-contracts.json');

    // Retreive corresponding list of ownable contracts
    let listOfOwnableContracts: {deployedName: string, artifactName: string}[];
    if (DRE.network.name == 'bsc') {
      listOfOwnableContracts = listOfOwnableContractsForProduction;
    } else {
      listOfOwnableContracts = listOfOwnableContractsForTestnet;
    }
    
    // Deployer address
    const [deployer] = await getEthersSigners();
    const deployedAddress = await deployer.getAddress();


    // Create list of contracts objects from listOfOwnableContracts that have deployer's address as the owner address
    let listOfContractsToTransfer: { name: string; contract: Contract }[] = [];
    for (let i = 0; i < listOfOwnableContracts.length; i++) {
      const contractArtifactName = listOfOwnableContracts[i].artifactName;
      const contractDeployedName = listOfOwnableContracts[i].deployedName;
      const contractAddress = deploymentJSON[contractDeployedName as keyof typeof deploymentJSON][DRE.network.name]["address"];
      const contract = await getContract(contractArtifactName, contractAddress);
      const contractOwner = (await contract.owner()).toString();

      if (contractOwner == deployedAddress) {
        listOfContractsToTransfer.push({ name: contractDeployedName, contract: contract });
      }
    }

    // Confirmation
    console.log('🔍 Ownership transfer Information:');
    console.log(`\tNetwork: ${DRE.network.name}`);
    console.log(`\tDeployer address: "${deployedAddress}"`);
    console.log(`\tNew owner address: "${owner}"`);
    console.log(`\tList of contracts to transfer ownership of:`);
    for (let i = 0; i < listOfContractsToTransfer.length; i++) {
      console.log(
        `\t\t${listOfContractsToTransfer[i].name} @ "${listOfContractsToTransfer[i].contract.address}"`
      );
    }
    let confirmation = promptUser(`❓ Type 'yes' continue: `);
    if (confirmation != 'yes') {
      console.log('❌ Deployment canceled');
      return;
    }
    if (DRE.network.name == 'bsc') {
      const astarConfirmation = promptUser(
        "❗❗❗ Are you sure you want to run this PRODUCTION CALL? Type 'I yes' to continue: "
      );
      if (astarConfirmation != 'yes') {
        console.log('❌ You did not enter the right input. Prod call not permitted');
        return;
      }
    }
    console.log('👍 Continuing ownership transfer');

    // Get nonce
    const deployerProvider: any = deployer.provider;
    let txCount = await deployerProvider.getTransactionCount(deployedAddress);
    if (debug) console.log('ℹ️  Starting nonce:', txCount);

    // execute transfer txns
    let deployedYetConfirmedTransferTxns: { name: string; txn: TransactionResponse }[] = [];
    for (let i = 0; i < listOfContractsToTransfer.length; i++) {
      const contractName = listOfContractsToTransfer[i].name;
      console.log(`⏳ Transfer ownership for ${contractName}...`);
      if (debug) {
        console.log(`ℹ️  Txn deployment info:`);
        console.log('\tTxn nonce:', txCount);
      }

      const contract = listOfContractsToTransfer[i].contract;
      const transferTxn = await contract.transferOwnership(owner, { nonce: txCount++ });

      deployedYetConfirmedTransferTxns.push({ name: contractName, txn: transferTxn });
    }

    // confirm transfer txns
    console.log('👍 All txns deployed. Confirming now...');
    for (let i = 0; i < deployedYetConfirmedTransferTxns.length; i++) {
      const contractName = deployedYetConfirmedTransferTxns[i].name;
      const transferTxn = deployedYetConfirmedTransferTxns[i].txn;
      const transferReceipt = await transferTxn.wait();
      console.log(`...Transfer ownership for ${contractName} confirmed ✅`);
      if (debug) {
        console.log(`ℹ️  Txn confirmation info:`);
        console.log('\tTxn hash:', transferReceipt.transactionHash);
        console.log('\tBlock number:', transferReceipt.blockNumber);
      }
    }

    for (let i = 0; i < listOfContractsToTransfer.length; i++) {
      const contractName = listOfContractsToTransfer[i].name;
      const contract = listOfContractsToTransfer[i].contract;
      console.log(`${contractName} has new owner: ${await contract.owner()}`);
    }

    console.log(`🏁 Ownership transfer successful 🏁`);
  });

subtask(
  'change-admin-address',
  'Changes admin address of all proxy contracts in module for a specific network'
)
  .addParam('admin', 'Address of the new proxy admin', undefined, types.string)
  .addFlag('debug', 'Print all blockchain transaction information')
  .setAction(async ({ admin, debug }, localBRE) => {
    const DRE: HardhatRuntimeEnvironment = await localBRE.run('set-dre');

    console.log(`⏳⏳ Starting admin changing...`);

    // get deployment json
    let deploymentJSON = getJSON('deployed-contracts.json');

    // Retreive corresponding list of ownable contracts
    let listOfProxyContracts: {deployedName: string, artifactName: string}[];
    if (DRE.network.name == 'bsc') {
      listOfProxyContracts = listOfProxyContractsForProduction;
    } else {
      listOfProxyContracts = listOfProxyContractsForTestnet;
    }

    // Deployer address
    const [deployer] = await getEthersSigners();
    const deployedAddress = await deployer.getAddress();

    // Create list of contracts objects from listOfProxyContracts that have deployer's address as the admin address
    let listOfContractsToChangeAdmin: { name: string; contract: Contract }[] = [];
    for (let i = 0; i < listOfProxyContracts.length; i++) {
      const contractDeployedName = listOfProxyContracts[i].deployedName;
      const contractArtifactName = listOfProxyContracts[i].artifactName;
      const contractAddress = deploymentJSON[contractDeployedName as keyof typeof deploymentJSON][DRE.network.name]["address"];
      const contract = await getContract(contractArtifactName, contractAddress);
      listOfContractsToChangeAdmin.push({ name: contractDeployedName, contract: contract });
    }

    // Confirmation
    console.log('🔍 Admin change Information:');
    console.log(`\tNetwork: ${DRE.network.name}`);
    console.log(`\tDeployer address: "${deployedAddress}"`);
    console.log(`\tNew admin address: "${admin}"`);
    console.log(`\tList of contracts to change admin of:`);
    for (let i = 0; i < listOfContractsToChangeAdmin.length; i++) {
      console.log(
        `\t\t${listOfContractsToChangeAdmin[i].name} @ "${listOfContractsToChangeAdmin[i].contract.address}"`
      );
    }
    let confirmation = promptUser(`❓ Type 'change admin' continue: `);
    if (confirmation != 'change admin') {
      console.log('❌ Deployment canceled');
      return;
    }
    if (DRE.network.name == 'bsc') {
      const astarConfirmation = promptUser(
        "❗❗❗ Are you sure you want to run this PRODUCTION CALL? Type 'I UNDERSTAND' to continue: "
      );
      if (astarConfirmation != 'I UNDERSTAND') {
        console.log('❌ You did not enter the right input. Prod call not permitted');
        return;
      }
    }
    console.log('👍 Continuing admin change');

    // Get nonce
    const deployerProvider: any = deployer.provider;
    let txCount = await deployerProvider.getTransactionCount(deployedAddress);
    if (debug) console.log('ℹ️  Starting nonce:', txCount);

    // execute transfer txns
    let deployedYetConfirmedTransferTxns: { name: string; txn: TransactionResponse }[] = [];
    for (let i = 0; i < listOfContractsToChangeAdmin.length; i++) {
      const contractName = listOfContractsToChangeAdmin[i].name;
      console.log(`⏳ Change admin for ${contractName}...`);
      if (debug) {
        console.log(`ℹ️  Txn deployment info:`);
        console.log('\tTxn nonce:', txCount);
      }

      const contract = listOfContractsToChangeAdmin[i].contract;
      const transferTxn = await contract.changeAdmin(admin, { nonce: txCount++ });

      deployedYetConfirmedTransferTxns.push({ name: contractName, txn: transferTxn });
    }

    // confirm transfer txns
    console.log('👍 All txns deployed. Confirming now...');
    for (let i = 0; i < deployedYetConfirmedTransferTxns.length; i++) {
      const contractName = deployedYetConfirmedTransferTxns[i].name;
      const transferTxn = deployedYetConfirmedTransferTxns[i].txn;
      const transferReceipt = await transferTxn.wait();
      console.log(`...admin change for ${contractName} confirmed ✅`);
      if (debug) {
        console.log(`ℹ️  Txn confirmation info:`);
        console.log('\tTxn hash:', transferReceipt.transactionHash);
        console.log('\tBlock number:', transferReceipt.blockNumber);
      }
    }

    console.log(`🏁 Admin change successful 🏁`);
  });

task(
  'migrate-owner-and-admin',
  'Will transfer ownership and change admin for all ownable and proxy contracts in module for a specific network'
)
  .addOptionalParam('admin', 'Address of the new proxy admin', undefined, types.string)
  .addFlag('debug', 'Print all blockchain transaction information')
  .addFlag('noAdminChange', 'Skips admin change step')
  .addFlag('noOwnershipTransfer', 'Skips ownership transfer step')
  .setAction(
    async (
      { admin, debug, noAdminChange, noOwnershipTransfer },
      localBRE
    ) => {
      const DRE: HardhatRuntimeEnvironment = await localBRE.run('set-dre');

      // Compile contracts
      console.log('⏳ Compiling smart contracts... ');
      await DRE.run('compile');

      if (!noAdminChange) {
        await DRE.run('change-admin-address', { admin: admin, debug: debug });
      }

      if (!noOwnershipTransfer) {
        await DRE.run('transfer-ownership', {debug: debug });
      }
    }
  );
