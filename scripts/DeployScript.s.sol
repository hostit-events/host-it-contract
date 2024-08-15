// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {IDiamondInit} from "../contracts/interfaces/IDiamondInit.sol";
import {DiamondInit} from "../contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {AccessControlFacet} from "../contracts/facets/AccessControlFacet.sol";
import {W3LC3__ERC721A} from "../contracts/facets/W3LC3__ERC721A.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "../contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../contracts/interfaces/IDiamondLoupe.sol";
import {IAccessControl} from "../contracts/interfaces/IAccessControl.sol";
import {IW3LC3__ERC721A} from "../contracts/interfaces/IW3LC3__ERC721A.sol";
import {IERC165} from "../contracts/interfaces/IERC165.sol";
import {IERC173} from "../contracts/interfaces/IERC173.sol";

import {Diamond, DiamondArgs} from "../contracts/Diamond.sol";

contract DeployScript is Script {
    // Store the FacetCut struct for each facet that is being deployed.
    // NOTE: using storage array to easily "push" new FacetCut as we
    // process the facets.
    FacetCut[] private _facetCuts;

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // Start by deploying the DiamonInit contract.
        DiamondInit diamondInit = new DiamondInit();
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        // OwnershipFacet ownershipFacet = new OwnershipFacet();
        AccessControlFacet accessControlFacet = new AccessControlFacet();
        W3LC3__ERC721A w3lc3 = new W3LC3__ERC721A();

        FacetCut[] memory initCut = new FacetCut[](1);

        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = IDiamondCut.diamondCut.selector;

        initCut[0] = FacetCut({facetAddress: address(diamondCutFacet), action: FacetCutAction.Add, functionSelectors: cutSelectors});

        // Build the DiamondArgs.
        DiamondArgs memory initDiamondArgs = DiamondArgs({
            init: address(diamondInit),
            // NOTE: "interfaceId" can be used since "init" is the only function in IDiamondInit.
            initCalldata: abi.encode(type(IDiamondInit).interfaceId)
        });

        // Deploy the diamond.
        // console.log("Message sender", msg.sender);
        Diamond diamond = new Diamond(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, initCut, initDiamondArgs);
        console.log("Diamond address: ", address(diamond));

        // Create the `cuts` array. (Already cut DiamondCut during diamond deployment)
        FacetCut[] memory cuts = new FacetCut[](3);

        // Get function selectors for facets for `cuts` array.
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;

        // bytes4[] memory ownershipSelectors = new bytes4[](2);
        // ownershipSelectors[0] = IERC173.owner.selector;
        // ownershipSelectors[1] = IERC173.transferOwnership.selector;

        bytes4[] memory accessControlSelectors = new bytes4[](6);
        accessControlSelectors[0] = IAccessControl.hasRole.selector;
        accessControlSelectors[1] = IAccessControl.getRoleAdmin.selector;
        accessControlSelectors[2] = IAccessControl.grantRole.selector;
        accessControlSelectors[3] = IAccessControl.revokeRole.selector;
        accessControlSelectors[4] = IAccessControl.renounceRole.selector;
        accessControlSelectors[5] = AccessControlFacet.setRoleAdmin.selector;

        bytes4[] memory w3lc3Selectors = new bytes4[](21);
        w3lc3Selectors[0] = IW3LC3__ERC721A.w3lc3__totalSupply.selector;
        w3lc3Selectors[1] = IW3LC3__ERC721A.w3lc3__balanceOf.selector;
        w3lc3Selectors[2] = IW3LC3__ERC721A.w3lc3__ownerOf.selector;
        w3lc3Selectors[3] = 0xf2e3b036; //w3lc3__safeTransferFrom
        w3lc3Selectors[4] = 0x3a8acfd7; //w3lc3__safeTransferFrom
        w3lc3Selectors[5] = IW3LC3__ERC721A.w3lc3__transferFrom.selector;
        w3lc3Selectors[6] = IW3LC3__ERC721A.w3lc3__approve.selector;
        w3lc3Selectors[7] = IW3LC3__ERC721A.w3lc3__setApprovalForAll.selector;
        w3lc3Selectors[8] = IW3LC3__ERC721A.w3lc3__getApproved.selector;
        w3lc3Selectors[9] = IW3LC3__ERC721A.w3lc3__isApprovedForAll.selector;
        w3lc3Selectors[10] = IW3LC3__ERC721A.w3lc3__name.selector;
        w3lc3Selectors[11] = IW3LC3__ERC721A.w3lc3__symbol.selector;
        w3lc3Selectors[12] = IW3LC3__ERC721A.w3lc3__tokenURI.selector;
        w3lc3Selectors[13] = W3LC3__ERC721A.w3lc3__setBaseURI.selector;
        w3lc3Selectors[14] = W3LC3__ERC721A.w3lc3__mintSingle.selector;
        w3lc3Selectors[15] = W3LC3__ERC721A.w3lc3__mintMultipe.selector;
        w3lc3Selectors[16] = W3LC3__ERC721A.w3lc3__batchMint.selector;
        w3lc3Selectors[17] = 0xe8f76096; //w3lc3__batchTransfer
        w3lc3Selectors[18] = 0x25897632; //w3lc3__batchTransfer
        w3lc3Selectors[19] = W3LC3__ERC721A.w3lc3__setBaseURI.selector;
        w3lc3Selectors[20] = W3LC3__ERC721A.w3lc3__verifyAttendance.selector;

        // Populate the `cuts` array with the needed data.
        cuts[0] = FacetCut({facetAddress: address(diamondLoupeFacet), action: FacetCutAction.Add, functionSelectors: loupeSelectors});

        // cuts[1] = FacetCut({facetAddress: address(ownershipFacet), action: FacetCutAction.Add, functionSelectors: ownershipSelectors});

        cuts[1] = FacetCut({facetAddress: address(accessControlFacet), action: FacetCutAction.Add, functionSelectors: accessControlSelectors});

        cuts[2] = FacetCut({facetAddress: address(w3lc3), action: FacetCutAction.Add, functionSelectors: w3lc3Selectors});

        // Upgrade our diamond with the remaining facets by making the cuts. Must be owner!
        IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        console.log("Diamond cuts complete. Owner of Diamond:", IERC173(address(diamond)).owner());

        vm.stopBroadcast();
    }
}

