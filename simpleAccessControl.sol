pragma solidity ^0.8.17;

abstract contract SimpleAccessControl {

    enum Role { MainAdmin, Admin, Mailer }

    struct RealAddress {
        uint256 index;
        string city;
        string street;
        string house;
    }

    struct PersonInfo {
        string surname;
        RealAddress realAddress;
        bool active;
    }
    struct RoleData {
        mapping(address => bool) members;
        Role adminRole;
    }

    mapping(Role => RoleData) public role;

   /* constructor() {
        role[]
    }*/
    mapping(address => PersonInfo) public personInfo;
    
    modifier inSystem(address person) {
        require(
            personInfo[person].active,
            "Person isnt in system."
        );
        _;
    }

    function changeSurname(string memory newSurname) public inSystem(msg.sender) {
        require(keccak256(bytes(newSurname)) == keccak256(bytes("")));

        personInfo[msg.sender].surname = newSurname;         
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

        personInfo[msg.sender].realAddress = RealAddress(index,city,street,house);
    }

}