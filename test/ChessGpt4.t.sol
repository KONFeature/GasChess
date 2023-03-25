// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.19;

import {ChessGame} from "../src/ChessGpt4.sol";
import {Test} from "forge-std/Test.sol";

/// @dev Test our chess game gpt4 contract
contract ChessGpt4Test is Test {
    /// @dev White address
    address private white = address(13);

    /// @dev Black address
    address private black = address(12);

    /// @dev The contract we will test
    ChessGame private chessGame;

    function setUp() public {
        // create the initial game, 13 white player, 12 black player
        chessGame = new ChessGame(white, black);
    }

    /* -------------------------------------------------------------------------- */
    /*                   Simple and initial board movement test                   */
    /* -------------------------------------------------------------------------- */

    function test_pawnMove() public {
        // White pawn to e4
        vm.prank(white);
        chessGame.move(1, 4, 3, 4, ChessGame.PieceType.Queen);
        // Black pawn to e5
        vm.prank(black);
        chessGame.move(6, 4, 5, 4, ChessGame.PieceType.Queen);
        // White queen to h4
        vm.prank(white);
        chessGame.move(0, 3, 4, 7, ChessGame.PieceType.Queen);
        // Black knight to f5
        // TODO : Variant with king to e7
        vm.prank(black);
        chessGame.move(7, 6, 5, 5, ChessGame.PieceType.Queen);
        // White bishop to b4
        vm.prank(white);
        chessGame.move(0, 5, 1, 4, ChessGame.PieceType.Queen);
        // Black pawn to d6
        vm.prank(black);
        chessGame.move(6, 3, 5, 3, ChessGame.PieceType.Queen);
        // White queen to f7 -> checkmate
        vm.prank(white);
        chessGame.move(4, 7, 6, 5, ChessGame.PieceType.Queen);
    }
}

/*

   _______________
8 |r|n|b|q|k|b|n|r|
7 |p|p|p|p|p|p|p|p|
6 |_|#|_|#|_|#|_|#|
5 |#|_|#|_|#|_|#|_|
4 |_|#|_|#|_|#|_|#|
3 |#|_|#|_|#|_|#|_|
2 |p|p|p|p|p|p|p|p|
1 |r|n|b|q|k|b|n|r|
   a b c d e f g h
   _______________
7 |r|n|b|q|k|b|n|r|
6 |p|p|p|_|_|q|p|p|
5 |_|#|_|p|_|#|_|#|
4 |#|_|#|_|p|_|#|_|
3 |_|#|b|#|p|#|_|#|
2 |#|_|#|_|#|_|#|_|
1 |p|p|p|p|_|p|p|p|
0 |r|n|b|_|k|_|n|r|
   0 1 2 3 4 5 6 7



*/
