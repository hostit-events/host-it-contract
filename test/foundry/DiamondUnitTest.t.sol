// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {HostIT} from "contracts/HostIT.sol";
import {DiamondInit} from "contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "contracts/facets/DiamondLoupeFacet.sol";
import {AccessControlFacet} from "contracts/facets/AccessControlFacet.sol";
import {W3LC2024Facet} from "contracts/facets/standalone_events/W3LC2024Facet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "contracts/interfaces/IDiamondCut.sol";
import {IDiamondInit} from "../../contracts/interfaces/IDiamondInit.sol";
import {IDiamondLoupe} from "contracts/interfaces/IDiamondLoupe.sol";
import {IAccessControl} from "contracts/interfaces/IAccessControl.sol";
import {IERC165} from "contracts/interfaces/IERC165.sol";

import {LibDiamond, DiamondArgs} from "contracts/libraries/LibDiamond.sol";
// import {LibApp} from "contracts/libraries/LibApp.sol";

import {W3LC2024} from "contracts/nfts/W3LC2024.sol";

contract DiamondUnitTest is Test {
    HostIT diamond;
    DiamondInit diamondInit;

    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    AccessControlFacet accessControlFacet;

    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    W3LC2024Facet w3lc2024Facet;

    W3LC2024 w3lc2024Upgradeable;

    address diamondAdmin = address(0x1337DAD);
    address alice = address(0xA11C3);
    address bob = address(0xB0B);

    address[] facetAddressList;

    function setUp() public {
        // Deploy core diamond template contracts
        diamondInit = new DiamondInit();
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        accessControlFacet = new AccessControlFacet();
        w3lc2024Facet = new W3LC2024Facet();

        DiamondArgs memory initDiamondArgs = DiamondArgs({
            init: address(diamondInit),
            // NOTE: "interfaceId" can be used since "init" is the only function in IDiamondInit.
            initCalldata: abi.encode(type(IDiamondInit).interfaceId)
        });

        FacetCut[] memory initCut = new FacetCut[](4);

        bytes4[] memory initCutSelectors = new bytes4[](1);
        initCutSelectors[0] = IDiamondCut.diamondCut.selector;

        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;

        bytes4[] memory accessControlSelectors = new bytes4[](6);
        accessControlSelectors[0] = IAccessControl.hasRole.selector;
        accessControlSelectors[1] = IAccessControl.getRoleAdmin.selector;
        accessControlSelectors[2] = IAccessControl.grantRole.selector;
        accessControlSelectors[3] = IAccessControl.revokeRole.selector;
        accessControlSelectors[4] = IAccessControl.renounceRole.selector;
        accessControlSelectors[5] = AccessControlFacet.setRoleAdmin.selector;

        bytes4[] memory addW3lc2024Selectors = new bytes4[](7);
        addW3lc2024Selectors[0] = W3LC2024Facet.setW3LC2024NFT.selector;
        addW3lc2024Selectors[1] = W3LC2024Facet.w3lc2024__setDayActive.selector;
        addW3lc2024Selectors[2] = W3LC2024Facet.w3lc2024__setDayInactive.selector;
        addW3lc2024Selectors[3] = W3LC2024Facet.w3lc2024__markAttendance.selector;
        addW3lc2024Selectors[4] = W3LC2024Facet.w3lc2024__verifyAttendance.selector;
        addW3lc2024Selectors[5] = W3LC2024Facet.w3lc2024__returnAttendance.selector;
        addW3lc2024Selectors[6] = W3LC2024Facet.w3lc2024__isDayActive.selector;

        initCut[0] = FacetCut({facetAddress: address(diamondCutFacet), action: FacetCutAction.Add, functionSelectors: initCutSelectors});

        initCut[1] = FacetCut({facetAddress: address(diamondLoupeFacet), action: FacetCutAction.Add, functionSelectors: loupeSelectors});

        initCut[2] = FacetCut({facetAddress: address(accessControlFacet), action: FacetCutAction.Add, functionSelectors: accessControlSelectors});

        initCut[3] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Add, functionSelectors: addW3lc2024Selectors});

        vm.startPrank(diamondAdmin);
        console.log("Diamond Admin: ", address(diamondAdmin));
        console.log("Msg.sender: ", msg.sender);
        diamond = new HostIT(msg.sender, initCut, initDiamondArgs);
        vm.stopPrank();

        facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses

        // Set interfaces for less verbose diamond interactions.
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
    }

    function test_Deployment() public view {

        // All 3 facets have been added to the diamond, and are not 0x0 address.
        assertEq(facetAddressList.length, 4, "Cut, Loupe, AccessControl, W3LC2024");
        assertNotEq(facetAddressList[0], address(0), "Not 0x0 address");
        assertNotEq(facetAddressList[1], address(0), "Not 0x0 address");
        assertNotEq(facetAddressList[2], address(0), "Not 0x0 address");
        assertNotEq(facetAddressList[3], address(0), "Not 0x0 address");

        // Owner is set correctly?
        // assertEq(IERC173(address(diamond)).owner(), diamondOwner, "Diamond owner set properly");

        // Interface support set to true during `init()` call during Diamond upgrade?
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId), "IERC165");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId), "Cut");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId), "Loupe");

        // Facets have the correct function selectors?
        bytes4[] memory loupeViewCut = ILoupe.facetFunctionSelectors(facetAddressList[0]); // DiamondCut
        bytes4[] memory loupeViewLoupe = ILoupe.facetFunctionSelectors(facetAddressList[1]); // Loupe
        bytes4[] memory loupeViewAccessControl = ILoupe.facetFunctionSelectors(facetAddressList[2]); // AccessControl
        bytes4[] memory loupeViewW3lc2024 = ILoupe.facetFunctionSelectors(facetAddressList[3]); // W3LC2024

        assertEq(loupeViewCut[0], IDiamondCut.diamondCut.selector, "should match");

        assertEq(loupeViewLoupe[0], IDiamondLoupe.facets.selector, "should match");
        assertEq(loupeViewLoupe[1], IDiamondLoupe.facetFunctionSelectors.selector, "should match");
        assertEq(loupeViewLoupe[2], IDiamondLoupe.facetAddresses.selector, "should match");
        assertEq(loupeViewLoupe[3], IDiamondLoupe.facetAddress.selector, "should match");
        assertEq(loupeViewLoupe[4], IERC165.supportsInterface.selector, "should match");
        
        assertEq(loupeViewAccessControl[0], IAccessControl.hasRole.selector, "should match");
        assertEq(loupeViewAccessControl[1], IAccessControl.getRoleAdmin.selector, "should match");
        assertEq(loupeViewAccessControl[2], IAccessControl.grantRole.selector, "should match");
        assertEq(loupeViewAccessControl[3], IAccessControl.revokeRole.selector, "should match");
        assertEq(loupeViewAccessControl[4], IAccessControl.renounceRole.selector, "should match");
        assertEq(loupeViewAccessControl[5], AccessControlFacet.setRoleAdmin.selector, "should match");

        assertEq(loupeViewW3lc2024[0], W3LC2024Facet.setW3LC2024NFT.selector, "should match");
        assertEq(loupeViewW3lc2024[1], W3LC2024Facet.w3lc2024__setDayActive.selector, "should match");
        assertEq(loupeViewW3lc2024[2], W3LC2024Facet.w3lc2024__setDayInactive.selector, "should match");
        assertEq(loupeViewW3lc2024[3], W3LC2024Facet.w3lc2024__markAttendance.selector, "should match");
        assertEq(loupeViewW3lc2024[4], W3LC2024Facet.w3lc2024__verifyAttendance.selector, "should match");
        assertEq(loupeViewW3lc2024[5], W3LC2024Facet.w3lc2024__returnAttendance.selector, "should match");
        assertEq(loupeViewW3lc2024[6], W3LC2024Facet.w3lc2024__isDayActive.selector, "should match");

        // Function selectors are associated with the correct facets?
        assertEq(facetAddressList[0], ILoupe.facetAddress(IDiamondCut.diamondCut.selector), "should match");

        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facets.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetFunctionSelectors.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddresses.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddress.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IERC165.supportsInterface.selector), "should match");

        assertEq(facetAddressList[2], ILoupe.facetAddress(IAccessControl.hasRole.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IAccessControl.getRoleAdmin.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IAccessControl.grantRole.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IAccessControl.revokeRole.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IAccessControl.renounceRole.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(AccessControlFacet.setRoleAdmin.selector), "should match");

        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.setW3LC2024NFT.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__setDayActive.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__setDayInactive.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__markAttendance.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__verifyAttendance.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__returnAttendance.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(W3LC2024Facet.w3lc2024__isDayActive.selector), "should match");
    }

    function test_W3lc2024Nft() public {
        w3lc2024Upgradeable = new W3LC2024();
        console.log(address(w3lc2024Upgradeable));
    }
}

