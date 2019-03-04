pragma solidity >=0.5.0 <0.6.0;

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return The adjusted transfer amount filtered by a specific token controller.
    function onTokenTransfer(address _from, address _to, uint _amount) public returns(uint);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return The adjusted approve amount filtered by a specific token controller.
    function onTokenApprove(address _owner, address _spender, uint _amount) public returns(uint);
}
