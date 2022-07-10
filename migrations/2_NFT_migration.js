var NFT= artifacts.require("NFT");

const name = "GunGirls"
const symbol = "GNG"
const price = 10
const newOwner = "TL1p3gSF331pgWMyX7WWy62D3G69EuUt7r"
const baseURI = "https://gateway.pinata.cloud/ipfs/QmcCnCPnptuxd8b7FWvRuqBMXbxuyVKopp4fTSiXdwUXPU/"

module.exports = function(deployer) {
  deployer.deploy(NFT, name, symbol, baseURI, newOwner, price);
};
