// test/ANKTPresale.test.js
// Load dependencies
const { expect } = require('chai');
 
// Load compiled artifacts
const ANKTPresale = artifacts.require('ANKTPresale');
 
// Start test block
contract('ANKTPresale', function () {
  beforeEach(async function () {
    // Deploy a new Box contract for each test
    this.anktpresale = await ANKTPresale.new();
  });
 
  // Test case
  it('get a value previously stored', async function () {
    await this.anktpresale.initialize("0xe4C5858dF29EE8Ca7b677469902fAAd17232568D", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F");
    expect(await this.anktpresale.safeAddress()).to.equal("0xe4C5858dF29EE8Ca7b677469902fAAd17232568D");
  });
});