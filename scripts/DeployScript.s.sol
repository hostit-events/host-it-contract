// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {IDiamondInit} from "../contracts/interfaces/IDiamondInit.sol";
import {DiamondInit} from "../contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "../contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../contracts/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../contracts/interfaces/IERC165.sol";
import {IERC173} from "../contracts/interfaces/IERC173.sol";

import {Diamond, DiamondArgs} from "../contracts/Diamond.sol";

contract DeployScript is Script {
    // Store the FacetCut struct for each facet that is being deployed.
    // NOTE: using storage array to easily "push" new FacetCut as we
    // process the facets.
    FacetCut[] private _facetCuts;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // Start by deploying the DiamonInit contract.
        DiamondInit diamondInit = new DiamondInit();

        // Register all facets.
        string[4] memory facets = [
            // Native facets,
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            // Raw implementation facets.
            "Test1Facet"
            // HostIT facets.
        ];

        string[] memory inputs = new string[](3);
        inputs[0] = "python3";
        inputs[1] = "script/python/get_selectors.py";

        // Loop on each facet, deploy them and create the FacetCut.
        for (uint256 facetIndex = 0; facetIndex < facets.length; facetIndex++) {
            string memory facet = facets[facetIndex];

            // Deploy the facet.
            bytes memory bytecode = vm.getCode(string.concat(facet, ".sol"));
            address facetAddress;
            assembly {
                facetAddress := create(0, add(bytecode, 0x20), mload(bytecode))
            }

            // Get the facet selectors.
            inputs[2] = facet;
            bytes memory res = vm.ffi(inputs);
            bytes4[] memory selectors = abi.decode(res, (bytes4[]));

            // Create the FacetCut struct for this facet.
            _facetCuts.push(
                FacetCut({
                    facetAddress: facetAddress,
                    action: FacetCutAction.Add,
                    functionSelectors: selectors
                })
            );
        }

        // Build the DiamondArgs.
        DiamondArgs memory diamondArgs = DiamondArgs({
            init: address(diamondInit),
            // NOTE: "interfaceId" can be used since "init" is the only function in IDiamondInit.
            initCalldata: abi.encode(type(IDiamondInit).interfaceId)
        });

        // Deploy the diamond.
        Diamond diamond = new Diamond(_facetCuts, diamondArgs);

        vm.stopBroadcast();
    }
}

contract DeployDiamondScript is Script {
    function run() external {

        vm.startBroadcast();

        // Deploy Contracts
        DiamondInit diamondInit = new DiamondInit();
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();

        // We prepare an array of `cuts` that we want to upgrade our Diamond with.
        // The remaining cuts that we want the diamond to have are the Loupe and Ownership facets.
        // A `cut` is a facet, its associated functions, and the action (we want to add).
        // (DiamondCutFacet was already cut during Diamond deployment, cannot re-add again anyway).
        FacetCut[] memory cuts = new FacetCut[](2);

        // We create and populate array of function selectors needed for FacetCut Structs
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector; // The IERC165 function found in the Loupe.

        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = IERC173.owner.selector; // IERC173 has all the ownership functions needed.
        ownershipSelectors[1] = IERC173.transferOwnership.selector;

        // Populate the `cuts` array with all data needed for each `FacetCut` struct
        cuts[0] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        cuts[1] = FacetCut({
            facetAddress: address(ownershipFacet),
            action: FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // After we have all the cuts setup how we want, we can upgrade the diamond to include these facets.
        // We call `diamondCut` with our `diamond` contract through the `IDiamondCutFacet` interface.
        // `diamondCut` takes in the `cuts` and the `DiamondInit` contract and calls its `init()` function.
        // IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        DiamondArgs memory args = DiamondArgs({
            init: address(0),
            initCalldata: ""
        });

        // Public address associated with the private key that launched this script is now the owner. (msg.sender).
        Diamond diamond = new Diamond(cuts, args);
        console.log("Deployed Diamond.sol at address:", address(diamond));

        // We use `IERC173` instead of an `IOwnershipFacet` interface for the `OwnershipFacet` with no problems
        // because all functions from `OwnershipFacet` are just IERC173 overrides.
        // However, for more complex facets that are not exactly 1:1 with an existing IERC, 
        // you can create custom `IExampleFacet` interface that isn't just identical to an IERC.
        console.log("Diamond cuts complete. Owner of Diamond:", IERC173(address(diamond)).owner());

        vm.stopBroadcast();
    }
}
