// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Fund is ERC1155, ReentrancyGuard, Ownable {
	uint256 constant private _TOKENID = 0;

	uint256 public TOTAL_SUPPLY;
	uint256 public OWNER_SUPPLY;
	uint256 public MIN_FUNDING;
	uint256 public TOTAL_FUNDING;
	uint256 public FUNDING_END;

	mapping(address => uint256) private _FUNDERS;

	constructor(uint256 total_supply, uint256 owner_supply, uint256 min_funding, uint256 funding_end) ERC1155("") {
		require(total_supply >= owner_supply);
		TOTAL_SUPPLY = total_supply;
		OWNER_SUPPLY = owner_supply;
		MIN_FUNDING = min_funding;
		FUNDING_END = funding_end;
	}

	function fund() external payable nonReentrant {
		require(msg.value > 0, "Value zero");
		require(block.timestamp < FUNDING_END, "Funding closed");
		_FUNDERS[msg.sender] += msg.value;
		TOTAL_FUNDING += msg.value;
	}

	function mint(
		address to
	) external nonReentrant {
		require(block.timestamp >= FUNDING_END, "Still funding");
		require(TOTAL_FUNDING >= MIN_FUNDING, "Min funding not reached");
		uint256 count = _FUNDERS[msg.sender] * (TOTAL_SUPPLY - OWNER_SUPPLY) / TOTAL_FUNDING;
		_mint(to, _TOKENID, count, bytes(""));
	}

	function claimRefund(
		address to
	) external nonReentrant {
		require(block.timestamp >= FUNDING_END, "Still funding");
		require(TOTAL_FUNDING < MIN_FUNDING, "No refunds, min funding reached");
		uint256 amount = _FUNDERS[msg.sender];
		require(amount > 0, "Nothing to refund");
		_withdraw(to, amount);
		_FUNDERS[msg.sender] = 0;
	}

	function withdrawAll(
		address to
	) external nonReentrant onlyOwner {
		require(block.timestamp >= FUNDING_END, "Still funding");
		require(TOTAL_FUNDING >= MIN_FUNDING, "Min funding not reached");
		uint256 amount = address(this).balance;
		require(amount > 0, "Nothing to withdraw");
		_withdraw(to, amount);
	}

	function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }	
}
