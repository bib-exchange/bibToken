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

task(`run-exclude`, `Tryp to adde address to whitelist`)
  .setAction(async ({}, localBRE) => {
    await localBRE.run('set-dre');

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }
    let exclude:string = "";
    
    while(!exclude && exclude === ""){
        exclude = promptUser(
            "❗❗❗ Type the address to continue: "
        );
        if (/^0x[0-9a-fA-F]{40}$/.test(exclude)) {
            break;
        } else {
            console.log(`❌ Invlaid address`);
        }
    }
    const bibToken = await getBIBToken();
    const dvidednTraker = await getTokenDividendTracker();

    console.log(`⏳ Try to add ${exclude} to transfer && dividend && noporcess special cases  `);
    if(!(await bibToken.isFromWhiteList(exclude))) {
        await waitForTx(
          await bibToken.setFeeWhiteList(exclude, true, true)
        );
        console.log(`\t🏁 Added ${exclude} to transfer-out white list`);
    } else {
        console.log(`\t✅ ${exclude} existed in transfer-out white list`);
    }
    if(!(await bibToken.isToWhiteList(exclude))) {
        await waitForTx(
            await bibToken.setFeeWhiteList(exclude, true, false)
        );
        console.log(`\t🏁 Added ${exclude} to transfer-in white list`);
    } else {
        console.log(`\t✅ ${exclude} existed in transfer-in white list`);
    }

    if(!(await dvidednTraker.excludedFromDividends(exclude))){
        await waitForTx(
            await dvidednTraker.excludeFromDividends(exclude)
        );
        console.log(`\t🏁 Added ${exclude} to divided exlude list`);
    } else {
        console.log(`\t✅ ${exclude} existed in dividend list`);
    }

    if(!(await bibToken.noProcessList(exclude))){
        await waitForTx(
            await bibToken.setNoProcessList(exclude, true)
        );
        console.log(`\t🏁 Added ${exclude} to noprocess list`);
    } else {
        console.log(`\t✅ ${exclude} existed in noprocess list`);
    }
  });
