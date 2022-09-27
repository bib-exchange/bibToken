import { task } from 'hardhat/config';
import { eContractid } from '../../helpers/types';
import {
  deployTokenDividendTracker,
  registerContractInJsonDb,
  deployInitializableAdminUpgradeabilityProxy
} from '../../helpers/contracts-helpers';

const { TokenDividendTracker, TokenDividendTrackerImpl } = eContractid;

task(`deploy-${TokenDividendTracker}`, `Deploy the ${TokenDividendTracker} contract`)
  .addFlag('verify', 'Proceed with the Etherscan verification')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`\n- ${TokenDividendTracker} deployment`);

    console.log(`\tDeploying ${TokenDividendTracker} implementation ...`);
    const tokenDividendTrackerImpl = await deployTokenDividendTracker(verify);
    await registerContractInJsonDb(TokenDividendTrackerImpl, tokenDividendTrackerImpl);

    console.log(`\tDeploying ${TokenDividendTracker} Transparent Proxy ...`);
    const tokenDividendTrackerProxy = await deployInitializableAdminUpgradeabilityProxy(verify);
    await registerContractInJsonDb(TokenDividendTracker, tokenDividendTrackerProxy);

    console.log(`\tFinished ${TokenDividendTracker} proxy and implementation deployment`);
  });
