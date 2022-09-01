import { InitializableAdminUpgradeabilityProxy} from '../../types/InitializableAdminUpgradeabilityProxy';
import { task } from 'hardhat/config';
import { eContractid} from '../../helpers/types';
import { eEthereumNetwork } from '../../helpers/types-common';
import {
  getBIBToken,
  getBIBTokenImpl,
  getTokenDividendTracker,
  deployVestingToken,
  getContract,
  registerContractInJsonDb
} from '../../helpers/contracts-helpers';
import { waitForTx } from '../../helpers/misc-utils';
import { ZERO_ADDRESS,
  getSwapRoterPerNetwork,
  getEosystemVaultPartPerNetwork,
  getPrivateSellPartPerNetwork,
  getPulicSellPartPerNetwork,
  getLiquidtyPartPerNetwork,
  getMarkettingPartPerNetwork,
  getIncentivePartPerNetwork,
  getCoperationPartPerNetwork,
  getProjectTeamPartPerNetwork,
  projectVestingConfig,
  getBUSDTokenPerNetwork,
  getBIBAdminPerNetwork
 } from '../../helpers/constants';

const { BIBToken,TeamVesting } = eContractid;

task(`initialize-${BIBToken}`, `Initialize the ${BIBToken} proxy contract`)
  .setAction(async ({}, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`\n- Initialzie ${BIBToken} proxy`);
    
    const network = localBRE.network.name as eEthereumNetwork;

    const admin = await getBIBAdminPerNetwork(network);
    const bibToken = await getBIBToken();
    const bibTokenImpl = await getBIBTokenImpl();
    const tokenDividendTracker = await getTokenDividendTracker();

    const bibTokenProxy = await getContract<InitializableAdminUpgradeabilityProxy>(
      eContractid.InitializableAdminUpgradeabilityProxy,
      bibToken.address
    );
    console.log(`
    bibTokenProxy: ${bibTokenProxy.address}
    tokenDividendTracker: ${tokenDividendTracker.address}
    router: ${getSwapRoterPerNetwork(network)}
    busd: ${getBUSDTokenPerNetwork(network)}
    `);
    const encodedInitialize = bibTokenImpl.interface.encodeFunctionData('initialize', [
      tokenDividendTracker.address,
      getSwapRoterPerNetwork(network),
      getBUSDTokenPerNetwork(network),
    ]);

    await waitForTx(
      await bibTokenProxy['initialize(address,address,bytes)'](
        bibTokenImpl.address,
        admin,
        encodedInitialize,
      {gasLimit:5e6, gasPrice:10e9})
    );

    // transfer(w1,(initialSupply.mul(15).div(100))); 
    // transfer(w2,(initialSupply.mul(25).div(100))); 
    // transfer(w3,(initialSupply.mul(15).div(100)));
    // transfer(w4,(initialSupply.mul(2).div(100)));
    // transfer(w0,(initialSupply.mul(3).div(100))); 
    // transfer(w5,(initialSupply.mul(9).div(100)));
    // transfer(w6,(initialSupply.mul(16).div(100)));
    // transfer(w7,(initialSupply.mul(15).div(100)));

    console.log(`\t Deploy team vesting contract`);
    const teamVesting = await deployVestingToken(
      getProjectTeamPartPerNetwork(network),
      projectVestingConfig.start,
      projectVestingConfig.duration
    );
    await registerContractInJsonDb(TeamVesting, teamVesting);

    // initialize address
    // 3. set market fee collector
    console.log(`\tInitialize addreses`);
    await waitForTx(
      await bibToken.initAddress(
        teamVesting.address,
        getEosystemVaultPartPerNetwork(network),
        getPrivateSellPartPerNetwork(network),
        getPulicSellPartPerNetwork(network),
        getLiquidtyPartPerNetwork(network),
        getMarkettingPartPerNetwork(network),
        getIncentivePartPerNetwork(network),
        getCoperationPartPerNetwork(network)
      ,{gasLimit:3e6, gasPrice:10e9})
      );

      // release token to wallets
      await waitForTx(
        await bibToken.setAllowTransfer(true,{gasLimit:3e6, gasPrice:10e9}));

      console.log(`\tRelease to wallets`);
      await waitForTx(
        await bibToken.release({gasLimit:3e6, gasPrice:10e9}));

      console.log(`\tFinished ${BIBToken} proxy initialize`);
  });
