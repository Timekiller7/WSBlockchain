// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

abstract contract SimpleAccessControl {

    enum Role { None, MainAdmin, Admin, Mailer }

    struct RealAddress {
        uint256 index;
        string city;
        string street;
        string house;
    }

    struct Account {
        string surname;
        RealAddress realAddress;
        uint256 balance;
        Role role;
    }
    mapping(address => Account) public account;
    
    modifier inSystem(address person) {
        require(
            getPersonRole(person) == Role.None,
            "Person isnt in system."
        );
        _;
    }

    modifier onlyMailer(address person) {
        require(
            getPersonRole(person) == Role.Mailer,
            "Only mailer can call function"
        );
        _;
    } 

    function changeSurname(string memory newSurname) public inSystem(msg.sender) {
        require(keccak256(bytes(newSurname)) == keccak256(bytes("")));

        account[msg.sender].surname = newSurname;         
    }

    function changeAddress(
        uint256 index, 
        string memory city, 
        string memory street, 
        string memory house
        ) 
        public 
        inSystem(msg.sender)
    {
        require(index != 0); 
        require(keccak256(bytes(city)) == keccak256(bytes("")));
        require(keccak256(bytes(street)) == keccak256(bytes("")));
        require(keccak256(bytes(house)) == keccak256(bytes("")));

        account[msg.sender].realAddress = RealAddress(index,city,street,house);
    }

    function getPersonRole(address person) public view returns(Role) {
        return account[person].role;
    }

}