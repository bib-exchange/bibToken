## Introduction

## Set up environment
1. Pin the npm version for compilling

```bash
npm -g -i npm@8.5.5
```
## Configure contracts
Locate the `constants.ts`
1. Setup `admin`
    Find `getBIBAdminPerNetwork` section and fill address under the specific network
2. Setup `BUSD`
    Find `getBUSDTokenPerNetwork` section and fill address under the specific network
3. Setup `PancakeSwapRouter`
    Find `getSwapRoterPerNetwork` section and fill address under the specific network
3. Setup `Ecosystem distribution part`
    Find `getEosystemVaultPartPerNetwork` section and fill address under the specific network
4. Setup `Team distribution part`
    Find `getProjectTeamPartPerNetwork` section and fill address under the specific network
5. Setup `Private sale distribution part`
    Find `getPrivateSellPartPerNetwork` section and fill address under the specific network
6. Setup `Public sale distribution part`
    Find `getPulicSellPartPerNetwork` section and fill address under the specific network
7. Setup `Liquidity distribution part`
    Find `getLiquidtyPartPerNetwork` section and fill address under the specific network
8. Setup `Marketting incentive distribution part`
    Find `getMarkettingPartPerNetwork` section and fill address under the specific network
9. Setup `Incentive distribution part`
    Find `getIncentivePartPerNetwork` section and fill address under the specific network
10. Setup `Coperation distribution part`
    Find `getCoperationPartPerNetwork` section and fill address under the specific network
## Deploy and debug
1. Clean internal output

```bash
npm ci:clean
```

2. Compile source code

```bash
npm run compile
```

3. To run test (Skip over if not needed)

```bash
npm run test
```

4. Deploy to network
- Deploy to test network
```bash
npm run bsc-test:deployment
```
- Deploy to main network
```bash
npm run bsc:deployment
```

5. Open console
- for test net
```bash
npm run --network bsc-test console
```
- for main net
6. To open console on mainnet
```bash
npm run --network bsc console
```

7. Add address to whitelist
- for test-net
```bash
npm run bsc-test:run-exclude
```
- for main-net
```bash
npm run bsc:run-exclude
```
