pragma solidity >=0.5.0 <0.6.0;

contract Managed {
    /// @notice The address of the manager is the only address that can call
    ///  a function with this modifier
    modifier onlyManager { require(msg.sender == manager); _; }

    address public manager;

    constructor() public { manager = msg.sender;}

    /// @notice Changes the manager of the contract
    /// @param _newManager The new manager of the contract
    function changeManager(address _newManager) public onlyManager {
        manager = _newManager;
    }
    
    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) view internal returns(bool) {
        uint size = 0;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
