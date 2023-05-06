// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

abstract contract SimpleAccessControl {

    enum Role { None, MainAdmin, Admin, Mailer, User, System }

    struct RealAddress {
        uint256 numberMail;
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
            getPersonRole(person) != Role.None,
            "Person isnt in system."
        );
        _;
    }

    modifier hasRole(address person, Role role) {
        require(
            getPersonRole(person) == role,
            "You have no rights to call function"
        );
        _;
    }

    function registerInMail(
        string memory surname, 
        uint256 numberMail, 
        string memory city, 
        string memory street, 
        string memory house
        ) 
        external 
        hasRole(msg.sender, Role.None) 
    {
        account[msg.sender].role = Role.User;
        changeAddress(numberMail,city,street,house);
        changeSurname(surname);
    }

    function upgradePersons(address[] memory addresses) external {
        Role callerRole = getPersonRole(msg.sender);
        require(callerRole == Role.MainAdmin || callerRole == Role.Admin);

        Role newRole = Role(uint256(callerRole)+1);

        uint256 len = addresses.length;
        uint256 i;
        address accountAddress;

        for(i; i < len; i++) {
            accountAddress = addresses[i];
            require(getPersonRole(accountAddress) == Role.User);

            account[accountAddress].role = newRole;
        }
    }

    function downgradePersons(address[] memory addresses) external {
        Role callerRole = getPersonRole(msg.sender);
        require(callerRole == Role.MainAdmin || callerRole == Role.Admin);
        Role addressRoleMustBe = Role(uint256(callerRole)+1);
   
        uint256 len = addresses.length;
        uint256 i;
        address accountAddress;
        for(i; i < len; i++) {
            accountAddress = addresses[i];
            require(account[accountAddress].role == addressRoleMustBe);
            account[accountAddress].role = Role.User;
        }
    }

    function changeSurname(string memory newSurname) public inSystem(msg.sender) {
        require(keccak256(bytes(newSurname)) != keccak256(bytes("")));

        account[msg.sender].surname = newSurname;         
    }

    function changeAddress(
        uint256 numberMail, 
        string memory city, 
        string memory street, 
        string memory house
        ) 
        public 
        inSystem(msg.sender)
    {
        require(numberMail <= 16); 
        require(keccak256(bytes(city)) != keccak256(bytes("")));
        require(keccak256(bytes(street)) != keccak256(bytes("")));
        require(keccak256(bytes(house)) != keccak256(bytes("")));

        account[msg.sender].realAddress = RealAddress(numberMail,city,street,house);
    }
        

    function getPersonRole(address person) public view returns(Role) {
        return account[person].role;
    }
    function claimFunds(address receiver, uint256 toClaim) external hasRole(msg.sender, Role.MainAdmin) {
        _claimFunds(receiver, toClaim);
    }

    function _claimFunds(address receiver, uint256 toClaim) internal {
        (bool sent, ) = (receiver).call{value: toClaim}("");
        require(sent, "Failed to send Ether");
    }

}