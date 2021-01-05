# GLM Stake Pool

***
## 【Introduction of GLM Stake Pool】
- This is a smart contract in order to provide the opportunity of yield farming for Golem's GLM token holders. (By staking uniswap-LP tokens that is a pair between GLM and ETH into the stake pool)

&nbsp;

***

## 【Workflow】

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

### ② Compile & migrate contracts (on Rinkeby testnet)
```
$ npm run migrate:local
```

<br>

### ③ Test (Mainnet-fork approach with Ganache-CLI)
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

## 【References】
- Golem
  - Prize：https://gitcoin.co/issue/golemfactory/hackathons/4/100024409

<br>

- Test (Mainnet-fork approach with Ganache-CLI and Infura)  
https://medium.com/@samajammin/how-to-interact-with-ethereums-mainnet-in-a-development-environment-with-ganache-3d8649df0876  
(Current block number @ mainnet: https://etherscan.io/blocks )