//     address diamondOwner = address(0x1337DAD);
//     address alice = address(0xA11C3);
//     address bob = address(0xB0B);

//     address[] facetAddressList;

//     function setUp() public {
//         // Deploy core diamond template contracts
//         diamondInit = new DiamondInit();
//         diamondCutFacet = new DiamondCutFacet();
//         diamondLoupeFacet = new DiamondLoupeFacet();
//         ownershipFacet = new OwnershipFacet();
//         accessControlFacet = new AccessControlFacet();

//         DiamondArgs memory args = DiamondArgs({
//             init: address(0),
//             initCalldata: ""
//         });

//         diamond = new HostIT(diamondOwner, cuts, args);

//         // Create the `cuts` array. (Already cut DiamondCut during diamond deployment)
//         FacetCut[] memory cuts = new FacetCut[](3);

//         // Get function selectors for facets for `cuts` array.
//         bytes4[] memory loupeSelectors = new bytes4[](5);
//         loupeSelectors[0] = IDiamondLoupe.facets.selector;
//         loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
//         loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
//         loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
//         loupeSelectors[4] = IERC165.supportsInterface.selector;

//         bytes4[] memory ownershipSelectors = new bytes4[](2);
//         ownershipSelectors[0] = IERC173.owner.selector;
//         ownershipSelectors[1] = IERC173.transferOwnership.selector;

