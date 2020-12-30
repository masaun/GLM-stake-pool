const GLMPoolToken = artifacts.require("GLMPoolToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(GLMPoolToken);
};
