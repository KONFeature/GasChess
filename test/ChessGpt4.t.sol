// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.19;

import {ChessGame} from "../src/ChessGpt4.sol";
import {Test} from "forge-std/Test.sol";

/// @dev Test our chess game gpt4 contract
contract ChessGpt4Test is Test {
    /// @dev The contract we will test
    ChessGame private chessGame;

    function setUp() public {
        // create the initial game, 13 white player, 12 black player
        chessGame = new ChessGame(address(13), address(12));
    }
}
