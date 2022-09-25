import { task,types } from 'hardhat/config';
import { eContractid } from '../../helpers/types';
import { eEthereumNetwork } from '../../helpers/types-common';
import { waitForTx } from '../../helpers/misc-utils';
import { ethers } from 'ethers';
const promptUser = require('prompt-sync')();

import {
getBIBToken,
getTokenDividendTracker
} from '../../helpers/contracts-helpers';

const DEFAULT_GAS_PROCESSING = 300000;

task(`enable-dividend`, `Try to enable or disable dividend`)
  .addFlag('enable', 'True--enable swap && distribute dividen, false otherwise')
  .setAction(async ({enable}, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`⏳ Try to ${enable?"enbale":"disable"} swap && distribute dividend `);

    const bibToken = await getBIBToken();
    const swapEnable = await bibToken.swapEnabled();
    if(enable){
        if(!swapEnable){
            waitForTx(await bibToken.setSwapEnabled(enable));
            console.log(`\tEnabled swap`);
        } else {
            console.log(`\tSwap enabled`);
        }
    } else {
        if(!swapEnable){
            console.log(`\tSwap disabled`);
        } else {
            waitForTx(await bibToken.setSwapEnabled(enable));
            console.log(`\tDisabled swap`);
        }
    }

    const gas = await bibToken.gasForProcessing();
    if(enable){
        if(gas.lte(0)){
            waitForTx(await bibToken.updateGasForProcessing(DEFAULT_GAS_PROCESSING));
            console.log(`\tUpdate proccessing gas to ${DEFAULT_GAS_PROCESSING}`);
        } else {
            console.log(`\tExisted proccessing gas ${gas}`);
        }
    } else {
        if(gas.gt(0)){
            waitForTx(await bibToken.updateGasForProcessing(0));
            console.log(`\tUpdate proccessing gas to 0`)
        } else {
            console.log(`\tThe proccessing gas is now 0`);
        }
    }
  });
