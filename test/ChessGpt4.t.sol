// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.19;

import {ChessGame} from "../src/ChessGpt4.sol";
import {Test} from "forge-std/Test.sol";

/*
Initial gas report
| src/ChessGpt4.sol:ChessGame contract |                 |          |         |           |         |
|--------------------------------------|-----------------|----------|---------|-----------|---------|
| Deployment Cost                      | Deployment Size |          |         |           |         |
| 2244415                              | 8781            |          |         |           |         |
| Function Name                        | min             | avg      | median  | max       | # calls |
| move                                 | 6562627         | 38071369 | 9163587 | 206254350 | 7       |


=== Inital impl ===
v0 report : 
| move                                 | 6562627         | 38071369 | 9163587 | 206254350 | 7       |
ChessGpt4Test:test_pawnMove() (gas: 266518868)

=== Remove signed integer usage ===
v1 report :
| move                                 | 3581063         | 23099337 | 8736953 | 163719332 | 20      |
ChessGpt4Test:test_enPassantMate() (gas: 31419860)
ChessGpt4Test:test_foolsMate() (gas: 177526823)
ChessGpt4Test:test_pawnCapture() (gas: 29647345)
ChessGpt4Test:test_scholarsMate() (gas: 223461123) -> Was test_pawnMove

 */

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

    function test_scholarsMate() public {
        // White pawn to e4
        vm.prank(white);
        chessGame.move(1, 4, 3, 4, ChessGame.PieceType.Queen);
        // Black pawn to e5
        vm.prank(black);
        chessGame.move(6, 4, 4, 4, ChessGame.PieceType.Queen);
        // White queen to h4
        vm.prank(white);
        chessGame.move(0, 3, 4, 7, ChessGame.PieceType.Queen);
        // Black knight to f5
        vm.prank(black);
        chessGame.move(7, 6, 5, 5, ChessGame.PieceType.Queen);
        // White bishop to b4
        vm.prank(white);
        chessGame.move(0, 5, 3, 2, ChessGame.PieceType.Queen);
        // Black pawn to d6
        vm.prank(black);
        chessGame.move(6, 3, 5, 3, ChessGame.PieceType.Queen);
        // White queen to f7 -> checkmate
        vm.prank(white);
        chessGame.move(4, 7, 6, 5, ChessGame.PieceType.Queen);
    }

    function test_foolsMate() public {
        // White pawn to f3
        vm.prank(white);
        chessGame.move(1, 5, 2, 5, ChessGame.PieceType.Queen);
        // Black pawn to e5
        vm.prank(black);
        chessGame.move(6, 4, 4, 4, ChessGame.PieceType.Queen);
        // White pawn to g4
        vm.prank(white);
        chessGame.move(1, 6, 3, 6, ChessGame.PieceType.Queen);
        // Black queen to h4 -> checkmate
        vm.prank(black);
        chessGame.move(7, 3, 3, 7, ChessGame.PieceType.Queen);
    }

    function test_pawnCapture() public {
        // White pawn to e4
        vm.prank(white);
        chessGame.move(1, 4, 3, 4, ChessGame.PieceType.Queen);
        // Black pawn to e5
        vm.prank(black);
        chessGame.move(6, 4, 4, 4, ChessGame.PieceType.Queen);
        // White pawn to d4
        vm.prank(white);
        chessGame.move(1, 3, 3, 3, ChessGame.PieceType.Queen);
        // Black pawn to e4
        vm.prank(black);
        chessGame.move(4, 4, 3, 3, ChessGame.PieceType.Queen); // En passant capture
    }

    function test_enPassantMate() public {
        // White pawn to e4
        vm.prank(white);
        chessGame.move(1, 4, 3, 4, ChessGame.PieceType.Queen);
        // Black pawn to a5
        vm.prank(black);
        chessGame.move(6, 0, 4, 0, ChessGame.PieceType.Queen);
        // White pawn to e5
        vm.prank(white);
        chessGame.move(3, 4, 4, 4, ChessGame.PieceType.Queen);
        // Black pawn to d5
        vm.prank(black);
        chessGame.move(6, 3, 4, 3, ChessGame.PieceType.Queen);
        // White pawn to d7 -> en passant
        vm.prank(white);
        chessGame.move(4, 4, 5, 3, ChessGame.PieceType.Queen);
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
x  _______________
7 |r|n|b|q|k|b|n|r|
6 |p|p|p|_|_|q|p|p|
5 |_|#|_|p|_|#|_|#|
4 |#|_|#|_|p|_|#|_|
3 |_|#|b|#|p|#|_|#|
2 |#|_|#|_|#|_|#|_|
1 |p|p|p|p|_|p|p|p|
0 |r|n|b|_|k|_|n|r|
   0 1 2 3 4 5 6 7 y



*/
