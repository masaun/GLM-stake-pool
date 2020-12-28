const GLMMockToken = artifacts.require("GLMMockToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(GLMMockToken);
};