//         bytes4[] memory accessControlSelectors = new bytes4[](5);
//         accessControlSelectors[0] = IAccessControl.hasRole.selector;
//         accessControlSelectors[1] = IAccessControl.getRoleAdmin.selector;
//         accessControlSelectors[2] = IAccessControl.grantRole.selector;
//         accessControlSelectors[3] = IAccessControl.revokeRole.selector;
//         accessControlSelectors[4] = IAccessControl.renounceRole.selector;

//         // Populate the `cuts` array with the needed data.
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

//         cuts[2] = FacetCut({
//             facetAddress: address(accessControlFacet),
//             action: FacetCutAction.Add,
//             functionSelectors: accessControlSelectors
//         });

//         vm.prank(diamondOwner);

//         // Upgrade our diamond with the remaining facets by making the cuts. Must be owner!
//         IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

//         facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses

//         // Set interfaces for less verbose diamond interactions.
//         ILoupe = IDiamondLoupe(address(diamond));
//         ICut = IDiamondCut(address(diamond));
//     }

//     function test_Deployment() public view {

//         // All 3 facets have been added to the diamond, and are not 0x0 address.
//         assertEq(facetAddressList.length, 3, "Cut, Loupe, Ownership");
//         assertNotEq(facetAddressList[0], address(0), "Not 0x0 address");
//         assertNotEq(facetAddressList[1], address(0), "Not 0x0 address");
//         assertNotEq(facetAddressList[2], address(0), "Not 0x0 address");

//         // Owner is set correctly?
//         assertEq(IERC173(address(diamond)).owner(), diamondOwner, "Diamond owner set properly");

//         // Interface support set to true during `init()` call during Diamond upgrade?
//         assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId), "IERC165");
//         assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId), "IERC173");
//         assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId), "Cut");
//         assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId), "Loupe");
//         assertTrue(IERC165(address(diamond)).supportsInterface(0x36372b07), "IERC20");
//         assertTrue(IERC165(address(diamond)).supportsInterface(0xa219a025), "IERC20MetaData");
//         assertTrue(IERC165(address(diamond)).supportsInterface(0xd9b67a26), "IERC1155");
//         assertTrue(IERC165(address(diamond)).supportsInterface(0x0e89341c), "IERC1155MetadataURI");

