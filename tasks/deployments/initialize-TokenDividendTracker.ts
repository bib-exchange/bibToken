import { InitializableAdminUpgradeabilityProxy} from '../../types/InitializableAdminUpgradeabilityProxy';
import { task } from 'hardhat/config';
import { eContractid} from '../../helpers/types';
import { eEthereumNetwork } from '../../helpers/types-common';
import {
  getBIBToken,
  getBIBTokenImpl,
  getTokenDividendTracker,
  getTokenDividendTrackerImpl,
  getContract,
  registerContractInJsonDb
} from '../../helpers/contracts-helpers';
import { waitForTx } from '../../helpers/misc-utils';
import { ZERO_ADDRESS,
  getBUSDTokenPerNetwork,
  getBIBAdminPerNetwork,
  CLAIM_WAIT
 } from '../../helpers/constants';

const { TokenDividendTracker } = eContractid;

task(`initialize-${TokenDividendTracker}`, `Initialize the ${TokenDividendTracker} proxy contract`)
  .setAction(async ({}, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`\n- Initialzie ${TokenDividendTracker} proxy`);
    
    const network = localBRE.network.name as eEthereumNetwork;

    const admin = await getBIBAdminPerNetwork(network);
    const bibToken = await getBIBToken();
    const tokenDividendTracker = await getTokenDividendTracker();
    const tokenDividendTrackerImpl = await getTokenDividendTrackerImpl();

    const tokenDividendTrackerProxy = await getContract<InitializableAdminUpgradeabilityProxy>(
      eContractid.InitializableAdminUpgradeabilityProxy,
      tokenDividendTracker.address
    );

    const encodedInitialize = tokenDividendTrackerImpl.interface.encodeFunctionData('initialize', [
      await getBUSDTokenPerNetwork(network),
    ]);

    await waitForTx(
      await tokenDividendTrackerProxy['initialize(address,address,bytes)'](
        tokenDividendTrackerImpl.address,
        admin,
        encodedInitialize
      )
    );

    // set controller
    console.log(`\t set tokenDividendTracker controller to ${bibToken.address}`);
    await waitForTx(
      await tokenDividendTracker.setController(bibToken.address)
    );

    // set claim wait
    console.log(`\t set tokenDividendTracker claim wait duration to ${CLAIM_WAIT}`);
    await waitForTx(
      await tokenDividendTracker.updateClaimWait(CLAIM_WAIT)
    );

    console.log(`\tFinished ${TokenDividendTracker} proxy initialize`);
  });
