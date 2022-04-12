// test/ANKTPresale.proxy.test.js
// Load dependencies
const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
 
// Load compiled artifacts
const ANKTPresale = artifacts.require('ANKTPresale');
 
// Start test block
contract('ANKTPresale (proxy)', function () {
  beforeEach(async function () {
    // Deploy a new ANKTPresale contract for each test
    this.anktpresale = await deployProxy(ANKTPresale, ["0xe4C5858dF29EE8Ca7b677469902fAAd17232568D", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"], {initializer: 'initialize'});
  });
 
  // Test case
  it('retrieve returns a value previously initialized', async function () {
   expect(await this.anktpresale.usdtAddress()).to.equal("0xc2132D05D31c914a87C6611C10748AEb04B58e8F");
  });
});