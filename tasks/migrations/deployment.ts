import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { eEthereumNetwork } from '../../helpers/types-common';
import { eContractid } from '../../helpers/types';
import { checkVerification } from '../../helpers/etherscan-verification';
import { getBIBAdminPerNetwork } from '../../helpers/constants';
require('dotenv').config();

task('deployment', 'Deployment in bsc-test network')
  .addFlag(
    'verify',
    'Verify contract.'
  )
  .setAction(async ({ verify }, localBRE) => {
    const DRE: HardhatRuntimeEnvironment = await localBRE.run('set-dre');
    const network = DRE.network.name as eEthereumNetwork;
    const admin = getBIBAdminPerNetwork(network);

    if (!admin) {
      throw Error(
        'The --admin parameter must be set for bsc-test network. Set an Ethereum address as --admin parameter input.'
      );
    }

    // If Etherscan verification is enabled, check needed enviroments to prevent loss of gas in failed deployments.
    if (verify) {
      checkVerification();
    }

    // 1. deploy BIBToken
    await DRE.run(`deploy-${eContractid.BIBToken}`, { verify });

    // 2. deploy TokenDividendTracker
    await DRE.run(`deploy-${eContractid.TokenDividendTracker}`, { verify });

    // 1
    await DRE.run(`initialize-${eContractid.TokenDividendTracker}`, { verify });

    // 2
    await DRE.run(`initialize-${eContractid.BIBToken}`, { verify });
  

    console.log(`\n✔️ Finished the deployment for ${network}. ✔️`);
  });
