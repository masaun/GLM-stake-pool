const GLMStakePool = artifacts.require("GLMStakePool");
const GLMMockToken = artifacts.require("GLMMockToken");
const GLMPoolToken = artifacts.require("GLMPoolToken");
const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");

//@dev - Import from exported file
var contractAddressList = require('./addressesList/contractAddress/contractAddress.js');
var tokenAddressList = require('./addressesList/tokenAddress/tokenAddress.js');

const _GLMToken = GLMMockToken.address;
const _glmPoolToken = GLMPoolToken.address;
const _golemGovernanceToken = GolemGovernanceToken.address;
const _uniswapV2Factory = contractAddressList["Ropsten"]["Uniswap"]["UniswapV2Factory"];
const _uniswapV2Router02 = contractAddressList["Ropsten"]["Uniswap"]["UniswapV2Router02"];


module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(GLMStakePool, 
                          _GLMToken,
                          _glmPoolToken, 
                          _golemGovernanceToken, 
                          _uniswapV2Factory, 
                          _uniswapV2Router02);
};
