pragma solidity ^0.4.18;

import './Ownable.sol';

contract Destructible is Ownable {
	function destroy() onlyOwner public {
		selfdestruct(msg.sender);
	}

	function destroyAndSend(address _recipient) onlyOwner public {
		require(_recipient != address(0));
		selfdestruct(_recipient);
	}
}