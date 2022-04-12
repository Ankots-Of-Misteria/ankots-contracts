// migrations/3_transfer_ownership_proxyadmin.js
const { admin } = require('@openzeppelin/truffle-upgrades');
 
module.exports = async function (deployer, network) {
  // Use address of your Gnosis Safe
  const gnosisSafe = '0xe4C5858dF29EE8Ca7b677469902fAAd17232568D';
 
  // Don't change ProxyAdmin ownership for our test network
  if (network !== 'test') {
    // The owner of the ProxyAdmin can upgrade our contracts
    await admin.transferProxyAdminOwnership(gnosisSafe);
  }
};