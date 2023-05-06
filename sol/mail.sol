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
        uint8 weight;          // <=10, in kg  , origWeight
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
        uint256 numberMail;  // из таблицы, автоматом /идентификатор отделения
        uint8 weight;
        uint256 updateTimestamp;
        uint256 originalTimestamp;  // пусть будет по utc
    }
    mapping(string => TrackData) public trackingSystem;

    mapping(address => uint256) public workerToNumber;
    mapping(uint256 => uint256) public numberToMailIndex;  // numMail => realIndex

    constructor(uint256[17] memory mailIndexes) {
        packageDayCost[ClassType.First] = PackageDayCost(5, 0.5 ether);
        packageDayCost[ClassType.Second] = PackageDayCost(10, 0.3 ether);
        packageDayCost[ClassType.Third] = PackageDayCost(15, 0.1 ether);

        uint256 i;
        for(i = 0; i < 17; i ++) {
            numberToMailIndex[i] = mailIndexes[i];
        }
    }

    
    function updateBalance() external payable inSystem(msg.sender) {
        account[msg.sender].balance += msg.value;
    }

    function sendPackage(
        uint256 index,        // по дню
        address sender,
        address receiver,
        string memory date,
        Type packType,
        ClassType classType,
        uint8 weight,        
        uint256 precious,
        uint256 numberMailTo  //!
        ) external 
        hasRole(msg.sender, Role.Mailer) 
        inSystem(sender) 
        inSystem(receiver)
    {
        uint256 costSum = calculateSumCost(classType,weight,precious);
        require (costSum >= account[sender].balance, "Not enough balance");

        account[sender].balance -= costSum;

        uint256 numberMailFrom = workerToNumber[msg.sender];
        require(numberMailTo != 0, "Wrong number index for receiver mail");

        string memory _trackNumber = string(
            abi.encodePacked(
                "RR", date, index, numberMailFrom, numberMailTo
            )
        );
        trackNumber[_trackNumber] = Package(
            sender, receiver, packType, classType,
            weight, precious, account[sender].realAddress, account[receiver].realAddress
        );
        trackingSystem[_trackNumber] = TrackData(numberMailFrom, weight, 0, block.timestamp);
    }

    /**
     * В каждой точке транзита сотрудник почтового отделения добавляет информацию
     * о почтовом отправлении 
     * (идентификатор отделения, трек-номер отправления, вес отправления). 
     */
    function updatePackage(string memory _trackNumber, uint8 weight) 
        external 
        hasRole(msg.sender, Role.Mailer) 
    {
        TrackData storage trackData = trackingSystem[_trackNumber];
        uint256 currentNumberMail = workerToNumber[msg.sender];
        require(checkIfCanUpdate(trackData.numberMail, currentNumberMail), "Can't be updated");
        require(!isArrived(_trackNumber));
        
        trackData.numberMail = currentNumberMail;
        trackData.updateTimestamp = block.timestamp;
        trackData.weight = weight;
    }

    function receiveDelivery(string memory _trackNumber) external hasRole(msg.sender, Role.Mailer) {

    }

//стоимОтКласса*Вес+ценность*0.1
    function calculateSumCost(ClassType classType, uint8 weight, uint256 precious) 
        public view 
        returns(uint256) 
    {
        uint256 classCost = packageDayCost[classType].ethCost;
        
        return (classCost*weight + precious/10);
    }

// level 1 и level 2 находятся в одной локации 
// (есть связь между mail index lev 1 и lev 2)
// если да => можно updatePackage вызвать сотруднику
    function isLocalL1L2(uint256 numberMail1, uint256 numberMail2) public pure returns(bool) {
        //lev2: index 1, 5, 9, 13 = 4
        //lev1: index lev 2 + 1 or + 2 or + 3
        bool isLocal;
        uint256 levelM1 = getLevel(numberMail1);
        uint256 levelM2 = getLevel(numberMail2);
        if(levelM1 == 1 && levelM2 == 2) {
            if(numberMail1 > numberMail2 && numberMail1 <= numberMail2+3)
                isLocal = true;
        } else if(levelM1 == 2 && levelM2 == 1) {
            if(numberMail2 > numberMail1 && numberMail2 <= numberMail1+3)
                isLocal = true;
        }
        return isLocal;
    }

    function getLevel(uint256 numberMail) public pure returns(uint256) {
        uint256 level = 0;
        if(numberMail == 1 || numberMail == 5 || numberMail == 9 || numberMail == 13)
            level = 2;
        else if(numberMail == 0)
            level = 3;           // Pостов
        else 
            level = 1;
        return level;
    }

    function checkIfCanUpdate(uint256 previousMail, uint256 currentMail) public pure returns(bool) {
        bool canUpdate;
        uint256 levelPrevious = getLevel(previousMail);
        uint256 levelCurrent = getLevel(currentMail);
        if(isLocalL1L2(currentMail, previousMail)) 
            canUpdate = true;
        else if(
            (levelPrevious == 3 && levelCurrent == 2) || 
            (levelPrevious == 2 && levelCurrent == 3)
        )
            canUpdate = true;
        return canUpdate;
    }

    function isArrived(string memory _trackNumber) public view returns(bool) {
        if(
            trackNumber[_trackNumber].addressReceiver.numberMail == 
            trackingSystem[_trackNumber].numberMail && 
            trackingSystem[_trackNumber].updateTimestamp != 0
        )
            return true;
        return false;
    }

}
