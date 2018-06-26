pragma solidity ^0.4.23;

import './abstractions/DDNSTemplate.sol';
import './common/Destructible.sol';
import './libs/DomainLib.sol';

contract DDNS is DDNSTemplate, Destructible {
    using DomainLib for DomainLib.DomainInfo;

    uint public constant REGISTRATION_FEE = 1 ether;

    event LogRegisteredNewDomain(bytes domain, bytes4 ip, address owner);
    event LogDomainEdit(bytes domain, bytes4 ip);
    event LogExtension(bytes domain);
    event LogTransferOwnership(bytes domain, address newOwner);
    event LogWithdrawal();    

    mapping (address=>Receipt[]) public receipts;
    mapping (bytes=>DomainLib.DomainInfo) domains;

    function register(bytes _domain, bytes4 _ip) public payable {
        require(_domain.length > 5);
        require(_ip != 0);

        DomainLib.DomainInfo storage domain = domains[_domain];

        uint price;
        bool isExtending = false;

        if (domain.exists() && !domain.hasExpired()) {
            require(msg.sender == domain.getOwner());
            price = REGISTRATION_FEE;
            isExtending = true;
        } else {
            price = getPrice(_domain);
        }

        require(msg.value >= price);

        if (isExtending) {
            domain.extendExpiry();
            receipts[domain.getOwner()].push(Receipt({amountPaidWei: msg.value, expires: now + 365 days, timestamp: now}));

            emit LogExtension(_domain);
        } else {
            require(domain.hasExpired());

            domain.owner = msg.sender;
            domain.ip = _ip;
            domain.expires = now + 365 days;
            receipts[domain.getOwner()].push(Receipt({amountPaidWei: msg.value, expires: now + 365 days, timestamp: now}));

            emit LogRegisteredNewDomain(_domain, _ip, msg.sender);
        }
    }
    
    function edit(bytes _domain, bytes4 _newIp) public {
        require(domains[_domain].exists());
        require(domains[_domain].getOwner() == msg.sender);
        require(!domains[_domain].hasExpired());
        
        domains[_domain].changeIp(_newIp);

        emit LogDomainEdit(_domain, _newIp);
    }
    
    function transferDomain(bytes _domain, address _newOwner) public {
        require(_newOwner != address(0));
        require(domains[_domain].exists());
        require(domains[_domain].getOwner() == msg.sender);
        require(!domains[_domain].hasExpired());

        emit LogTransferOwnership(_domain, _newOwner);

        domains[_domain].changeOwner(_newOwner);
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0);

        emit LogWithdrawal();

        owner.transfer(address(this).balance);
    }

    function getIP(bytes _domain) public view returns (bytes4) {
        require(domains[_domain].exists());

        return domains[_domain].ip;
    }
    
    function getPrice(bytes _domain) public view returns (uint) {
        require(_domain.length > 5);
        return REGISTRATION_FEE + _domain.length * (100 finney);
    }
}