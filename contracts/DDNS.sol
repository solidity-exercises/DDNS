pragma solidity ^0.4.23;

import './abstractions/DDNSTemplate.sol';
import './common/Destructible.sol';
import './libs/DomainLib.sol';

contract DDNS is DDNSTemplate, Destructible {
    using DomainLib for DomainLib.DomainInfo;

    uint public constant REGISTRATION_FEE = 1 ether;
    uint public constant MIN_DOMAIN_NAME_LENGTH = 5;

    event LogReceipt(address owner, bytes domainName, uint payment, uint expiration);
    event LogRegisteredNewDomain(bytes domain, bytes4 ip, address owner);
    event LogTransferOwnership(bytes domain, address newOwner);
    event LogDomainEdit(bytes domain, bytes4 ip);
    event LogExtension(bytes domain);
    event LogWithdrawal();    

    mapping (address=>Receipt[]) public receipts;
    mapping (bytes=>DomainLib.DomainInfo) domains;

    modifier isValidOwnedDomain(bytes _domain) {
        require(domains[_domain].exists());
        require(domains[_domain].getOwner() == msg.sender);
        require(!domains[_domain].hasExpired());
        _;
    }

    // register function is used to both extend owned domain expiration date or purchase a new domain
    function register(bytes _domain, bytes4 _ip) public payable {
        require(_domain.length > MIN_DOMAIN_NAME_LENGTH);
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
            _newReceipt(msg.sender, msg.value, domain.expires, _domain);

            emit LogExtension(_domain);
        } else {
            require(domain.hasExpired());

            domain.changeOwner(msg.sender);
            domain.changeIp(_ip);
            domain.resetExpiry();
            _newReceipt(msg.sender, msg.value, domain.expires, _domain);

            emit LogRegisteredNewDomain(_domain, _ip, msg.sender);
        }
    }
    
    function edit(bytes _domain, bytes4 _newIp) public isValidOwnedDomain(_domain) {        
        emit LogDomainEdit(_domain, _newIp);

        domains[_domain].changeIp(_newIp);
    }
    
    function transferDomain(bytes _domain, address _newOwner) public isValidOwnedDomain(_domain) {
        require(_newOwner != address(0));

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
        require(_domain.length > MIN_DOMAIN_NAME_LENGTH);
        return REGISTRATION_FEE + _domain.length * (100 finney);
    }

    function _newReceipt(address _recepient, uint _payment, uint _expiration, bytes _domainName) private {
        receipts[_recepient].push(Receipt({amountPaidWei: _payment, expires: _expiration, timestamp: now}));

        emit LogReceipt(_recepient, _domainName, _payment, _expiration);
    }
}