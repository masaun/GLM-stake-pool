# GLM Stake Pool

***
## 【Introduction of GLM Stake Pool】
- This is a smart contract in order to provide the opportunity of yield farming for Golem's GLM token holders. (By staking uniswap-LP tokens that is a pair between GLM and ETH into the stake pool)

&nbsp;

***

## 【Workflow】
- ① Create UniswapV2-Pool between GLM token and ETH. (Add Liquidity)
- ② Create UNI-V2 LP tokens (GLM-ETH).
- ③ Stake UNI-V2 LP tokens (GLM-ETH) into the GLM stake pool contract.
- ④ Smart contract (the GLM stake pool contract) automatically generate rewards every week.
  - The `Golem Governance Token (GGC)` is generated as rewards. 
  - Current formula of generating rewards is that:
    - 10% of staked UNI-V2 LP tokens (GLM-ETH) amount in a week is generated each week. 
    - Staker can receive rewards ( `Golem Governance Token` ) depends on their `share of pool` when they claim rewards.
- ⑤ Claim rewards and distributes rewards into claimed-staker.
  (or, Un-Stake UNI-V2 LP tokens. At that time, claiming rewards will be executed at the same time)

&nbsp;

***

## 【Technical Stack】
- Solidity (Solc): v0.5.16
- Truffle: v5.1.60
- web3.js: v1.2.9
- Node.js: v11.15.0
- Libraries
  - @openzeppelin/contracts: v2.5.1
    etc,...
&nbsp;

***

## 【Setup】
### ① Install modules
```
$ npm install
```

<br>

### ② Add `.env` to the root directory. 
- Please reference `.env.example` to create `.env` 


<br>

### ③ Compile & migrate contracts (on Rinkeby testnet)
```
$ npm run migrate:local
```

<br>

### ④ Test (Mainnet-fork approach with Ganache-CLI)
```
$ ganache-cli --fork https://mainnet.infura.io/v3/{YOUR INFURA KEY}
```
(Ref：https://medium.com/@samajammin/how-to-interact-with-ethereums-mainnet-in-a-development-environment-with-ganache-3d8649df0876 ）  
(Current block number @ mainnet: https://etherscan.io/blocks )

Then,  

- All of tests
```
$ npm run test
```

- Only test of the Stake Pool contract
```
$ npm run test:stake
```

&nbsp;

***

## 【Remaining tasks and next steps】
- Replace GLMMockToken contract (GLMMockToken.sol) with official GLM token contract (NewGolemNetworkToken.sol).
- Additional implementation of GLM stake pool between GLM-ERC20. (Currently, this is in progress)
- Additional implementation of the Golem Governance Token (GGC) and governance structures (e.g. Community voting function by GLM token holders)
- Implement the front-end (UI).


&nbsp;

***

## 【References】
- Golem  
  - GLM contract  
    https://github.com/golemfactory/gnt2/tree/master/gnt2-contracts/src/contracts/GNT2  

  - ERC20 token migration（GNT -> GLM)  
    https://blog.golemproject.net/glmupdate/  
  
  - GLM Migration Tracker  
    https://glm.golem.network/  
  
  - Golem Hackathon resources  
    https://github.com/golemfactory/hackathons  
  
  - Awesome Golem  
    https://github.com/golemfactory/awesome-golem  
  
  - Doc  
    https://handbook.golem.network/introduction/golem-overview#golem-architecture  
  
  - Golem Network Hackathon  
    https://gitcoin.co/issue/golemfactory/hackathons/4/100024409  

<br>

- Test (Mainnet-fork approach with Ganache-CLI and Infura)  
https://medium.com/@samajammin/how-to-interact-with-ethereums-mainnet-in-a-development-environment-with-ganache-3d8649df0876  
(Current block number @ mainnet: https://etherscan.io/blocks )  
