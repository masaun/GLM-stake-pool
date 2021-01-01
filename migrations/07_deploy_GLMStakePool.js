const GLMStakePool = artifacts.require("GLMStakePool");
const GLMMockToken = artifacts.require("GLMMockToken");
const GolemFarmingLPToken = artifacts.require("GolemFarmingLPToken");
const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");

//@dev - Import from exported file
var contractAddressList = require('./addressesList/contractAddress/contractAddress.js');
var tokenAddressList = require('./addressesList/tokenAddress/tokenAddress.js');

const _GLMToken = GLMMockToken.address;
const _golemFarmingLPToken = GolemFarmingLPToken.address;
const _golemGovernanceToken = GolemGovernanceToken.address;
let _uniswapV2Factory;
let _uniswapV2Router02;


module.exports = async function(deployer, network, accounts) {
    if (network == 'test' || network == 'local') {  /// [Note]: Mainnet-fork approach with Truffle/Ganache-CLI/Infura 
        _uniswapV2Factory = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Factory"];
        _uniswapV2Router02 = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Router02"];
    } else if (network == 'ropsten') {
        _uniswapV2Factory = contractAddressList["Ropsten"]["Uniswap"]["UniswapV2Factory"];
        _uniswapV2Router02 = contractAddressList["Ropsten"]["Uniswap"]["UniswapV2Router02"];
    }

    await deployer.deploy(GLMStakePool, 
                          _GLMToken,
                          _golemFarmingLPToken, 
                          _golemGovernanceToken,
                          _uniswapV2Factory, 
                          _uniswapV2Router02);
};
