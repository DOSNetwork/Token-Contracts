pragma solidity >=0.5.0 <0.6.0;

import "./auth.sol";
import "./math.sol";
import "./TokenController.sol";

contract LockdropController is TokenController, DSAuth, DSMath {
    uint public perNodeLockedAmount = 0;
    uint public lockedSupply = 0;
    uint public lockedNode = 0;
    mapping (address => bool) public lockdropList;
    
    event UpdatePerNodeLockedAmount(uint oldAmount, uint newAmount);
    event Lock(address indexed node, uint amount);
    event Release(address indexed node, uint amount);
    
    function setPerNodeLockedAmount(uint amount) public auth {
        require(amount != perNodeLockedAmount);
        emit UpdatePerNodeLockedAmount(perNodeLockedAmount, amount);
        perNodeLockedAmount = amount;
        lockedSupply = mul(perNodeLockedAmount, lockedNode);
    }
    
    function lock(address node) public auth {
        require(!lockdropList[node], "Already in lockdrop list");
        lockdropList[node] = true;
        lockedSupply = add(lockedSupply, perNodeLockedAmount);
        lockedNode = add(lockedNode, 1);
        emit Lock(node, perNodeLockedAmount);
    }
    
    function release(address node) public auth {
        require(lockdropList[node], "Not in lockdrop list");
        delete lockdropList[node];
        lockedSupply = sub(lockedSupply, perNodeLockedAmount);
        lockedNode = sub(lockedNode, 1);
        emit Release(node, perNodeLockedAmount);
    }
    
    /// @notice For address in lockdropList it's only allowed to transfer the amount greater than the perNodeLockedAmount.
    function onTokenTransfer(address _from, uint _fromBalance, uint _amount) public returns(uint) {
        if (lockdropList[_from] && add(_amount, perNodeLockedAmount) > _fromBalance) {
            return 0;
        } else {
            return _amount;
        }
    }
}
