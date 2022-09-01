import chai, { expect } from 'chai';
import BigNumber from 'bignumber.js';
import { fail } from 'assert';
import { solidity } from 'ethereum-waffle';
import { 
  TestEnv, 
  makeSuite,
  SignerWithAddress
} from './helpers/make-suite';
import { ProtocolErrors, eContractid } from '../helpers/types';
import { 
  DRE, 
  advanceBlock,
   timeLatest, 
   waitForTx ,
   increaseTime,
   mineOneBlock
  } from '../helpers/misc-utils';
import {
  buildDelegateParams,
  buildDelegateByTypeParams,
  deploySoccerStarNft,
  deployStakedSoccerStarNftV2,
  getContract,
  getSoccerStarNft,
  getCurrentBlock,
  getSignatureFromTypedData,
  getCurrentBlockTimestamp,
} from '../helpers/contracts-helpers';

import { MAX_UINT_AMOUNT, ZERO_ADDRESS } from '../helpers/constants';
import { parseEther } from 'ethers/lib/utils';
import {
  SoccerStarNft,
  StakedSoccerStarNftV2
} from "../types";
import { ethers } from 'hardhat';
import exp from 'constants';
chai.use(solidity);



makeSuite('Staked', (testEnv: TestEnv) => {
  const {} = ProtocolErrors;
  const MAX_APPROVE = ethers.utils.parseEther('100000000000');

  const initialBlance = ethers.utils.parseEther('100');
  const valutBalance = ethers.utils.parseEther('10000');
  let tx;
  let soccerStarNft:SoccerStarNft;
  let stakedSoccerStarNftV2:StakedSoccerStarNftV2;
  let userOne:SignerWithAddress;
  let userTwo:SignerWithAddress;
  let vault:SignerWithAddress;
  const emissionPerSecond = "100";

  before('Install soccer nft', async ()=>{
    [userOne, userTwo, vault]  = testEnv.users;

    const {deployer, mockBib, mockBusd, mockBibOracle} = testEnv;

    await mockBib.transfer(userOne.address, initialBlance);
    tx = await mockBib.balanceOf(userOne.address);
    expect(tx).to.equal(initialBlance);

    await mockBib.transfer(userTwo.address, initialBlance);
    tx = await mockBib.balanceOf(userTwo.address);
    expect(tx).to.equal(initialBlance);

    await mockBib.transfer(vault.address, valutBalance);
    tx = await mockBib.balanceOf(vault.address);
    expect(tx).to.equal(valutBalance);
    
    soccerStarNft = await deploySoccerStarNft(
    ["10000", mockBib.address, mockBusd.address, deployer.address, mockBibOracle.address]);
    tx = await soccerStarNft.ownerMint(1);
    await soccerStarNft.updateProperty([1], [{name:"aa", country:"bb", position:"m",starLevel:1, gradient:1}]);

    stakedSoccerStarNftV2 = await deployStakedSoccerStarNftV2();
    await stakedSoccerStarNftV2.initialize(
    soccerStarNft.address, mockBib.address, vault.address, 10000);

    tx = await stakedSoccerStarNftV2.STAKED_TOKEN();
    expect(tx).to.be.equal(soccerStarNft.address);

    tx = await stakedSoccerStarNftV2.REWARD_TOKEN();
    expect(tx).to.be.equal(mockBib.address);

    tx = await stakedSoccerStarNftV2.REWARDS_VAULT();
    expect(tx).to.be.equal(vault.address);
      
    tx = await stakedSoccerStarNftV2.DISTRIBUTION_END();
    const distrubutionEnd = 10000 + await getCurrentBlockTimestamp(await getCurrentBlock());
    expect(tx).to.be.equal(distrubutionEnd);

    // approve vault transfer
    await mockBib.connect(vault.signer).approve(stakedSoccerStarNftV2.address, MAX_APPROVE);
    expect(await mockBib.allowance(vault.address, stakedSoccerStarNftV2.address))
    .to.be.equal(MAX_APPROVE);

    const assetsConfigInput: {
      emissionPerSecond: string;
      totalPower: string;
      underlyingAsset: string;
    } = {
      emissionPerSecond: emissionPerSecond,
      totalPower: "0",
      underlyingAsset: stakedSoccerStarNftV2.address
    };
    await stakedSoccerStarNftV2.configureAssets([assetsConfigInput]);
    tx = await stakedSoccerStarNftV2.assets(stakedSoccerStarNftV2.address);
   });

  it('Test staked && withdraw', async () => {
    const {deployer, mockBib} = testEnv;
    const tokenId = 1;

    // aprove
    tx = await soccerStarNft.setApprovalForAll(stakedSoccerStarNftV2.address, true);
    tx = await soccerStarNft.isApprovedForAll(deployer.address, stakedSoccerStarNftV2.address);
    expect(tx).to.be.equal(true);

    // check stake
    expect(await soccerStarNft.ownerOf(tokenId)).to.equal(deployer.address);
    await stakedSoccerStarNftV2.stake(tokenId);
    expect(await soccerStarNft.ownerOf(tokenId)).to.equal(stakedSoccerStarNftV2.address);

    expect(await stakedSoccerStarNftV2.isStaked(tokenId)).to.equal(true);

    tx = await stakedSoccerStarNftV2.getUserStakedInfoByPage(deployer.address, 0, 10);
    expect(tx.length).equal(1);
    expect(tx[0].owner).equal(deployer.address);
    expect(tx[0].tokenId).equal(tokenId);

    tx =  stakedSoccerStarNftV2.withdraw(tokenId);
    await expect(tx).to.be.revertedWith("");

    // check redeem
    tx = await stakedSoccerStarNftV2.redeem(tokenId);
    expect(await stakedSoccerStarNftV2.isStaked(tokenId)).to.equal(false);
    expect(await stakedSoccerStarNftV2.isUnfreezing(tokenId)).to.equal(true);

    tx = await stakedSoccerStarNftV2.tokenStakedInfoTb(tokenId);

    await increaseTime(70);
    await mineOneBlock()

    expect(await soccerStarNft.ownerOf(tokenId)).to.eq(stakedSoccerStarNftV2.address);
    tx = await stakedSoccerStarNftV2.tokenStakedInfoTb(tokenId);
    expect(tx.owner).to.equal(deployer.address);

    const unclaimed = await stakedSoccerStarNftV2.getUnClaimedRewards(deployer.address);
    const balanceBefore = await mockBib.balanceOf(deployer.address);

    expect(await stakedSoccerStarNftV2.isWithdrawAble(tokenId)).to.equal(true);
    tx = await stakedSoccerStarNftV2.withdraw(tokenId);

    // check owner
    expect(await soccerStarNft.ownerOf(tokenId)).to.eq(deployer.address);
    // check contract info
    tx = await stakedSoccerStarNftV2.getUserStakedInfoByPage(deployer.address, 0, 10);
    expect(tx.length).equal(0);
    tx = await stakedSoccerStarNftV2.tokenStakedInfoTb(tokenId);
    expect(tx.owner).to.equal(ZERO_ADDRESS);
  });

  const checkUnclaimed = async(user:SignerWithAddress,tokenId:number, expectReward:BigNumber)=>{
    const {mockBib} = testEnv;
    let unclaimed = await stakedSoccerStarNftV2.getUnClaimedRewards(user.address);
    expect(expectReward.isEqualTo(unclaimed.toNumber())).to.be.true;

    unclaimed = await stakedSoccerStarNftV2.getUnClaimedRewardsByToken(tokenId);
    expect(expectReward.isEqualTo(unclaimed.toNumber())).to.be.true;

    let rewards = await stakedSoccerStarNftV2.getUnClaimedRewardsByTokens([tokenId]);
    unclaimed = rewards.reduce((pre, cur)=>{
      if(pre){
        return pre + cur;
      } else {
        return cur;
      }
    }, null);

    expect(expectReward.isEqualTo(unclaimed.toNumber())).to.be.true;
  };

  it("Test rewards", async () => {
    const {deployer, mockBib} = testEnv;
    const tokenId = 1;

    // aprove
    await soccerStarNft.transferFrom(deployer.address, userOne.address, tokenId);
    expect(await soccerStarNft.ownerOf(tokenId)).to.equal(userOne.address);

    // check stake
    tx = await soccerStarNft.connect(userOne.signer).
    setApprovalForAll(stakedSoccerStarNftV2.address, true);
    tx = await soccerStarNft.isApprovedForAll(userOne.address, stakedSoccerStarNftV2.address);
    expect(tx).to.be.equal(true);

    await stakedSoccerStarNftV2.connect(userOne.signer).stake(tokenId);
    const timeStake = await timeLatest();

    await increaseTime(70);
    await mineOneBlock();

    const timeDelt = (await timeLatest()).minus(timeStake);
    let expectReward =  new BigNumber(emissionPerSecond).multipliedBy(timeDelt);
    await checkUnclaimed(userOne, tokenId, expectReward);


    // claimed
    let beforeClaimed = await mockBib.balanceOf(userOne.address);
    tx = await stakedSoccerStarNftV2.connect(userOne.signer).claimRewards();
    let claimed = (await mockBib.balanceOf(userOne.address)).sub(beforeClaimed);
    console.log(claimed);

    expectReward = new BigNumber("0");
    await checkUnclaimed(userOne, tokenId, expectReward);
  
    // // redeem back
    tx = await stakedSoccerStarNftV2.connect(userOne.signer).redeem(tokenId);
    await increaseTime(70);
    await mineOneBlock();

    // the caculation is working but not stake so bellow shall be failed
    beforeClaimed = await mockBib.balanceOf(userOne.address);
    tx = await stakedSoccerStarNftV2.connect(userOne.signer).claimRewards();
    claimed = (await mockBib.balanceOf(userOne.address)).sub(beforeClaimed);
    expect(claimed.eq(expectReward.toNumber())).to.be.true;

  });
});
