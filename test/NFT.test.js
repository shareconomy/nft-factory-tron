const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT contract", function () {
    let NFT;
    let owner;
    let acc1;
    let acc2;

    const name = "GunGirls"
    const symbol = "GNG"
    const price = 10
    const newOwner = "TL1p3gSF331pgWMyX7WWy62D3G69EuUt7r"

    beforeEach(async function () {
        NFT = await ethers.getContractFactory("NFT");
        [owner, acc1, acc2, acc3, acc4] = await ethers.getSigners();
        NFTInstace = await NFT.deploy(
            name,
            symbol,
            newOwner,
            price
        );
        await NFTInstace.deployed()
    });

    describe("Deployment", function () {
        it("Contract`s owner should be equal to 'newOwner' const", async function () {
            expect(await NFTInstace.owner()).to.equal(newOwner);
        });

        it("Contract`s name should be equal to 'name' const", async function () {
            expect(await NFTInstace.name()).to.equal(name);
        })

        it("Contract`s symbol should be equal to 'symbol' const", async function () {
            expect(await NFTInstace.symbol()).to.equal(symbol);
        })
    })
})