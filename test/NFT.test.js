const { solidity, revertedWith } = require('ethereum-waffle')
const chai = require('chai');
chai.use(solidity, revertedWith);

const NFT = artifacts.require("NFT")

const TronWeb = require('tronweb')

const tronWeb = new TronWeb(
    "http://127.0.0.1:9090",
    "http://127.0.0.1:9090",
    "http://127.0.0.1:9090",
    'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
)

contract('NFT', function (accounts) {
    let nft
    const name = "GunGirls"
    const symbol = "GNG"
    const price = 10
    const newOwner = "TEBSoUMRKszV8pVqj1KDzCzrAoUi7qeAyv" // is accounts[9]
    const baseURI = "https://gateway.pinata.cloud/ipfs/QmcCnCPnptuxd8b7FWvRuqBMXbxuyVKopp4fTSiXdwUXPU/"
    const initialAmount = 5
  
    beforeEach(async function () {
      nft = await NFT.deployed()
    })
  
    describe("Deployment", function () {
        it("Contract`s owner should be equal to 'newOwner' const", async function () {
            expect(await nft.call("owner")).to.equal(tronWeb.address.toHex(newOwner)); // but should be equal to 'newOwner' idk why???
        });

        it("Contract`s name should be equal to 'name' const", async function () {
            expect(await nft.call("name")).to.equal(name);
        })

        it("Contract`s symbol should be equal to 'symbol' const", async function () {
            expect(await nft.call("symbol")).to.equal(symbol);
        })

        it("Contract`s price should be equal to 'price' const", async function () {
            expect(parseInt(await nft.call("price"))).to.equal(price); // but should be equal to 'newOwner' idk why???
        });

        it("Contract`s baseURI should be equal to 'baseURI' const", async function () {
            expect(await nft.call("baseURI")).to.equal(baseURI);
        })

        it("Contract`s deployer should has DEFAULT_ADMIN_ROLE", async function () {
            expect(await nft.call("hasRole", await nft.call("DEFAULT_ADMIN_ROLE"), accounts[0])).to.equal(true);
        })

        it("Contract`s newOwner should has MINTER_ROLE", async function () {
            expect(await nft.call("hasRole", await nft.call("MINTER_ROLE"), accounts[9])).to.equal(true);
        })

        it("should verify that the contract has been deployed by accounts[0]", async function () {
            assert.equal(await nft.call("owner"), tronWeb.address.toHex(newOwner))
        });
    })

    describe("mint function", function () {
        it("Contract`s owner could use 'mint' function and create new tokens", async function () {
            nft = await NFT.deployed()

            const minter = accounts[9]
            const amount = 5
            console.log(await nft.call("hasRole", await nft.call("MINTER_ROLE"), minter));

            try {
                await nft.mint([minter, amount], {from: minter});
            } catch(e) {
                console.log(e)
            }
            console.log(tronWeb.toDecimal(await nft.totalSupply()))
            expect(tronWeb.toDecimal(await nft.balanceOf(minter))).to.equal(amount);
        });

        it("Only accounts with 'MINTER_ROLE' could mint new tokens", async function () {
            await nft.mint(accounts[0], 5, {from: accounts[0], to: accounts[9], value: 10000})
            expect(parseInt(await nft.balanceOf(accounts[0]))).to.equal(0);
        })
    })

    describe("mintForTRX function", function () {
        it("Anyone could use 'mintForTRX' function and create new tokens for TRX", async function () {
            await nft.mintForTRX(accounts[1], {amount: 50})
            console.log(tronWeb.toDecimal(await nft.totalSupply()))
            expect(tronWeb.toDecimal(await nft.balanceOf(accounts[0]))).to.equal(5);
        });
    })

    describe("changePrice function", function () {
        it("ADMIN can change 'price' value", async function () {
            await nft.changePrice(20, {from: accounts[9]})
            console.log(tronWeb.toDecimal(await nft.call("price")))
            expect(tronWeb.toDecimal(await nft.call("price"))).to.equal(20);
        });

        it("Account[1] dont have ADMIN_ROLE", async function () {
            expect(await nft.call("hasRole", await nft.call("ADMIN_ROLE"), accounts[1])).to.equal(false);
        })

        it("Account without 'ADMIN_ROLE' can not change 'price' value", async function () {
            await nft.changePrice(20, {from: accounts[1]})
            console.log(tronWeb.toDecimal(await nft.call("price")))
            expect(tronWeb.toDecimal(await nft.call("price"))).to.equal(10);
        });
    })

    describe("setBaseURI function", function () {
        it("ADMIN can change 'baseURI' string value", async function () {
            const newURI = "My new URI"
            await nft.setBaseURI(newURI, {from: accounts[9]})
            expect(await nft.call("baseURI")).to.equal(newURI);
        });

        it("Account[0] dont have ADMIN_ROLE", async function () {
            expect(await nft.call("hasRole", await nft.call("ADMIN_ROLE"), accounts[0])).to.equal(false);
        })

        it("Account without 'ADMIN_ROLE' can not change 'baseURI' string value", async function () {
            const newURI = "My new URI"
            await nft.setBaseURI(newURI, {from: accounts[1]})
            expect(await nft.call("baseURI")).to.equal(baseURI);
        });
    })
})
