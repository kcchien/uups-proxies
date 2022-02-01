const { ethers, upgrades } = require("hardhat");

let contract_proxy_address;

describe("Test Box v1 deploy", function () {
  it("Deploying Box v1", async function () {
    const Box = await ethers.getContractFactory("Box");
    const box = await upgrades.deployProxy(Box, { kind: "uups" });
    contract_proxy_address = box.address;
  });

  it("Upgrading to v1", async function () {
    const BoxV2 = await ethers.getContractFactory("BoxV2");
    await upgrades.upgradeProxy(contract_proxy_address, BoxV2);
  });
});
