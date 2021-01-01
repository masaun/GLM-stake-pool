const UniswapV2Helper = artifacts.require("UniswapV2Helper");

//@dev - Import from exported file
var contractAddressList = require('./addressesList/contractAddress/contractAddress.js');
var tokenAddressList = require('./addressesList/tokenAddress/tokenAddress.js');

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

    await deployer.deploy(UniswapV2Helper, 
                          _uniswapV2Factory, 
                          _uniswapV2Router02);
};
