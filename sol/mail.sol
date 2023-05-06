// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./simpleAccessControl.sol";

contract Mail is SimpleAccessControl {

/*   ОТПРАВЛЕНИЕ   */
    enum Type { Mail, Parcel, Pack }     // письмо бандероль посылка
    enum ClassType { Third, Second, First }

    struct PackageDayCost {
        uint8 deliverDays;   // 1 day = 5sec in real life
        uint256 ethCost;    // 1 ether is 10**18 wei
    }

    struct Package {
        address sender;
        address receiver;
        Type packType;
        ClassType classType;
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

    // TRACK NUMBER = RR + date +
    mapping(string => Package) public trackNumber;
    

    /*   ДЕНЬГА ПЕРЕВОД   */
    struct MoneyTransfer {
        address sender;
        address receiver;
        uint256 sum;    // eth
        uint256 ttl;   // days
    }

//!!!получение почтового отправления через сотрудника почтового отделения, а также самостоятельно выполнять денежные переводы.

/*   TRACK SYSTEM    */
    struct TrackData {
        uint256 idMail;  // из таблицы, автоматом /идентификатор отделения
        uint8 weight;
    }

    mapping(string => TrackData) public trackingSystem;

    mapping(address => uint256) public workerToNumber;
    mapping(uint256 => uint256) public numberToMailIndex;

    constructor(uint256[] memory calldatamailIndexes) {
        packageDayCost[ClassType.First] = PackageDayCost(5, 0.5 ether);
        packageDayCost[ClassType.Second] = PackageDayCost(10, 0.3 ether);
        packageDayCost[ClassType.Third] = PackageDayCost(15, 0.1 ether);

        for(i=0;i<)
        
        numberToMailIndex[0] = 344000;
        numberToMailIndex[1] = 347900;
        numberToMailIndex[2] = 347901;
        numberToMailIndex[3] = 347902;
        numberToMailIndex[4] = 347903;
        numberToMailIndex[5] = 344000;
        numberToMailIndex[6] = 344000;
        numberToMailIndex[7] = 344000;
        numberToMailIndex[8] = 344000;
        numberToMailIndex[9] = 344000;


    }

    
    function updateBalance() external payable inSystem(msg.sender) {
        account[msg.sender].balance += msg.value;
    }

    function sendPackage(
        address sender,
        address receiver,
        Type packType,
        ClassType classType,
        uint8 weight,        
        uint256 precious
        ) 
        external 
        onlyMailer(msg.sender) 
        inSystem(sender) 
        inSystem(receiver)
    {
        uint256 costSum = calculateSumCost(classType,weight,precious);


        




        
        


    }

//стоимОтКласса*Вес+ценность*0.1
    function calculateSumCost(ClassType classType, uint8 weight, uint256 precious) public view returns(uint256) {
        uint256 classCost = packageDayCost[classType].ethCost;
        
        return (classCost*weight + precious/10);
    }

}
