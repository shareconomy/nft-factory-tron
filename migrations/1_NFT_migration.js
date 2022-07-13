// var NFT= artifacts.require("NFT");

// const name = "GunGirls"
// const symbol = "GNG"
// const price = 10
// const newOwner = "TEBSoUMRKszV8pVqj1KDzCzrAoUi7qeAyv" // is accounts[9] for development
// const amount = 5
// // const newOwner = "TL1p3gSF331pgWMyX7WWy62D3G69EuUt7r" // for shasta network
// const baseURI = "https://gateway.pinata.cloud/ipfs/QmcCnCPnptuxd8b7FWvRuqBMXbxuyVKopp4fTSiXdwUXPU/"

// module.exports = function(deployer) {
//   deployer.deploy(NFT, name, symbol, baseURI, newOwner, price, amount);
// };

var NFTFactory= artifacts.require("NFTFactory");

module.exports = function(deployer) {
  deployer.deploy(NFTFactory);
};
