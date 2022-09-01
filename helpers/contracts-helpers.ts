
import { Contract, Signer, utils, ethers, BigNumberish } from 'ethers';
import { Artifact } from 'hardhat/types';
import { Artifact as BuidlerArtifact } from '@nomiclabs/buidler/types';
import { readArtifact as buidlerReadArtifact } from '@nomiclabs/buidler/plugins';
import { getDb, DRE, waitForTx } from './misc-utils';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {eEthereumNetwork} from "./types-common";
import { eContractid, tStringTokenSmallUnits,tEthereumAddress } from './types';
import { MOCK_ETH_ADDRESS, SUPPORTED_ETHERSCAN_NETWORKS } from './constants';
import BigNumber from 'bignumber.js';
import { InitializableAdminUpgradeabilityProxy } from '../types/InitializableAdminUpgradeabilityProxy';
import { signTypedData_v4, TypedData } from 'eth-sig-util';
import { fromRpcSig, ECDSASignature } from 'ethereumjs-util';
import { verifyContract } from './etherscan-verification';
import { BibToken, TokenDividendTracker, VestingToken } from '../types';
import {TokenDividendTracker__factory, TokenDividendTrackerLibraryAddresses} from '../types/factories/TokenDividendTracker__factory'

export const registerContractInJsonDb = async (contractId: string, contractInstance: Contract) => {
  const currentNetwork = DRE.network.name;
  if (currentNetwork !== 'hardhat' && currentNetwork !== 'coverage') {
    console.log(`\n\t  *** ${contractId} ***\n`);
    console.log(`\t  Network: ${currentNetwork}`);
    console.log(`\t  tx: ${contractInstance.deployTransaction.hash}`);
    console.log(`\t  contract address: ${contractInstance.address}`);
    console.log(`\t  deployer address: ${contractInstance.deployTransaction.from}`);
    console.log(`\t  gas price: ${contractInstance.deployTransaction.gasPrice}`);
    console.log(`\t  gas used: ${contractInstance.deployTransaction.gasLimit}`);
    console.log(`\t  ******`);
    console.log();
  }

  await getDb()
    .set(`${contractId}.${currentNetwork}`, {
      address: contractInstance.address,
      deployer: contractInstance.deployTransaction.from,
    })
    .write();
};

export const insertContractAddressInDb = async (id: eContractid, address: tEthereumAddress) =>
  await getDb()
    .set(`${id}.${DRE.network.name}`, {
      address,
    })
    .write();

export const getEthersSigners = async (): Promise<Signer[]> =>
  await Promise.all(await DRE.ethers.getSigners());

export const getFirstSigner = async () => (await getEthersSigners())[0];

export const getEthersSignersAddresses = async (): Promise<tEthereumAddress[]> =>
  await Promise.all((await DRE.ethers.getSigners()).map((signer) => signer.getAddress()));

export const getCurrentBlock = async () => {
  return DRE.ethers.provider.getBlockNumber();
};

export const getCurrentBlockTimestamp = async (blockNumber:number) => {
  return (await DRE.ethers.provider.getBlock(blockNumber)).timestamp;
};
 
export const deployInitializableAdminUpgradeabilityProxy = async (verify?: boolean) => {
  const id = eContractid.InitializableAdminUpgradeabilityProxy;
  const args: string[] = [];
  const instance = await deployContract<InitializableAdminUpgradeabilityProxy>(id, args);
  await instance.deployTransaction.wait();
  if (verify) {
    await verifyContract(id, instance.address, args);
  }
  return instance;
};

export const decodeAbiNumber = (data: string): number =>
  parseInt(utils.defaultAbiCoder.decode(['uint256'], data).toString());

const deployContract = async <ContractType extends Contract>(
  contractName: string,
  args: any[]
): Promise<ContractType> => {
  const contract = (await (
    await DRE.ethers.getContractFactory(contractName)
  ).deploy(...args)) as ContractType;
  await waitForTx(contract.deployTransaction);
  await registerContractInJsonDb(<eContractid>contractName, contract);
  return contract;
};

export const depIterableMappingLibrary = async (verify?: boolean) =>{
  const iterableMappingArtifact = await readArtifact(eContractid.IterableMapping);
  
  const iterableMappingFactory = await DRE.ethers.getContractFactory(
    iterableMappingArtifact.abi,
    iterableMappingArtifact.bytecode
  );
  
  const iterableMapping = await (
    await iterableMappingFactory.connect(await getFirstSigner()).deploy()
  ).deployed();
  return withSaveAndVerify(iterableMapping, eContractid.IterableMapping, [], verify);
};

export const deployBIBToken = async (verify?: boolean) => {
  const id = eContractid.BIBToken;
  const args: string[] = [];
  const instance = await deployContract<BibToken>(id, args);
  await instance.deployTransaction.wait();
  if (verify) {
    await verifyContract(id, instance.address, args);
  }
  return instance;
};

export const deployLibraries = async (
  verify?: boolean
): Promise<TokenDividendTrackerLibraryAddresses> => {
  const iterableMapping = await depIterableMappingLibrary(verify);

  return {
    ['__$773280757a331d91bcd4b03ec520144bfc$__']: iterableMapping.address,
  };
};

export const deployTokenDividendTracker = async (verify?: boolean) => {
const id = eContractid.TokenDividendTracker;

const libraries = await deployLibraries(verify);
const tokenDividendTrackerImpl = await new TokenDividendTracker__factory(libraries, await getFirstSigner()).deploy();
await insertContractAddressInDb(eContractid.TokenDividendTrackerImpl, tokenDividendTrackerImpl.address);
return withSaveAndVerify(tokenDividendTrackerImpl, eContractid.TokenDividendTracker, [], verify);
};

