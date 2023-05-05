pragma solidity ^0.8.17;

import "./simpleAccessControl.sol";

contract Mail is SimpleAccessControl {

/*   ОТПРАВЛЕНИЕ   */
enum Type {Mail, Parcel, Pack}     // письмо бандероль посылка
enum ClassType {First, Second, Third}

struct PackageDayCost {
    uint8 deliverDays;   // 1 day = 5sec in real life
    uint256 ethCost;    // 1 ether is 10**18 wei
}

struct Package {
    address sender;
    address receiver;
    Type packType;
    ClassType classType;
    uint8 deliverDays;
    uint8 weight;          // <=10, in kg
    uint256 precious;     // def = 0
    // sumCost is calculated, dont want to store it
    RealAddress addressSender;
    RealAddress addressReceiver;
}

// для вывода
struct PackageInterface {
    address sender;
    address receiver;
    Type packType;
    ClassType classType;
    uint8 deliverDays;  
    uint256 ethCost;
    uint8 weight;
    uint256 precious;
    uint256 sumCost;
    RealAddress addressSender;
    RealAddress addressReceiver;
}


mapping(ClassType => PackageDayCost) public packageDayCost;
mapping(string => Package) public trackNumber;
//RR +date+
/*   ДЕНЬГА ПЕРЕВОД   */
struct MoneyTransfer {
    address sender;
    address receiver;
    uint256 sum;    // eth
    uint256 ttl;   // days
}



function calculateSumCost(string memory _trackNumber) public view returns(uint256) {


}

}