// Register all facets.
// string[4] memory facets = [
//     // Native facets,
//     "DiamondCutFacet",
//     "DiamondLoupeFacet",
//     "OwnershipFacet",
//     // Raw implementation facets.
//     "Test1Facet"
//     // HostIT facets.
// ];

// string[] memory inputs = new string[](3);
// inputs[0] = "python3";
// inputs[1] = "script/python/get_selectors.py";

// // Loop on each facet, deploy them and create the FacetCut.
// for (uint256 facetIndex = 0; facetIndex < facets.length; facetIndex++) {
//     string memory facet = facets[facetIndex];

//     // Deploy the facet.
//     bytes memory bytecode = vm.getCode(string.concat(facet, ".sol"));
//     address facetAddress;
//     assembly {
//         facetAddress := create(0, add(bytecode, 0x20), mload(bytecode))
//     }

//     // Get the facet selectors.
//     inputs[2] = facet;
//     bytes memory res = vm.ffi(inputs);
//     bytes4[] memory selectors = abi.decode(res, (bytes4[]));

//     // Create the FacetCut struct for this facet.
//     _facetCuts.push(
//         FacetCut({
//             facetAddress: facetAddress,
//             action: FacetCutAction.Add,
//             functionSelectors: selectors
//         })
//     );
// }

// contract DeployDiamondScript is Script {
//     function run() external {

//         vm.startBroadcast();

//         // Deploy Contracts
//         DiamondInit diamondInit = new DiamondInit();
//         DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
//         DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
//         OwnershipFacet ownershipFacet = new OwnershipFacet();

//         // We prepare an array of `cuts` that we want to upgrade our Diamond with.
//         // The remaining cuts that we want the diamond to have are the Loupe and Ownership facets.
//         // A `cut` is a facet, its associated functions, and the action (we want to add).
//         // (DiamondCutFacet was already cut during Diamond deployment, cannot re-add again anyway).
//         FacetCut[] memory cuts = new FacetCut[](2);

//         // We create and populate array of function selectors needed for FacetCut Structs
//         bytes4[] memory loupeSelectors = new bytes4[](5);
//         loupeSelectors[0] = IDiamondLoupe.facets.selector;
//         loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
//         loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
//         loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
//         loupeSelectors[4] = IERC165.supportsInterface.selector; // The IERC165 function found in the Loupe.

//         bytes4[] memory ownershipSelectors = new bytes4[](2);
//         ownershipSelectors[0] = IERC173.owner.selector; // IERC173 has all the ownership functions needed.
//         ownershipSelectors[1] = IERC173.transferOwnership.selector;

//         // Populate the `cuts` array with all data needed for each `FacetCut` struct
//         cuts[0] = FacetCut({
//             facetAddress: address(diamondLoupeFacet),
//             action: FacetCutAction.Add,
//             functionSelectors: loupeSelectors
//         });

//         cuts[1] = FacetCut({
//             facetAddress: address(ownershipFacet),
//             action: FacetCutAction.Add,
//             functionSelectors: ownershipSelectors
//         });

//         // After we have all the cuts setup how we want, we can upgrade the diamond to include these facets.
//         // We call `diamondCut` with our `diamond` contract through the `IDiamondCutFacet` interface.
//         // `diamondCut` takes in the `cuts` and the `DiamondInit` contract and calls its `init()` function.
//         // IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

//         DiamondArgs memory args = DiamondArgs({
//             init: address(0),
//             initCalldata: ""
//         });

//         // Public address associated with the private key that launched this script is now the owner. (msg.sender).
//         Diamond diamond = new Diamond(cuts, args);
//         console.log("Deployed Diamond.sol at address:", address(diamond));

//         // We use `IERC173` instead of an `IOwnershipFacet` interface for the `OwnershipFacet` with no problems
//         // because all functions from `OwnershipFacet` are just IERC173 overrides.
//         // However, for more complex facets that are not exactly 1:1 with an existing IERC,
//         // you can create custom `IExampleFacet` interface that isn't just identical to an IERC.
//         console.log("Diamond cuts complete. Owner of Diamond:", IERC173(address(diamond)).owner());

//         vm.stopBroadcast();
//     }
// }
