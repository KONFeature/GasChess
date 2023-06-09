// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.19;

/// @dev v0 of the contract, original implementation of gpt4 with a few fixes
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

    Piece[8][8] board;

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
        board[0][0] = board[0][7] = Piece(PieceType.Rook, Player.White);
        board[0][1] = board[0][6] = Piece(PieceType.Knight, Player.White);
        board[0][2] = board[0][5] = Piece(PieceType.Bishop, Player.White);
        board[0][3] = Piece(PieceType.Queen, Player.White);
        board[0][4] = Piece(PieceType.King, Player.White);

        // Set up white pawns
        for (uint8 i = 0; i < 8; i++) {
            board[1][i] = Piece(PieceType.Pawn, Player.White);
        }

        // Set up black pieces
        board[7][0] = board[7][7] = Piece(PieceType.Rook, Player.Black);
        board[7][1] = board[7][6] = Piece(PieceType.Knight, Player.Black);
        board[7][2] = board[7][5] = Piece(PieceType.Bishop, Player.Black);
        board[7][3] = Piece(PieceType.Queen, Player.Black);
        board[7][4] = Piece(PieceType.King, Player.Black);

        // Set up black pawns
        for (uint8 i = 0; i < 8; i++) {
            board[6][i] = Piece(PieceType.Pawn, Player.Black);
        }
    }

    function move(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, PieceType promotionPiece) external {
        require(!gameEnded, "Game has already ended.");
        require(validPlayer(fromX, fromY), "Invalid player.");

        Piece memory piece = board[fromX][fromY];
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
        return msg.sender == getSenderForPlayer(currentPlayer) && board[x][y].player == currentPlayer;
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
        if (board[toX][toY].player == player) {
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
        view
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

    function validPawnMove(Player player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        view
        returns (bool)
    {
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
            if (distanceX == 1 && board[toX][toY].player == Player.None) {
                return true;
            }
            // Same Y, 2 distance from start line
            if (((player == Player.White && fromX == 1) || (player == Player.Black && fromX == 6)) && distanceX == 2) {
                return true;
            }
        } else if (abs(int8(toY) - int8(fromY)) == 1 && distanceX == 1) {
            // Check for capture
            if (board[toX][toY].player != Player.None) {
                return true;
            }
            if (isEnPassantCapture(player, fromX, fromY, toX, toY)) {
                return true;
            }
        }

        return false;
    }

    function isEnPassantCapture(Player player, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        internal
        view
        returns (bool)
    {
        if ((player == Player.White && fromX == 4) || (player == Player.Black && fromX == 3)) {
            if (lastMove[0] == toX && lastMove[1] == uint8(int8(toY) - (player == Player.White ? int8(1) : int8(-1)))) {
                Piece memory capturedPawn = board[toX][fromX];
                return capturedPawn.pieceType == PieceType.Pawn && capturedPawn.player != player;
            }
        }
        return false;
    }

    function validRookMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal view returns (bool) {
        if (fromX != toX && fromY != toY) {
            return false;
        }

        int8 xDirection = (fromX < toX) ? int8(1) : int8(-1);
        int8 yDirection = (fromY < toY) ? int8(1) : int8(-1);

        uint8 x = fromX;
        uint8 y = fromY;

        while (x != toX || y != toY) {
            x = (x != toX) ? uint8(int8(x) + xDirection) : x;
            y = (y != toY) ? uint8(int8(y) + yDirection) : y;

            if (x == toX && y == toY) {
                return true;
            }
            if (board[x][y].player != Player.None) {
                return false;
            }
        }

        return false;
    }

    function validBishopMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal view returns (bool) {
        if (abs(int8(toX) - int8(fromX)) != abs(int8(toY) - int8(fromY))) {
            return false;
        }

        int8 xDirection = (fromX < toX) ? int8(1) : int8(-1);
        int8 yDirection = (fromY < toY) ? int8(1) : int8(-1);

        int8 x = int8(fromX) + xDirection;
        int8 y = int8(fromY) + yDirection;

        while (x != int8(toX) && y != int8(toY)) {
            if (board[uint8(x)][uint8(y)].player != Player.None) {
                return false;
            }
            x += xDirection;
            y += yDirection;
        }

        return true;
    }

    function validKnightMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) internal pure returns (bool) {
        int8 xDiff = int8(toX) - int8(fromX);
        int8 yDiff = int8(toY) - int8(fromY);

        return (abs(xDiff) == 2 && abs(yDiff) == 1) || (abs(xDiff) == 1 && abs(yDiff) == 2);
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
        Piece[8][8] memory tempBoard;
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                tempBoard[x][y] = board[x][y];
            }
        }

        // Apply the move on the temporary board
        tempBoard[toX][toY] = tempBoard[fromX][fromY];
        tempBoard[fromX][fromY] = Piece(PieceType.Empty, Player.None);

        // Find the king's position for the current player
        uint8 kingX;
        uint8 kingY;
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (tempBoard[x][y].player == player && tempBoard[x][y].pieceType == PieceType.King) {
                    kingX = x;
                    kingY = y;
                }
            }
        }

        // Check if any of the opponent's pieces can capture the king
        Player opponentPlayer = player == Player.White ? Player.Black : Player.White;
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (tempBoard[x][y].player == opponentPlayer) {
                    if (validMoveForPiece(opponentPlayer, tempBoard[x][y], x, y, kingX, kingY)) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function applyMove(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, PieceType promotionPiece) internal {
        Piece memory piece = board[fromX][fromY];

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

        board[toX][toY] = piece;
        board[fromX][fromY] = Piece(PieceType.Empty, Player.None);

        emit Move(msg.sender, fromX, fromY, toX, toY);
    }

    /// @dev Check if it's a game over for the given player
    function isGameOver(Player forPlayer) internal returns (bool) {
        bool kingInCheck = false;
        uint8 kingX;
        uint8 kingY;

        // Find the king's position for the current player
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (board[x][y].player == forPlayer && board[x][y].pieceType == PieceType.King) {
                    kingX = x;
                    kingY = y;
                    break;
                }
            }
        }

        // Get the opponent player for move validation
        Player oppponentPlayer = forPlayer == Player.White ? Player.Black : Player.White;

        // Check if the king is in check
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (board[x][y].player == oppponentPlayer) {
                    if (validMove(oppponentPlayer, board[x][y], x, y, kingX, kingY)) {
                        kingInCheck = true;
                        break;
                    }
                }
            }
        }

        if (!kingInCheck) {
            // Check for a draw
            return isDraw(forPlayer);
        }

        // Check if there are any legal moves left for the current player
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (board[x][y].player == forPlayer) {
                    for (uint8 newX = 0; newX < 8; newX++) {
                        for (uint8 newY = 0; newY < 8; newY++) {
                            if (validMove(forPlayer, board[x][y], x, y, newX, newY)) {
                                return false;
                            }
                        }
                    }
                }
            }
        }

        // If there are no legal moves left and the king is in check, it's checkmate
        return true;
    }

    function isDraw(Player forPlayer) internal returns (bool) {
        // Check if there are any legal moves left for the current player
        for (uint8 x = 0; x < 8; x++) {
            for (uint8 y = 0; y < 8; y++) {
                if (board[x][y].player == currentPlayer) {
                    for (uint8 newX = 0; newX < 8; newX++) {
                        for (uint8 newY = 0; newY < 8; newY++) {
                            if (validMove(forPlayer, board[x][y], x, y, newX, newY)) {
                                return false;
                            }
                        }
                    }
                }
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

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}
