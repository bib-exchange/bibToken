import { MockToken } from './../types/MockToken.d';
import rawBRE from 'hardhat';

import {
  getEthersSigners,
  deployMockBIBToken,
  deployMockBUSDToken,
  deployMockOracleToken,
  deploySoccerStarNft,
  //deployInitializableAdminUpgradeabilityProxy,
  insertContractAddressInDb,
  registerContractInJsonDb,
} from '../helpers/contracts-helpers';

import path from 'path';
import fs from 'fs';

import { Signer } from 'ethers';

import { initializeMakeSuite } from './helpers/make-suite';
import { waitForTx, DRE } from '../helpers/misc-utils';
import { eContractid } from '../helpers/types';
import { parseEther } from 'ethers/lib/utils';

['misc', 'deployments', 'migrations'].forEach((folder) => {
  const tasksPath = path.join(__dirname, '../tasks', folder);
  fs.readdirSync(tasksPath).forEach((task) => require(`${tasksPath}/${task}`));
});

const buildTestEnv = async (deployer: Signer, secondaryWallet: Signer) => {
  console.time('setup');

  const treasury = await secondaryWallet.getAddress();
  const mockBib = await deployMockBIBToken();
  const mockBusd = await deployMockBUSDToken();
  const mockBibOracle = await deployMockOracleToken();
  
  await insertContractAddressInDb(eContractid.MockBib, mockBib.address);
  await insertContractAddressInDb(eContractid.MockBusd, mockBusd.address);
  await insertContractAddressInDb(eContractid.MockBibOracle, mockBibOracle.address);

  console.timeEnd('setup');
};

before(async () => {
  await rawBRE.run('set-dre');
  const [deployer, secondaryWallet] = await getEthersSigners();
  console.log('-> Deploying test environment...');
  await buildTestEnv(deployer, secondaryWallet);
  await initializeMakeSuite();
  console.log('\n***************');
  console.log('Setup and snapshot finished');
  console.log('***************\n');
});
