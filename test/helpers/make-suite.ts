import { evmRevert, evmSnapshot, DRE } from '../../helpers/misc-utils';
import { Signer } from 'ethers';
import {
  getEthersSigners,
  getMockBIBToken,
  getMockBUSDToken,
  getMockOracleToken,
} from '../../helpers/contracts-helpers';
import { tEthereumAddress } from '../../helpers/types';

import chai from 'chai';
// @ts-ignore
import bignumberChai from 'chai-bignumber';
import { MockBib } from '../../types/MockBib';
import { MockBusd } from '../../types/MockBusd';
import { MockBibOracle } from '../../types/MockBibOracle';
import {SoccerStarNft} from '../../types/SoccerStarNft';

chai.use(bignumberChai());

export interface SignerWithAddress {
  signer: Signer;
  address: tEthereumAddress;
}
export interface TestEnv {
  deployer: SignerWithAddress;
  users: SignerWithAddress[];
  mockBib: MockBib;
  mockBusd: MockBusd;
  mockBibOracle: MockBibOracle;
  soccerStarNft: SoccerStarNft;
}

let buidlerevmSnapshotId: string = '0x1';
const setBuidlerevmSnapshotId = (id: string) => {
  if (DRE.network.name === 'hardhat') {
    buidlerevmSnapshotId = id;
  }
};

const testEnv: TestEnv = {
  deployer: {} as SignerWithAddress,
  users: [] as SignerWithAddress[],
  mockBib: {} as MockBib,
  mockBusd: {} as MockBusd,
  mockBibOracle: {} as MockBibOracle,
  soccerStarNft: {} as SoccerStarNft,
} as TestEnv;

export async function initializeMakeSuite() {
  const [_deployer, ...restSigners] = await getEthersSigners();
  const deployer: SignerWithAddress = {
    address: await _deployer.getAddress(),
    signer: _deployer,
  };

  for (const signer of restSigners) {
    testEnv.users.push({
      signer,
      address: await signer.getAddress(),
    });
  }
  testEnv.deployer = deployer;
  testEnv.mockBib = await getMockBIBToken();
  testEnv.mockBusd = await getMockBUSDToken();
  testEnv.mockBibOracle = await getMockOracleToken();
}

export function makeSuite(name: string, tests: (testEnv: TestEnv) => void) {
  describe(name, () => {
    before(async () => {
      setBuidlerevmSnapshotId(await evmSnapshot());
    });
    tests(testEnv);
    after(async () => {
      await evmRevert(buidlerevmSnapshotId);
    });
  });
}
