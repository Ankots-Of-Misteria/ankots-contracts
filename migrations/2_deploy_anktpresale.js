// migrations/2_deploy_anktpresale.js
const ANNKTPresale = artifacts.require('ANKTPresale');
 
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
 
module.exports = async function (deployer) {
  await deployProxy(ANNKTPresale, ["0xe4C5858dF29EE8Ca7b677469902fAAd17232568D", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"], { deployer, initializer: 'initialize' });
};