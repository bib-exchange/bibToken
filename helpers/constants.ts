import { tEthereumAddress } from './types';
import { getParamPerNetwork } from './misc-utils';
import { eEthereumNetwork } from './types-common';
import {BigNumber} from "bignumber.js";
import {BytesLike, ethers} from "ethers";

export const BUIDLEREVM_CHAINID = 31337;
export const COVERAGE_CHAINID = 1337;
export const CLAIM_WAIT = 3600;//1hour

export const ZERO_ADDRESS: tEthereumAddress = '0x0000000000000000000000000000000000000000';
export const ONE_ADDRESS = '0x0000000000000000000000000000000000000001';
export const MAX_UINT_AMOUNT =
  '115792089237316195423570985008687907853269984665640564039457584007913129639935';
export const MOCK_ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
export const WAD = Math.pow(10, 18).toString();

export const SUPPORTED_ETHERSCAN_NETWORKS = ['main', 'bsc', 'bsc_test'];
export interface LinerVestingConfig {
  start: string,
  duration: string
};

export const projectVestingConfig:LinerVestingConfig = {
  start: "0",
  duration : (4 * 365 * 24 * 3600).toFixed()
};

export const getBIBTokenDomainSeparatorPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
  getParamPerNetwork<tEthereumAddress>(
    {
      [eEthereumNetwork.coverage]:
        '0x6334ce07fc771d21f0634439a587b364f00756c209bb425d2c4873b672e6d265',
      [eEthereumNetwork.hardhat]:
        '0x199a7af9929982744df0725704a9dcbfc5809292509419575dca5613a7d9fb91',
      [eEthereumNetwork.bsc_test]: '',
      [eEthereumNetwork.bsc]: '',
    },
    network
  );

// BIBProtoGovernance address as admin of BIBToken and Migrator
export const getBIBAdminPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
  getParamPerNetwork<tEthereumAddress>(
    {
      [eEthereumNetwork.coverage]: "0xA1198B5dE887cd2916817C6D5d902ddfE210aBe9",
      [eEthereumNetwork.hardhat]: '0xA1198B5dE887cd2916817C6D5d902ddfE210aBe9',
      [eEthereumNetwork.bsc_test]: '0xA1198B5dE887cd2916817C6D5d902ddfE210aBe9',
      [eEthereumNetwork.bsc]: '0x3b681f97Acd15eF59FE9A229eDf16458c94f1F43',//bsc safe
    },
    network
  );

  type BN = ethers.BigNumberish;


export const getBUSDTokenPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: '0x9555f1998C31D4387c044582869c77B2EB4bb2cc',
    [eEthereumNetwork.bsc_test]: '0x9555f1998C31D4387c044582869c77B2EB4bb2cc', // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getSwapRoterPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3',
    [eEthereumNetwork.bsc_test]: '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3', // TODO: need to replace
    [eEthereumNetwork.bsc]: '0x10ED43C718714eb63d5aA57B78B54704E256024E',
  },
  network
);

export const getEosystemVaultPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0xCF0586bb817599bf5eAd931155aB6a06464C9A27", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getProjectTeamPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0xb5DB01684D87988bEF64b6999151697e49494Cd1", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getPrivateSellPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x8801a6bC0aEa3145643Cc324995C37981b795684", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getPulicSellPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x32ECC6FeB8862d86EAA064F3c7593f50CCFf8813", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getLiquidtyPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x239728A640f4C9362EDa1bAfd915b4fB8e642Add", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getMarkettingPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x3640DF3e8089Ac7E3CDC358d46277eF3Abdaa20b", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getIncentivePartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x13bBd022e49e22FD261e34184AE4C952A2097a12", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);

export const getCoperationPartPerNetwork = (network: eEthereumNetwork): tEthereumAddress =>
getParamPerNetwork<tEthereumAddress>(
  {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.bsc_test]: "0x0CEF8b80dD908C13d22E380D2BC4AAe575CE51ce", // TODO: need to replace
    [eEthereumNetwork.bsc]: ZERO_ADDRESS,
  },
  network
);