//         // Facets have the correct function selectors?
//         bytes4[] memory loupeViewCut = ILoupe.facetFunctionSelectors(facetAddressList[0]); // DiamondCut
//         bytes4[] memory loupeViewLoupe = ILoupe.facetFunctionSelectors(facetAddressList[1]); // Loupe
//         bytes4[] memory loupeViewOwnership = ILoupe.facetFunctionSelectors(facetAddressList[2]); // Ownership
//         assertEq(loupeViewCut[0], IDiamondCut.diamondCut.selector, "should match");
//         assertEq(loupeViewLoupe[0], IDiamondLoupe.facets.selector, "should match");
//         assertEq(loupeViewLoupe[1], IDiamondLoupe.facetFunctionSelectors.selector, "should match");
//         assertEq(loupeViewLoupe[2], IDiamondLoupe.facetAddresses.selector, "should match");
//         assertEq(loupeViewLoupe[3], IDiamondLoupe.facetAddress.selector, "should match");
//         assertEq(loupeViewLoupe[4], IERC165.supportsInterface.selector, "should match");
//         assertEq(loupeViewOwnership[0], IERC173.owner.selector, "should match");
//         assertEq(loupeViewOwnership[1], IERC173.transferOwnership.selector, "should match");

//         // Function selectors are associated with the correct facets?
//         assertEq(facetAddressList[0], ILoupe.facetAddress(IDiamondCut.diamondCut.selector), "should match");
//         assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facets.selector), "should match");
//         assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetFunctionSelectors.selector), "should match");
//         assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddresses.selector), "should match");
//         assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddress.selector), "should match");
//         assertEq(facetAddressList[1], ILoupe.facetAddress(IERC165.supportsInterface.selector), "should match");
//         assertEq(facetAddressList[2], ILoupe.facetAddress(IERC173.owner.selector), "should match");
//         assertEq(facetAddressList[2], ILoupe.facetAddress(IERC173.transferOwnership.selector), "should match");
//     }

//     // Tests Add, Replace, and Remove functionality for ExampleFacet
//     function test_AddReplaceRemove() public {

//         // Deploy another facet
//         // test1Facet = new Test1Facet();

//         // // We create and populate array of function selectors needed for the cut of Test1Facet.
//         // bytes4[] memory exampleSelectors = new bytes4[](5);
//         // exampleSelectors[0] = Test1Facet.test1Func1.selector;
//         // exampleSelectors[1] = Test1Facet.test1Func2.selector;
//         // exampleSelectors[2] = Test1Facet.test1Func3.selector;
//         // exampleSelectors[3] = Test1Facet.test1Func4.selector;
//         // exampleSelectors[4] = Test1Facet.test1Func5.selector;

//         // // Make the cut
//         // FacetCut[] memory cut = new FacetCut[](1);

//         // cut[0] = FacetCut({
//         //     facetAddress: address(test1Facet),
//         //     action: FacetCutAction.Add,
//         //     functionSelectors: exampleSelectors
//         // });

//         // // Upgrade diamond with ExampleFacet cut. No need to init anything special/new.
//         // vm.prank(diamondOwner);
//         // ICut.diamondCut(cut, address(0x0), "");

//         // // Update testing variable `facetAddressList` with our new facet by calling `facetAddresses()`.
//         // facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses();

//         // // 4 facets should now be in the Diamond. And the new one is valid.
//         // assertEq(facetAddressList.length, 4, "Cut, Loupe, Ownership, Test1Facet");
//         // assertNotEq(facetAddressList[3], address(0), "Test1Facet is not 0x0 address");