export const deployVestingToken = async (
  beneficiaryAddress: tEthereumAddress,
  startTimestamp: string,
  durationSeconds: string,
  verify?: boolean) => {
  const id = eContractid.VestingToken;
  const args: string[] = [beneficiaryAddress, startTimestamp, durationSeconds];
  const instance = await deployContract<VestingToken>(id, args);
  await instance.deployTransaction.wait();
  if (verify) {
    await verifyContract(id, instance.address, args);
  }
  return instance;
};

const readArtifact = async (id: string) => {
  if (DRE.network.name === eEthereumNetwork.buidlerevm) {
    return buidlerReadArtifact(DRE.config.paths.artifacts, id);
  }
  return (DRE as HardhatRuntimeEnvironment).artifacts.readArtifact(id);
};

export const linkBytecode = (artifact: BuidlerArtifact | Artifact, libraries: any) => {
  let bytecode = artifact.bytecode;

  for (const [fileName, fileReferences] of Object.entries(artifact.linkReferences)) {
    for (const [libName, fixups] of Object.entries(fileReferences)) {
      const addr = libraries[libName];

      if (addr === undefined) {
        continue;
      }

      for (const fixup of fixups) {
        bytecode =
          bytecode.substr(0, 2 + fixup.start * 2) +
          addr.substr(2) +
          bytecode.substr(2 + (fixup.start + fixup.length) * 2);
      }
    }
  }

  return bytecode;
};

export const withSaveAndVerify = async <ContractType extends Contract>(
  instance: ContractType,
  id: string,
  args: (string | string[])[],
  verify?: boolean
): Promise<ContractType> => {
  await waitForTx(instance.deployTransaction);
  await registerContractInJsonDb(id, instance);
  if (verify) {
    await verifyContract(id, instance.address, args);
  }
  return instance;
};

export const getContract = async <ContractType extends Contract>(
  contractName: string,
  address: string
): Promise<ContractType> => (await DRE.ethers.getContractAt(contractName, address)) as ContractType;

export const getInitializableAdminUpgradeabilityProxy = async (address: tEthereumAddress) => {
  return await getContract<InitializableAdminUpgradeabilityProxy>(
    eContractid.InitializableAdminUpgradeabilityProxy,
    address ||
      (
        await getDb()
          .get(`${eContractid.InitializableAdminUpgradeabilityProxy}.${DRE.network.name}`)
          .value()
      ).address
  );
};

export const getBIBToken = async (address?: tEthereumAddress) => {
  return await getContract<BibToken>(
    eContractid.BIBToken,
    address || (await getDb().get(`${eContractid.BIBToken}.${DRE.network.name}`).value()).address
  );
};

export const getBIBTokenImpl = async (address?: tEthereumAddress) => {
  return await getContract<BibToken>(
    eContractid.BIBToken,
    address || (await getDb().get(`${eContractid.BIBTokenImpl}.${DRE.network.name}`).value()).address
  );
};

export const getTokenDividendTracker= async (address?: tEthereumAddress) => {
  return await getContract<TokenDividendTracker>(
    eContractid.TokenDividendTracker,
    address || (await getDb().get(`${eContractid.TokenDividendTracker}.${DRE.network.name}`).value()).address
  );
};

export const getTokenDividendTrackerImpl = async (address?: tEthereumAddress) => {
  return await getContract<TokenDividendTracker>(
    eContractid.TokenDividendTracker,
    address || (await getDb().get(`${eContractid.TokenDividendTrackerImpl}.${DRE.network.name}`).value()).address
  );
};

export const buildPermitParams = (
  chainId: number,
  BIBToken: tEthereumAddress,
  owner: tEthereumAddress,
  spender: tEthereumAddress,
  nonce: number,
  deadline: string,
  value: tStringTokenSmallUnits
) => ({
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    Permit: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
      { name: 'value', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  primaryType: 'Permit' as const,
  domain: {
    name: 'BIB Token',
    version: '1',
    chainId: chainId,
    verifyingContract: BIBToken,
  },
  message: {
    owner,
    spender,
    value,
    nonce,
    deadline,
  },
});

export const buildDelegateByTypeParams = (
  chainId: number,
  BIBToken: tEthereumAddress,
  delegatee: tEthereumAddress,
  type: string,
  nonce: string,
  expiry: string
) => ({
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    DelegateByType: [
      { name: 'delegatee', type: 'address' },
      { name: 'type', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'expiry', type: 'uint256' },
    ],
  },
  primaryType: 'DelegateByType' as const,
  domain: {
    name: 'BIB Token',
    version: '1',
    chainId: chainId,
    verifyingContract: BIBToken,
  },
  message: {
    delegatee,
    type,
    nonce,
    expiry,
  },
});

export const buildDelegateParams = (
  chainId: number,
  BIBToken: tEthereumAddress,
  delegatee: tEthereumAddress,
  nonce: string,
  expiry: string
) => ({
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    Delegate: [
      { name: 'delegatee', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'expiry', type: 'uint256' },
    ],
  },
  primaryType: 'Delegate' as const,
  domain: {
    name: 'BIB Token',
    version: '1',
    chainId: chainId,
    verifyingContract: BIBToken,
  },
  message: {
    delegatee,
    nonce,
    expiry,
  },
});

export const getSignatureFromTypedData = (
  privateKey: string,
  typedData: any // TODO: should be TypedData, from eth-sig-utils, but TS doesn't accept it
): ECDSASignature => {
  const signature = signTypedData_v4(Buffer.from(privateKey.substring(2, 66), 'hex'), {
    data: typedData,
  });
  return fromRpcSig(signature);
};
