
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/ItokenURIEngine.sol";
abstract contract TokenURISetting {

    event CallSetTokenURIEngine(address tokenURIEngine);
    address private _tokenURIEngine;

    /// @dev set tokenURIEngine's address.
    function _setTokenURIEngine(address tokenURIEngine_) internal {
        _tokenURIEngine = tokenURIEngine_;
        emit CallSetTokenURIEngine(tokenURIEngine_);
    }
    /// @dev TokenURIEngine's address.
    function getTokenURIEngine() public view returns(address){
        return _tokenURIEngine;
    }

    function tokenURIEngine() internal view returns(ItokenURIEngine) {
        require(_tokenURIEngine != address(0), "tokenURIEngine is not set");
        return ItokenURIEngine(_tokenURIEngine);
    }
}
