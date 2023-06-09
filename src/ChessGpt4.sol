// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.19;

/// @dev v1 of the contract, remove usage of signed integers
contract ChessGame {
    enum PieceType {
        Empty,
        Pawn,
        Knight,
        Bishop,
        Rook,
        Queen,
        King
    }
    enum Player {
        None,
        White,
        Black
    }

    struct Piece {
        PieceType pieceType;
        Player player;
    }

    address public whitePlayer;
    address public blackPlayer;

    Piece[64] board;

    // The last move on X and Y axis
    uint8[2] lastMove;

    Player public currentPlayer = Player.White;
    bool public gameEnded = false;

    event Move(address indexed player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY);
    event GameOver(Player targetPlayer);

    constructor(address _whitePlayer, address _blackPlayer) {
        whitePlayer = _whitePlayer;
        blackPlayer = _blackPlayer;

        // Initialize the board with the starting positions
        // Set up white pieces
        board[index(0, 0)] = board[index(0, 7)] = Piece(PieceType.Rook, Player.White);
        board[index(0, 1)] = board[index(0, 6)] = Piece(PieceType.Knight, Player.White);
        board[index(0, 2)] = board[index(0, 5)] = Piece(PieceType.Bishop, Player.White);
        board[index(0, 3)] = Piece(PieceType.Queen, Player.White);
        board[index(0, 4)] = Piece(PieceType.King, Player.White);

        // Set up white pawns
        for (uint8 i; i < 8;) {
            board[index(1, i)] = Piece(PieceType.Pawn, Player.White);
            unchecked {
                ++i;
            }
        }

        // Set up black pieces
        board[index(7, 0)] = board[index(7, 7)] = Piece(PieceType.Rook, Player.Black);
        board[index(7, 1)] = board[index(7, 6)] = Piece(PieceType.Knight, Player.Black);
        board[index(7, 2)] = board[index(7, 5)] = Piece(PieceType.Bishop, Player.Black);
        board[index(7, 3)] = Piece(PieceType.Queen, Player.Black);
        board[index(7, 4)] = Piece(PieceType.King, Player.Black);

        // Set up black pawns
        for (uint8 i; i < 8;) {
            board[index(6, i)] = Piece(PieceType.Pawn, Player.Black);
            unchecked {
                ++i;
            }
        }
    }

    function move(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, PieceType promotionPiece) external {
        require(!gameEnded, "Game has already ended.");
        require(validPlayer(fromX, fromY), "Invalid player.");

        Piece memory piece = board[index(fromX, fromY)];
        Player _currentPlayer = currentPlayer;
        require(validMove(_currentPlayer, piece, fromX, fromY, toX, toY), "Invalid move.");

        applyMove(fromX, fromY, toX, toY, promotionPiece);

        // Update the player o
        Player targetPlayer = _currentPlayer == Player.White ? Player.Black : Player.White;
        currentPlayer = targetPlayer;

        // Check if that's a game over for the given player
        if (isGameOver(targetPlayer)) {
            gameEnded = true;
            emit GameOver(targetPlayer);
            return;
        }
    }

    function validPlayer(uint8 x, uint8 y) internal view returns (bool) {
        return msg.sender == getSenderForPlayer(currentPlayer) && board[index(x, y)].player == currentPlayer;
    }

    /// @dev Check if the given move is valid for the given `player` and `piece`
    function validMove(Player player, Piece memory piece, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        returns (bool)
    {
        // Check that the move is within bounds
        if (toX > 7 || toY > 7) {
            return false;
        }

        // Ensure the piece belongs to the current player
        if (piece.player != player) {
            return false;
        }

        // Check that the destination square is either empty or occupied by an opponent's piece
        if (board[index(toX, toY)].player == player) {
            return false;
        }

        // Ensure the move doesn't leave the king in check
        if (moveLeavesKingInCheck(player, fromX, fromY, toX, toY)) {
            return false;
        }

        // Check the piece movment validity
        return validMoveForPiece(player, piece, fromX, fromY, toX, toY);
    }

    /// @dev Check if the given move is valid for the given `player` and `piece`, only check for the piece ovment, not check
    function validMoveForPiece(Player player, Piece memory piece, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        returns (bool)
    {
        // Implement move validation logic for each piece type
        if (piece.pieceType == PieceType.Pawn) {
            return validPawnMove(player, fromX, fromY, toX, toY);
        } else if (piece.pieceType == PieceType.Rook) {
            return validRookMove(fromX, fromY, toX, toY);
        } else if (piece.pieceType == PieceType.Bishop) {
            return validBishopMove(fromX, fromY, toX, toY);
        } else if (piece.pieceType == PieceType.Knight) {
            return validKnightMove(fromX, fromY, toX, toY);
        } else if (piece.pieceType == PieceType.Queen) {
            return validQueenMove(fromX, fromY, toX, toY);
        } else if (piece.pieceType == PieceType.King) {
            return validKingMove(fromX, fromY, toX, toY);
        }
        return false;
    }

    function validPawnMove(Player player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal returns (bool) {
        // Ensure the value are right, we need position direction for the given player
        if (player == Player.White && fromX > toX) {
            return false;
        } else if (player == Player.Black && fromX < toX) {
            return false;
        }

        // Get distance
        uint8 distanceX = fromX > toX ? fromX - toX : toX - fromX;

        if (fromY == toY) {
            // Same Y, just 1 distance, ok
            if (distanceX == 1 && board[index(toX, toY)].player == Player.None) {
                return true;
            }
            // Same Y, 2 distance from start line
            if (((player == Player.White && fromX == 1) || (player == Player.Black && fromX == 6)) && distanceX == 2) {
                return true;
            }
        } else {
            uint8 yDiff = fromY > toY ? fromY - toY : toY - fromY;
            if (yDiff == 1 && distanceX == 1) {
                // Check for capture
                if (board[index(toX, toY)].player != Player.None) {
                    return true;
                }
                if (isEnPassantCapture(player, fromX, fromY, toX, toY)) {
                    return true;
                }
            }
        }

        return false;
    }

    function isEnPassantCapture(Player player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        returns (bool)
    {
        if ((player == Player.White && fromX == 4) || (player == Player.Black && fromX == 3)) {
            uint8 targetX = player == Player.White ? toX - 1 : toX + 1;
            if (lastMove[0] == targetX && lastMove[1] == toY) {
                Piece memory capturedPawn = board[index(targetX, toY)];
                bool isEnPassant = capturedPawn.pieceType == PieceType.Pawn && capturedPawn.player != player;
                // If that's an en passant capture, reset the position
                if (isEnPassant) {
                    board[index(targetX, toY)] = Piece(PieceType.Empty, Player.None);
                }
                return isEnPassant;
            }
        }
        return false;
    }

    function validRookMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal view returns (bool) {
        // If same column exit
        if (fromX != toX && fromY != toY) {
            return false;
        } else if (fromX != toX) {
            // x column movment check
            uint8 x = fromX;
            while (x <= toX) {
                x = fromX > toX ? x - 1 : x + 1;

                if (x == toX) {
                    return true;
                }
                if (board[index(x, fromY)].player != Player.None) {
                    return false;
                }
            }
        } else if (fromY != toY) {
            // y column movment check
            uint8 y = fromY;

            while (y <= toY) {
                y = fromY > toY ? y - 1 : y + 1;
                if (y == toY) {
                    return true;
                }
                if (board[index(fromX, y)].player != Player.None) {
                    return false;
                }
            }
        }

        return false;
    }

    function validBishopMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal view returns (bool) {
        uint8 distanceX = fromX > toX ? fromX - toX : toX - fromX;
        uint8 distanceY = fromY > toY ? fromY - toY : toY - fromY;

        if (distanceX != distanceY) {
            return false;
        }

        bool xIncreasing = fromX < toX;
        bool yIncreasing = fromY < toY;

        uint8 x = xIncreasing ? fromX + 1 : fromX - 1;
        uint8 y = yIncreasing ? fromY + 1 : fromY - 1;

        while (x != toX && y != toY) {
            if (board[index(x, y)].player != Player.None) {
                return false;
            }
            x = xIncreasing ? x + 1 : x - 1;
            y = yIncreasing ? y + 1 : y - 1;
        }

        return true;
    }

    function validKnightMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal pure returns (bool) {
        uint8 xDiff = fromX > toX ? fromX - toX : toX - fromX;
        uint8 yDiff = fromY > toY ? fromY - toY : toY - fromY;

        return (xDiff == 2 && yDiff == 1) || (xDiff == 1 && yDiff == 2);
    }

    function validQueenMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal view returns (bool) {
        return validRookMove(fromX, fromY, toX, toY) || validBishopMove(fromX, fromY, toX, toY);
    }

    function validKingMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal pure returns (bool) {
        uint8 xDiff = toX > fromX ? toX - fromX : fromX - toX;
        uint8 yDiff = toY > fromY ? toY - fromY : fromY - toY;

        return (xDiff <= 1) && (yDiff <= 1);
    }

    function moveLeavesKingInCheck(Player player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        returns (bool)
    {
        // Create a temporary board to test the move
        Piece[64] memory tempBoard = board;

        // Apply the move on the temporary board
        tempBoard[index(toX, toY)] = tempBoard[index(fromX, fromY)];
        tempBoard[index(fromX, fromY)] = Piece(PieceType.Empty, Player.None);

        // Find the king's position for the current player
        (uint8 kingX, uint8 kingY) = _findKingPositionOnBoard(tempBoard, player);

        // Check if any of the opponent's pieces can capture the king
        Player opponentPlayer = player == Player.White ? Player.Black : Player.White;
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (tempBoard[idx].player == opponentPlayer) {
                    (uint8 x, uint8 y) = position(idx);
                    if (validMoveForPiece(opponentPlayer, tempBoard[idx], x, y, kingX, kingY)) {
                        return true;
                    }
                }
                ++idx;
            }
        }

        return false;
    }

    function applyMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, PieceType promotionPiece) internal {
        Piece memory piece = board[index(fromX, fromY)];

        // Check for pawn promotion
        if (piece.pieceType == PieceType.Pawn) {
            if ((piece.player == Player.White && toY == 7) || (piece.player == Player.Black && toY == 0)) {
                require(
                    promotionPiece == PieceType.Queen || promotionPiece == PieceType.Rook
                        || promotionPiece == PieceType.Bishop || promotionPiece == PieceType.Knight,
                    "Invalid promotion piece"
                );
                piece.pieceType = promotionPiece;
            }
        }

        // Update the pieces
        board[index(toX, toY)] = piece;
        board[index(fromX, fromY)] = Piece(PieceType.Empty, Player.None);

        // Update the last move
        lastMove[0] = toX;
        lastMove[1] = toY;

        emit Move(msg.sender, fromX, fromY, toX, toY);
    }

    /// @dev Check if it's a game over for the given player
    function isGameOver(Player forPlayer) internal returns (bool) {
        bool kingInCheck = false;
        // Find the king's position for the current player
        (uint8 kingX, uint8 kingY) = _findKingPosition(forPlayer);

        // Get the opponent player for move validation
        Player oppponentPlayer = forPlayer == Player.White ? Player.Black : Player.White;

        // Check if the king is in check
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (board[idx].player == oppponentPlayer) {
                    (uint8 x, uint8 y) = position(idx);
                    if (validMove(oppponentPlayer, board[idx], x, y, kingX, kingY)) {
                        kingInCheck = true;
                        break;
                    }
                }
                ++idx;
            }
        }

        if (!kingInCheck) {
            // Check for a draw
            return isDraw(forPlayer);
        }

        // Check if there are any legal moves left for the current player
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (board[idx].player == forPlayer) {
                    for (uint256 newIdx = 0; newIdx < 64;) {
                        (uint8 x, uint8 y) = position(idx);
                        (uint8 newX, uint8 newY) = position(newIdx);
                        if (validMove(forPlayer, board[idx], x, y, newX, newY)) {
                            return false;
                        }
                        ++newIdx;
                    }
                }
                ++idx;
            }
        }

        // If there are no legal moves left and the king is in check, it's checkmate
        return true;
    }

    function isDraw(Player forPlayer) internal returns (bool) {
        // Check if there are any legal moves left for the current player
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (board[idx].player == currentPlayer) {
                    for (uint256 newIdx = 0; newIdx < 64;) {
                        (uint8 x, uint8 y) = position(idx);
                        (uint8 newX, uint8 newY) = position(newIdx);
                        if (validMove(forPlayer, board[idx], x, y, newX, newY)) {
                            return false;
                        }
                        ++newIdx;
                    }
                }
                ++idx;
            }
        }

        // If we reached here, no legal move for the given player
        return true;
    }

    function getSenderForPlayer(Player player) internal view returns (address) {
        // Implement logic to get the appropriate player's address
        if (player == Player.White) {
            return whitePlayer;
        } else if (player == Player.Black) {
            return blackPlayer;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                       Internal pure helper function's                      */
    /* -------------------------------------------------------------------------- */

    /// @dev Find the king position in the given `_board`for the given `_player`
    /// @return x The king's `x`  position
    /// @return y The king's `y` position
    function _findKingPositionOnBoard(Piece[64] memory _board, Player _player)
        internal
        pure
        returns (uint8 x, uint8 y)
    {
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (_board[idx].player == _player && _board[idx].pieceType == PieceType.King) {
                    return position(idx);
                }
                ++idx;
            }
        }
    }

    /// @dev Find the king position in the given `_board`for the given `_player`
    /// @return x The king's `x`  position
    /// @return y The king's `y` position
    function _findKingPosition(Player _player) internal view returns (uint8 x, uint8 y) {
        unchecked {
            for (uint256 idx = 0; idx < 64;) {
                if (board[idx].player == _player && board[idx].pieceType == PieceType.King) {
                    return position(idx);
                }
                ++idx;
            }
        }
    }

    /// @dev Generate an array index from the `x`and `y`chess position
    function index(uint256 x, uint256 y) internal pure returns (uint256 idx) {
        unchecked {
            idx = x * 8 + y;
        }
    }

    /// @dev Get a chess position from the array index
    function position(uint256 idx) internal pure returns (uint8 x, uint8 y) {
        unchecked {
            x = uint8(idx / 8);
            y = uint8(idx % 8);
        }
    }
}
