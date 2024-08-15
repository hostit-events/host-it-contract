/* global ethers */
/* eslint prefer-const: "off" */

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { getSelectors, FacetCutAction } = require('../../scripts/libraries/diamond.js')

module.exports = buildModule("deploy", (m) => {
  const contractOwner = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80").address;
  const zeroAddress = "0x0000000000000000000000000000000000000000";

  const diamondCutFacet = m.contract("DiamondCutFacet");

  // initFacetCut and DiamondArgs
  const initCut = []

  initCut.push({
    facetAddress: diamondCutFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondCutFacet)
  })

  const DiamondArgs = { address: zeroAddress, bytes: "" }

  const diamond = m.contract("Diamond", [contractOwner, initCut, DiamondArgs]);

  // m.call(diamond, "launch", []);

  return { diamond };
});

async function deployDiamond() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // initFacetCut and DiamondArgs
  const initCut = []

  initCut.push({
    facetAddress: diamondCutFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondCutFacet)
  })

  const DiamondArgs = { address: 0, bytes: "" }

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner, initCut, DiamondArgs)
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
