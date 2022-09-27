import { task } from 'hardhat/config';
import { eContractid } from '../../helpers/types';
import {
  deployBIBToken,
  registerContractInJsonDb,
  deployInitializableAdminUpgradeabilityProxy
} from '../../helpers/contracts-helpers';

const { BIBToken, BIBTokenImpl } = eContractid;

task(`deploy-${BIBToken}`, `Deploy the ${BIBToken} contract`)
  .addFlag('verify', 'Proceed with the Etherscan verification')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`\n- ${BIBToken} deployment`);

    console.log(`\tDeploying ${BIBToken} implementation ...`);
    const bibTokenImpl = await deployBIBToken(verify);
    await registerContractInJsonDb(BIBTokenImpl, bibTokenImpl);

    console.log(`\tDeploying ${BIBToken} Transparent Proxy ...`);
    const bibTokenProxy = await deployInitializableAdminUpgradeabilityProxy(verify);
    await registerContractInJsonDb(BIBToken, bibTokenProxy);

    console.log(`\tFinished ${BIBToken} proxy and implementation deployment`);
  });
