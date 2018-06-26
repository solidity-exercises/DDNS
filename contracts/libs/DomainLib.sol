pragma solidity ^0.4.23;

library DomainLib {
    struct DomainInfo {
        address owner;
        uint expires;
        bytes4 ip;
    }

    function exists(DomainInfo storage _self) public view returns (bool) {
        return _self.ip != 0;
    }

    function getOwner(DomainInfo storage _self) public view returns (address) {
        return _self.owner;
    }

    function changeOwner(DomainInfo storage _self, address _owner) public {
        _self.owner = _owner;
    }

    function changeIp(DomainInfo storage _self, bytes4 _ip) public {
        _self.ip = _ip;
    }

    function extendExpiry(DomainInfo storage _self) public {
        _self.expires += 365 days;
    }

    function hasExpired(DomainInfo storage _self) public view returns (bool) {
        return now > _self.expires;
    }
}