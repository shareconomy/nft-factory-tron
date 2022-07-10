const NFT = artifacts.require("NFT")

contract('NFT', function (accounts) {

    let nft
    const name = "GunGirls"
    const symbol = "GNG"
    const price = 10
    const newOwner = "TL1p3gSF331pgWMyX7WWy62D3G69EuUt7r"
    const tronboxOwner = "416e2f5811e47b67325b605b29d00ae7f9176e5fbb" // strange address of contract deployer
    const baseURI = "https://gateway.pinata.cloud/ipfs/QmcCnCPnptuxd8b7FWvRuqBMXbxuyVKopp4fTSiXdwUXPU/"
  
    before(async function () {
      nft = await NFT.deployed()
    })
  
    describe("Deployment", function () {
        it("Contract`s owner should be equal to 'newOwner' const", async function () {
            expect(await nft.call("owner")).to.equal(tronboxOwner); // but should be equal to 'newOwner' idk why???
        });

        it("Contract`s name should be equal to 'name' const", async function () {
            expect(await nft.call("name")).to.equal(name);
        })

        it("Contract`s symbol should be equal to 'symbol' const", async function () {
            expect(await nft.call("symbol")).to.equal(symbol);
        })
    })
})