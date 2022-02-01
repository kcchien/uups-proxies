const { ethers, upgrades } = require("hardhat");

// Fill in the BOX_ADDRESS variable below with the address of the Box contrac
const BOX_ADDRESS = "0x9b5B064626074c807c29EFcE716d49600317688D";

async function main() {
  const BoxV2 = await ethers.getContractFactory("BoxV2");
  const box = await upgrades.upgradeProxy(BOX_ADDRESS, BoxV2);
  console.log("Box upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