//         // // New facet has the correct function selectors?
//         // bytes4[] memory loupeViewExample = ILoupe.facetFunctionSelectors(facetAddressList[3]); // ExampleFacet
//         // assertEq(loupeViewExample[0], Test1Facet.test1Func1.selector, "should match");
//         // assertEq(loupeViewExample[1], Test1Facet.test1Func2.selector, "should match");
//         // assertEq(loupeViewExample[2], Test1Facet.test1Func3.selector, "should match");
//         // assertEq(loupeViewExample[3], Test1Facet.test1Func4.selector, "should match");
//         // assertEq(loupeViewExample[4], Test1Facet.test1Func5.selector, "should match");

//         // // Function selectors are associated with the correct facet.
//         // assertEq(facetAddressList[3], ILoupe.facetAddress(Test1Facet.test1Func1.selector), "should match");
//         // assertEq(facetAddressList[3], ILoupe.facetAddress(Test1Facet.test1Func2.selector), "should match");
//         // assertEq(facetAddressList[3], ILoupe.facetAddress(Test1Facet.test1Func3.selector), "should match");
//         // assertEq(facetAddressList[3], ILoupe.facetAddress(Test1Facet.test1Func4.selector), "should match");
//         // assertEq(facetAddressList[3], ILoupe.facetAddress(Test1Facet.test1Func5.selector), "should match");

//         // // We can successfully call the ExampleFacet functions.
//         // Test1Facet(address(diamond)).test1Func1();
//         // Test1Facet(address(diamond)).test1Func2();
//         // Test1Facet(address(diamond)).test1Func3();
//         // Test1Facet(address(diamond)).test1Func4();
//         // Test1Facet(address(diamond)).test1Func5();

//         // // We can successfully replace a function and put it in a different facet.
//         // bytes4[] memory selectorToReplace = new bytes4[](1);
//         // selectorToReplace[0] = Test1Facet.test1Func1.selector;

//         // // Make the cut
//         // FacetCut[] memory replaceCut = new FacetCut[](1);

//         // replaceCut[0] = FacetCut({
//         //     facetAddress: address(ownershipFacet),
//         //     action: FacetCutAction.Replace,
//         //     functionSelectors: selectorToReplace
//         // });

//         // vm.prank(diamondOwner);
//         // ICut.diamondCut(replaceCut, address(0), "");

//         // // The exampleFunction1 now lives in ownershipFacet and not ExampleFacet.
//         // assertEq(address(ownershipFacet), ILoupe.facetAddress(Test1Facet.test1Func1.selector));

//         // // Double checking, the Ownership facet now has the new function selector
//         // bytes4[] memory loupeViewOwnership = ILoupe.facetFunctionSelectors(facetAddressList[2]); // Ownership
//         // assertEq(loupeViewOwnership[0], IERC173.owner.selector, "should match");
//         // assertEq(loupeViewOwnership[1], IERC173.transferOwnership.selector, "should match");
//         // assertEq(loupeViewOwnership[2], Test1Facet.test1Func1.selector, "should match");

//         // // The ExampleFacet no longer has access to the exampleFunction1
//         // vm.expectRevert();
//         // Test1Facet(address(diamond)).test1Func1();

//         // // We can also remove functions completely by housing them in 0x0.
//         // bytes4[] memory selectorsToRemove = new bytes4[](2);
//         // selectorsToRemove[0] = Test1Facet.test1Func2.selector;
//         // selectorsToRemove[1] = Test1Facet.test1Func3.selector;

//         // // Make the cut
//         // FacetCut[] memory removeCut = new FacetCut[](1);

//         // removeCut[0] = FacetCut({
//         //     facetAddress: address(0),
//         //     action: FacetCutAction.Remove,
//         //     functionSelectors: selectorsToRemove
//         // });

//         // // Remove the functions via the removeCut
//         // vm.prank(diamondOwner);
//         // ICut.diamondCut(removeCut, address(0), "");

//         // // Functions cannot be called and no longer exist in the diamond.
//         // vm.expectRevert();
//         // Test1Facet(address(diamond)).test1Func2();
//         // vm.expectRevert();
//         // Test1Facet(address(diamond)).test1Func3();

