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

import {LibDiamond} from "../contracts/libraries/LibDiamond.sol";

import {Diamond, DiamondArgs} from "../contracts/Diamond.sol";

contract CutW3LC3 is Script {
    // IDiamondInit public DiamondInit;

    // function setUp() external {
    //     address diamondInit = 0xa513e6e4b8f2a923d98304ec87f64353c4d5c853;
    //     address diamond = 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82;

        
    // }

    function run() external {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        
        W3LC3__ERC721A w3lc3 = new W3LC3__ERC721A();

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory w3lc3Selectors = new bytes4[](19);
        w3lc3Selectors[0] = IW3LC3__ERC721A.w3lc3__totalSupply.selector;
        w3lc3Selectors[1] = IW3LC3__ERC721A.w3lc3__balanceOf.selector;
        w3lc3Selectors[2] = IW3LC3__ERC721A.w3lc3__ownerOf.selector;
        // w3lc3Selectors[3] = 0xf2e3b036; //w3lc3__safeTransferFrom
        w3lc3Selectors[3] = 0x3a8acfd7; //w3lc3__safeTransferFrom
        w3lc3Selectors[4] = IW3LC3__ERC721A.w3lc3__transferFrom.selector;
        w3lc3Selectors[5] = IW3LC3__ERC721A.w3lc3__approve.selector;
        w3lc3Selectors[6] = IW3LC3__ERC721A.w3lc3__setApprovalForAll.selector;
        w3lc3Selectors[7] = IW3LC3__ERC721A.w3lc3__getApproved.selector;
        w3lc3Selectors[8] = IW3LC3__ERC721A.w3lc3__isApprovedForAll.selector;
        w3lc3Selectors[9] = IW3LC3__ERC721A.w3lc3__name.selector;
        w3lc3Selectors[10] = IW3LC3__ERC721A.w3lc3__symbol.selector;
        w3lc3Selectors[11] = IW3LC3__ERC721A.w3lc3__tokenURI.selector;
        w3lc3Selectors[12] = W3LC3__ERC721A.w3lc3__setBaseURI.selector;
        w3lc3Selectors[13] = W3LC3__ERC721A.w3lc3__mintSingle.selector;
        w3lc3Selectors[14] = W3LC3__ERC721A.w3lc3__mintMultipe.selector;
        w3lc3Selectors[15] = W3LC3__ERC721A.w3lc3__batchMint.selector;
        // w3lc3Selectors[17] = 0xe8f76096; //w3lc3__batchTransfer
        w3lc3Selectors[16] = 0x25897632; //w3lc3__batchTransfer
        w3lc3Selectors[17] = W3LC3__ERC721A.w3lc3__setBaseURI.selector;
        w3lc3Selectors[18] = W3LC3__ERC721A.w3lc3__verifyAttendance.selector;

        cuts[0] = FacetCut({facetAddress: address(w3lc3), action: FacetCutAction.Add, functionSelectors: w3lc3Selectors});

        IDiamondCut(0x59b670e9fA9D0A427751Af201D676719a970857b).diamondCut(cuts, address(0x0B306BF915C4d645ff596e518fAf3F9669b97016), abi.encodeWithSignature("init()"));

        vm.stopBroadcast();

    }

}