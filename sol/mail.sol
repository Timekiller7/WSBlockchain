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
        bool rejected;
    }
    mapping(string => TrackData) public trackingSystem;
    mapping(string => Package) public trackNumber;

    mapping(address => uint256) public workerToNumber;
    mapping(uint256 => uint256) public numberToMailIndex;  // numMail => realIndex

    event PackageReceived(string indexed trackNumber);

    constructor(uint256[17] memory mailIndexes) {
        packageDayCost[ClassType.First] = PackageDayCost(5, 0.5 ether);
        packageDayCost[ClassType.Second] = PackageDayCost(10, 0.3 ether);
        packageDayCost[ClassType.Third] = PackageDayCost(15, 0.1 ether);

        uint256 i;
        for(i = 0; i < 17; i ++) {
            numberToMailIndex[i] = mailIndexes[i];
        }

        account[address(this)].role = Role.System;
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
        uint256 precious
        ) external 
        hasRole(msg.sender, Role.Mailer) 
        inSystem(sender) 
        inSystem(receiver)
    {
        uint256 costSum = calculateSumCost(classType,weight,precious);
        require (costSum >= account[sender].balance, "Not enough balance");

        account[sender].balance -= costSum;

        uint256 numberMailFrom = workerToNumber[msg.sender];
        uint256 numberMailTo = account[receiver].realAddress.numberMail;

        string memory _trackNumber = string(
            abi.encodePacked(
                "RR", date, index, numberMailFrom, numberMailTo
            )
        );

        require(trackNumber[_trackNumber].sender == address(0), "Double sending");

        trackNumber[_trackNumber] = Package(
            sender, receiver, packType, classType,
            weight, precious, account[sender].realAddress, account[receiver].realAddress
        );
        trackingSystem[_trackNumber] = TrackData(numberMailFrom, weight, 0, block.timestamp, false);
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
        require(weight <= 10, "Weight exceeds limit");

        TrackData storage trackData = trackingSystem[_trackNumber];
        uint256 currentNumberMail = workerToNumber[msg.sender];
        require(checkIfCanUpdate(trackData.numberMail, currentNumberMail), "Can't be updated");
        require(!isArrived(_trackNumber));

        trackData.numberMail = currentNumberMail;
        trackData.updateTimestamp = block.timestamp;
        trackData.weight = weight;

// Кейс №4
        if(isArrived(_trackNumber)) {
            emit PackageReceived(_trackNumber);
        }
    }

// Кейс №2
    function payBackForUnReceivedDelivery(string memory _trackNumber) external hasRole(msg.sender, Role.User) {
        // not if was rejected
        require(trackNumber[_trackNumber].sender != address(this));

        ClassType classType =  trackNumber[_trackNumber].classType;
        // просрочено обновление посылки
        require(trackingSystem[_trackNumber].updateTimestamp > trackingSystem[_trackNumber].originalTimestamp + packageDayCost[classType].deliverDays);
        
        uint256 precious = trackNumber[_trackNumber].precious;
        uint256 originalSumCost = calculateSumCost(classType, trackNumber[_trackNumber].weight, precious);
        
        if(classType == ClassType.First) {
            _claimFunds(msg.sender, originalSumCost);
        } else if (classType == ClassType.Second) {
            _claimFunds(msg.sender, originalSumCost/2 + precious);
        } else {
            _claimFunds(msg.sender, precious);
        }
    }

// Kейс №3
    function PackageReceivedByUser(string memory _trackNumber) external hasRole(msg.sender, Role.Mailer) {
        require(trackingSystem[_trackNumber].updateTimestamp + 14 days >= block.timestamp);
        
        // проверка на то что именно это почт отделение получило посылку => может распоряжаться ею
        uint256 numberMailFrom = workerToNumber[msg.sender];
        require(isArrived(_trackNumber) && trackingSystem[_trackNumber].numberMail == numberMailFrom);


        // however we can our tracks are remained, we can iterate through events 
        delete trackNumber[_trackNumber];
        delete trackingSystem[_trackNumber];
    }

//Кейс 3,4

    // by receiver
    function rejectPackage(string memory _trackNumber) external {
        require(!trackingSystem[_trackNumber].rejected);

        Package memory package = trackNumber[_trackNumber];
        uint8 originalWeight = package.weight;
        uint8 receivedWeight = trackingSystem[_trackNumber].weight;

        if(receivedWeight > (originalWeight*115)/100 || receivedWeight < (originalWeight*115)/100) {
            require(package.receiver == msg.sender);
            trackingSystem[_trackNumber].rejected = true;
            _claimFunds(package.sender, calculateSumCost(package.classType, originalWeight, package.precious));
        }
    }

    function sendPackageBackCommon(string memory _trackNumber, string memory date, uint256 index) external {
        if(!trackingSystem[_trackNumber].rejected) {
            require(trackingSystem[_trackNumber].updateTimestamp + 14 days >= block.timestamp);
        } 

        sendPackageBack(_trackNumber, date, index);
    }
    


    function sendPackageBack(string memory _trackNumber, string memory date, uint256 index) private hasRole(msg.sender, Role.Mailer) {
        uint256 numberMailFrom = workerToNumber[msg.sender];
        require(isArrived(_trackNumber) && trackingSystem[_trackNumber].numberMail == numberMailFrom);

        Package memory oldPackage = trackNumber[_trackNumber];
        uint256 numberMailTo = account[oldPackage.receiver].realAddress.numberMail;
        
        string memory newTrackNumber = string(
            abi.encodePacked(
                "RR", date, index, numberMailFrom, numberMailTo
            )
        );
        require(trackNumber[newTrackNumber].sender == address(0), "Double sending");

        trackNumber[newTrackNumber] = Package(
            address(this), oldPackage.sender,
            oldPackage.packType, oldPackage.classType,
            trackingSystem[_trackNumber].weight, oldPackage.precious,
            RealAddress(0,"","",""), oldPackage.addressSender
        );
        trackingSystem[newTrackNumber] = TrackData(numberMailFrom,  trackingSystem[_trackNumber].weight, 0, block.timestamp, false);

        delete trackNumber[_trackNumber];
        delete trackingSystem[_trackNumber];
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