//         // // The exampleFunction2 and 3 now live at 0x0.
//         // assertEq(address(0), ILoupe.facetAddress(Test1Facet.test1Func2.selector));
//         // assertEq(address(0), ILoupe.facetAddress(Test1Facet.test1Func3.selector));

//         // Note: I have not changed the template in diamond-3 in any meaningful way.
//         // Therefore, I did not include the cache bug test here b/c it is fixed in diamond-3.
//     }

//     // Deploying & Cutting ERC20Facet, state updates, transfers, approval, error emission, event emission.
//     // function test_ERC20() public {

//     //     erc20Facet = new ERC20Facet();

//     //     FacetCut[] memory cut = new FacetCut[](1);

//     //     bytes4[] memory selectors = new bytes4[](11);
//     //     selectors[0] = IERC20Facet.initialize.selector;
//     //     selectors[1] = IERC20Facet.name.selector;
//     //     selectors[2] = IERC20Facet.symbol.selector;
//     //     selectors[3] = IERC20Facet.decimals.selector;
//     //     selectors[4] = IERC20Facet.balanceOf.selector;
//     //     selectors[5] = IERC20Facet.allowance.selector;
//     //     selectors[6] = IERC20Facet.transfer.selector; // ignore any IDE coloring, its ERC20.transfer()
//     //     selectors[7] = IERC20Facet.transferFrom.selector;
//     //     selectors[8] = IERC20Facet.approve.selector;
//     //     selectors[9] = IERC20Facet.mint.selector;
//     //     selectors[10] = IERC20Facet.totalSupply.selector;

//     //     cut[0] = FacetCut({
//     //         facetAddress: address(erc20Facet),
//     //         action: FacetCutAction.Add,
//     //         functionSelectors: selectors
//     //     });

//     //     vm.prank(diamondOwner);
//     //     ICut.diamondCut(cut, address(0x0), "");
//     //     facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses
//     //     assertEq(facetAddressList.length, 4, "Cut, Loupe, Ownership, ERC20Facet"); // sanity checks
//     //     assertNotEq(facetAddressList[3], address(0), "ERC20Facet is not 0x0 address"); // sanity checks
//     //     IERC20Facet erc20 = IERC20Facet(address(diamond)); // for ease of use.

//     //     // Alice cannot call initialize
//     //     vm.expectRevert();
//     //     vm.prank(alice);
//     //     erc20.initialize(1000000e18, "MyERC20Facet", "MERC20F");

//     //     // Only owner can initialize
//     //     vm.startPrank(diamondOwner);
//     //     erc20.initialize(1000000e18, "MyERC20Facet", "MERC20F");
//     //     assertEq(erc20.name(), "MyERC20Facet", "should be name");
//     //     assertEq(erc20.symbol(), "MERC20F", "should be symbol");
//     //     assertEq(erc20.decimals(), 18, "should be 18 decimals");
//     //     assertEq(erc20.totalSupply(), 1000000e18, "initial supply should be 1M");
//     //     assertEq(erc20.balanceOf(diamondOwner), 1000000e18, "owner should have initial supply");

//     //     // Nobody can re-initialize
//     //     vm.expectRevert();
//     //     erc20.initialize(1337e18, "TokenName", "TKN"); // Cannot re-initialize

//     //     // Transfer (AppStorage balance updated properly and emits correct event)
//     //     vm.expectEmit();
//     //     emit IERC20Facet.Transfer(diamondOwner, bob, 69420e18);
//     //     erc20.transfer(bob, 69420e18);

//     //     assertEq(erc20.balanceOf(bob), 69420e18, "should get tokens");
//     //     assertEq(erc20.balanceOf(diamondOwner), 1000000e18-69420e18, "should deduct tokens");
//     //     vm.stopPrank();

//     //     // Transfer fails if u have no tokens (Reverts with correct custom error)
//     //     vm.expectRevert(abi.encodeWithSelector(IERC20Facet.ERC20InsufficientBalance.selector, alice, 0, 1));
//     //     vm.prank(alice);
//     //     erc20.transfer(bob, 1);

//     //     // Owner can mint more coins, but nobody else can.
//     //     vm.prank(diamondOwner);
//     //     erc20.mint(bob, 1337e18);
//     //     vm.prank(alice);
//     //     vm.expectRevert();
//     //     erc20.mint(alice, 1);

