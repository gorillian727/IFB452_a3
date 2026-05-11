// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
ProdArch - Product Archive Blockchain Application

This system stores product records on-chain.
Large files such as manuals/specifications are stored off-chain.
Only their hashes and links are stored on-chain.
*/

contract ProductRegistry {

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    struct Product {
        uint productId;
        string productName;
        string modelNumber;
        string manufacturerName;
        address manufacturerAddress;
        string manualLink;
        string manualHash;
        string specificationsLink;
        string specificationsHash;
        bool exists;
    }

    mapping(address => bool) public approvedManufacturers;
    mapping(uint => Product) public products;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyApprovedManufacturer() {
        require(approvedManufacturers[msg.sender] == true, "Not an approved manufacturer");
        _;
    }

    function approveManufacturer(address _manufacturer) public onlyAdmin {
        approvedManufacturers[_manufacturer] = true;
    }

    function registerProduct(
        uint _productId,
        string memory _productName,
        string memory _modelNumber,
        string memory _manufacturerName
    ) public onlyApprovedManufacturer {
        require(products[_productId].exists == false, "Product already exists");

        products[_productId] = Product(
            _productId,
            _productName,
            _modelNumber,
            _manufacturerName,
            msg.sender,
            "",
            "",
            "",
            "",
            true
        );
    }

    function addManual(
        uint _productId,
        string memory _manualLink,
        string memory _manualHash
    ) public onlyApprovedManufacturer {
        require(products[_productId].exists == true, "Product does not exist");
        require(products[_productId].manufacturerAddress == msg.sender, "Only original manufacturer can update");

        products[_productId].manualLink = _manualLink;
        products[_productId].manualHash = _manualHash;
    }

    function addSpecifications(
        uint _productId,
        string memory _specificationsLink,
        string memory _specificationsHash
    ) public onlyApprovedManufacturer {
        require(products[_productId].exists == true, "Product does not exist");
        require(products[_productId].manufacturerAddress == msg.sender, "Only original manufacturer can update");

        products[_productId].specificationsLink = _specificationsLink;
        products[_productId].specificationsHash = _specificationsHash;
    }

    function getProduct(uint _productId) public view returns (
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory
    ) {
        require(products[_productId].exists == true, "Product does not exist");

        Product memory p = products[_productId];

        return (
            p.productName,
            p.modelNumber,
            p.manufacturerName,
            p.manualLink,
            p.manualHash,
            p.specificationsLink,
            p.specificationsHash
        );
    }
}

contract AccessAndVerification {

    ProductRegistry public registry;

    constructor(address _registryAddress) {
        registry = ProductRegistry(_registryAddress);
    }

    function viewProductDetails(uint _productId) public view returns (
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory
    ) {
        return registry.getProduct(_productId);
    }

    function verifyManual(
        uint _productId,
        string memory _manualHashToCheck
    ) public view returns (bool) {
        (
            ,
            ,
            ,
            ,
            string memory storedManualHash,
            ,
            
        ) = registry.getProduct(_productId);

        return keccak256(abi.encodePacked(storedManualHash)) == keccak256(abi.encodePacked(_manualHashToCheck));
    }

    function verifySpecifications(
        uint _productId,
        string memory _specificationsHashToCheck
    ) public view returns (bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            string memory storedSpecificationsHash
        ) = registry.getProduct(_productId);

        return keccak256(abi.encodePacked(storedSpecificationsHash)) == keccak256(abi.encodePacked(_specificationsHashToCheck));
    }
}