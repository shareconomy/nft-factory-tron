const { expect } = require("chai");
const { ethers } = require("ethers");
const { abi, bytecode } = require ("../build/contracts/NFT.json");

describe("NFT contract", function () {
    let NFT;
    let owner;
    let acc1;
    let acc2;

    const name = "GunGirls"
    const symbol = "GNG"
    const price = 10
    const newOwner = "TL1p3gSF331pgWMyX7WWy62D3G69EuUt7r"
    const baseURI = "https://gateway.pinata.cloud/ipfs/QmcCnCPnptuxd8b7FWvRuqBMXbxuyVKopp4fTSiXdwUXPU/"

    beforeEach(async function () {
        [owner, acc1, acc2, acc3, acc4] = await ethers.Wallet()
        NFT = await ethers.ContractFactory(abi, bytecode, owner)
        NFTInstace = await NFT.deploy(
            name,
            symbol,
            baseURI,
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