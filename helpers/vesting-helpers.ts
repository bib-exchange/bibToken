import { tEthereumAddress } from './types';
import { BigNumber } from '@ethersproject/bignumber/lib/bignumber';
import { resolveSoa } from 'dns';

const SECONDS_PER_HOUR = 60 * 60;
const SECONDS_PER_MONTH = SECONDS_PER_HOUR * 24 * 30;
const CLIFF = SECONDS_PER_MONTH * 1;

export const timestamp = (date: Date) => {
  return Math.floor(date.getTime() / 1000);
};

const roles = ['investor', 'team', 'earlyContributor'];

const strategy = (role: string) => {
  if (!roles.includes(role)) {
    throw new Error(`unrecognized role: ${role}`);
  }
  const strategies = {
    ['investor']: vestingScheduleInvestor,
    ['team']: vestingScheduleTeam,
    ['earlyContributor']: vestingScheduleEarlyContributor,
  };
  const idx = Object.keys(strategies).findIndex((k) => k === role);
  return Object.values(strategies)[idx];
};

export const createSchedulePerRole = (role: string, address: string, totalAmount: BigNumber) => {
  return strategy(role)(address, totalAmount);
};

const vestingInputCommon = {
  cliff: CLIFF,
  revocable: true,
  slicePerSeconds: SECONDS_PER_HOUR,
};

const investorVestingInputBase: VestingInputBase = {
  duration: SECONDS_PER_MONTH * 18,
  start: timestamp(new Date(Date.UTC(2022, 9 - 1, 1))),
  ...vestingInputCommon,
};

const earlyContributorVestingInputBase: VestingInputBase = {
  duration: SECONDS_PER_MONTH * 18,
  start: timestamp(new Date(Date.UTC(2022, 9 - 1, 1))),
  ...vestingInputCommon,
};

const teamVestingInputBase: VestingInputBase = {
  duration: SECONDS_PER_MONTH * 6,
  start: timestamp(new Date(Date.UTC(2022, 2 - 1, 1))),
  ...vestingInputCommon,
};

interface VestingInputBase {
  start: number;
  cliff: number;
  duration: number;
  slicePerSeconds: number;
  revocable: boolean;
}

export interface VestingInput extends VestingInputBase {
  beneficiary: tEthereumAddress;
  amount: BigNumber;
}

const vestingScheduleInvestor = (beneficiary: tEthereumAddress, total: BigNumber): VestingInput => {
  return {
    beneficiary,
    amount: total,
    ...investorVestingInputBase,
  };
};

const vestingScheduleEarlyContributor = (
  beneficiary: tEthereumAddress,
  total: BigNumber
): VestingInput => {
  return {
    beneficiary,
    amount: total,
    ...earlyContributorVestingInputBase,
  };
};

const vestingScheduleTeam = (beneficiary: tEthereumAddress, total: BigNumber): VestingInput => {
  return {
    beneficiary,
    amount: total,
    ...teamVestingInputBase,
  };
};