//     //     // diamondOwner approves alice to spend some of his tokens.
//     //     vm.prank(diamondOwner);
//     //     erc20.approve(alice, 1000e18);

//     //     // Cannot transferFrom more than allowance
//     //     vm.startPrank(alice);
//     //     vm.expectRevert(abi.encodeWithSelector(IERC20Facet.ERC20InsufficientAllowance.selector, alice, 1000e18, 1001e18));
//     //     erc20.transferFrom(diamondOwner, bob, 1001e18);

//     //     // Can transfer up to amount, but then no more
//     //     erc20.transferFrom(diamondOwner, bob, 1000e18);
//     //     vm.expectRevert(abi.encodeWithSelector(IERC20Facet.ERC20InsufficientAllowance.selector, alice, 0, 1));
//     //     erc20.transferFrom(diamondOwner, bob, 1);

//     //     // Note: These unit tests are not exhaustive b/c ERC20Facet inherits OZ ERC20 template.
//     //     // The only changes were adding `s` for storage on state-changing functions.
//     //     // Once we see the functions work, AppStorage updates, errors, and events are emitting properly
//     //     // Then everything appears to be in good working order.
//     // }

//     // Deploying & Cutting ERC1155Facet, state updates, transfers, approval, error emission, event emission.
//     // function test_ERC1155() public {

//     //     erc1155Facet = new ERC1155Facet();

//     //     FacetCut[] memory cut = new FacetCut[](1);

//     //     bytes4[] memory selectors = new bytes4[](12);
//     //     selectors[0] = IERC1155Facet.initialize.selector;
//     //     selectors[1] = IERC1155Facet.setURI.selector;
//     //     selectors[2] = IERC1155Facet.mint.selector;
//     //     selectors[3] = IERC1155Facet.uri.selector;
//     //     selectors[4] = IERC1155Facet.onERC1155Received.selector;
//     //     selectors[5] = IERC1155Facet.onERC1155BatchReceived.selector;
//     //     selectors[6] = IERC1155Facet.balanceOf.selector;
//     //     selectors[7] = IERC1155Facet.balanceOfBatch.selector;
//     //     selectors[8] = IERC1155Facet.setApprovalForAll.selector;
//     //     selectors[9] = IERC1155Facet.isApprovedForAll.selector;
//     //     selectors[10] = IERC1155Facet.safeTransferFrom.selector;
//     //     selectors[11] = IERC1155Facet.safeBatchTransferFrom.selector;

//     //     cut[0] = FacetCut({
//     //         facetAddress: address(erc1155Facet),
//     //         action: FacetCutAction.Add,
//     //         functionSelectors: selectors
//     //     });

//     //     vm.prank(diamondOwner);
//     //     ICut.diamondCut(cut, address(0x0), "");
//     //     facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses

//     //     assertEq(facetAddressList.length, 4, "Cut, Loupe, Ownership, ERC1155Facet"); // sanity checks
//     //     assertNotEq(facetAddressList[3], address(0), "ERC1155Facet is not 0x0 address"); // sanity checks
//     //     IERC1155Facet erc1155 = IERC1155Facet(address(diamond)); // for ease of use.

//     //     // Alice cannot call initialize
//     //     vm.expectRevert();
//     //     vm.prank(alice);
//     //     erc1155.initialize("exampleURI");

//     //     // Only owner can initialize
//     //     vm.startPrank(diamondOwner);
//     //     erc1155.initialize("MyERC1155URIString");
//     //     assertEq(erc1155.uri(0), "MyERC1155URIString", "should be name");

//     //     // Nobody can re-initialize
//     //     vm.expectRevert();
//     //     erc1155.initialize("Im trying to reinitialize ERC1155");

//     //     // Owner can mint himself 1000 tokens of ID 0.
//     //     // Check that it emits event correctly.
//     //     vm.expectEmit();
//     //     emit IERC1155Facet.TransferSingle(diamondOwner, address(0), diamondOwner, 0, 1000e18);
//     //     erc1155.mint(diamondOwner, 0, 1000e18, "");
//     //     vm.stopPrank();

