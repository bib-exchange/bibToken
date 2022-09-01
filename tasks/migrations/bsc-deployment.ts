import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { eEthereumNetwork } from '../../helpers/types-common';
import { eContractid } from '../../helpers/types';
import { checkVerification } from '../../helpers/etherscan-verification';
import { getBIBAdminPerNetwork } from '../../helpers/constants';
require('dotenv').config();

task('bsc-deployment', 'Deployment in bsc network')
  .addFlag(
    'verify',
    'Verify contracts.'
  )
  .setAction(async ({ verify }, localBRE) => {
    const DRE: HardhatRuntimeEnvironment = await localBRE.run('set-dre');
    const network = DRE.network.name as eEthereumNetwork;
    const admin = getBIBAdminPerNetwork(network);
    if (!admin) {
      throw Error(
        'The --admin parameter must be set for bsc network. Set an Ethereum address as --admin parameter input.'
      );
    }

    await DRE.run(`deployment`, { verify });

    console.log('\n✔️ Finished the deployment of the BIB Token Astar Enviroment. ✔️');
  });
