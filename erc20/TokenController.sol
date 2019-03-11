pragma solidity >=0.5.0 <0.6.0;

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _fromBalance Original token balance of _from address
    /// @param _amount The amount of the transfer
    /// @return The adjusted transfer amount filtered by a specific token controller.
    function onTokenTransfer(address _from, uint _fromBalance, uint _amount) public returns(uint);
}