//     //     // Transfer fails if u have no tokens (Reverts with correct custom error)
//     //     vm.expectRevert(abi.encodeWithSelector(IERC1155Facet.ERC1155InsufficientBalance.selector, alice, 0, 1, 0));
//     //     vm.prank(alice);
//     //     erc1155.safeTransferFrom(alice, bob, 0, 1, "");

//     //     // Transfer (AppStorage balance updated properly and emits correct event)
//     //     vm.prank(diamondOwner);
//     //     vm.expectEmit();
//     //     emit IERC1155Facet.TransferSingle(diamondOwner, diamondOwner, bob, 0, 420e18);
//     //     erc1155.safeTransferFrom(diamondOwner, bob, 0, 420e18, "");
//     //     assertEq(erc1155.balanceOf(diamondOwner, 0), 1000e18-420e18, "should deduct tokens");
//     //     assertEq(erc1155.balanceOf(bob, 0), 420e18, "bob gets 420 tokenID 0");

//     //     // TransferFrom (Bob tries to send diamondOwner tokens but doesn't have approval)
//     //     vm.prank(bob);
//     //     vm.expectRevert(abi.encodeWithSelector(IERC1155Facet.ERC1155MissingApprovalForAll.selector, bob, diamondOwner));
//     //     erc1155.safeTransferFrom(diamondOwner, alice, 0, 100e18, "");

//     //     // Gets approval
//     //     vm.prank(diamondOwner);
//     //     vm.expectEmit();
//     //     emit IERC1155Facet.ApprovalForAll(diamondOwner, bob, true);
//     //     erc1155.setApprovalForAll(bob, true);

//     //     // Bob can now send on behalf
//     //     vm.prank(bob);
//     //     vm.expectEmit();
//     //     emit IERC1155Facet.TransferSingle(bob, diamondOwner, alice, 0, 100e18);
//     //     erc1155.safeTransferFrom(diamondOwner, alice, 0, 100e18, "");

//     //     // Note: These unit tests are not exhaustive b/c ERC1155Facet inherits OZ ERC1155 template.
//     //     // The only changes were adding `s` for storage on state-changing functions.
//     //     // Once we see the functions work, AppStorage updates, errors, and events are emitting properly
//     //     // Then everything appears to be in good working order.

//     //     // Deploy FWAS2 to test no storage collisions with AppStorage and OZ ERC1155 inheritance
//     //     // We thwart the AppStorage collisions with AppStorageRoot contract in AppStorage
//     //     // Forcing the AppStorage to always be at slot 0 of a contract.
//     //     facetWithAppStorage2 = new FacetWithAppStorage2();

//     //     FacetCut[] memory cut2 = new FacetCut[](1);

//     //     bytes4[] memory selector = new bytes4[](6);
//     //     selector[0] = FacetWithAppStorage2.getFirstVar.selector;
//     //     selector[1] = FacetWithAppStorage2.changeNestedStruct.selector;
//     //     selector[2] = FacetWithAppStorage2.changeUnprotectedNestedStruct.selector;
//     //     selector[3] = FacetWithAppStorage2.viewNestedStruct.selector;
//     //     selector[4] = FacetWithAppStorage2.viewUnprotectedNestedStruct.selector;
//     //     selector[5] = FacetWithAppStorage2.getNumber.selector;

//     //     cut2[0] = FacetCut({
//     //         facetAddress: address(facetWithAppStorage2),
//     //         action: FacetCutAction.Add,
//     //         functionSelectors: selector
//     //     });

//     //     vm.prank(diamondOwner);
//     //     ICut.diamondCut(cut2, address(0x0), "");

//     //     facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses

//     //     FacetWithAppStorage2 FWAS2 = FacetWithAppStorage2(address(diamond)); // for ease of use.

//     //     // Importantly, without `AppStorageRoot`, the `_number` was 0 before. Now it matches.
//     //     uint256 _number = FWAS2.getNumber();
//     //     assertEq(_number, 777, "should match");
//     // }

// }
