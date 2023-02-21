// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract RockPaperScissors {

    enum Shape {
        Rock,
        Scissors,
        Paper
    }

    enum GameState {
        Stopped,
        WaitingForPlayerTwo,
        WaitingForReveal,
        WaitingForCompletion
    }

    int8[3][3] checkWinner = [
        [int8(0), int8(-1), int8(1)],
        [int8(1), int8(0), int8(-1)],
        [int8(-1), int8(1), int8(0)]
    ];

    event Move(address player, Shape move);
    event Winner(address winner, uint256 amount);
    event Tie(address playerOne, address playerTwo, uint256 amount);
    event TimeOut(address winner, uint256 amount);

    uint public timeout;
    uint public minimumBet;
    uint public playerOneDeposit;

    mapping(address => uint256) public balances;

    GameState public state;
    uint256 lastActionTimestamp;
    uint256 public potSize;
    uint256 public betSize;

    address public playerOne;
    bytes32 hiddenMovePlayerOne;
    Shape public movePlayerOne;

    address public playerTwo;
    Shape public movePlayerTwo;

    // constructor(uint256 _timeout, uint256 _minimumBet, uint256 _playerOneDeposit) {
    constructor() {
        timeout = 10000000000000;
        minimumBet = 100000000000000000;
        playerOneDeposit = 200000000000000000;
    }

    receive() external payable {
        potSize += msg.value;
    }

    function startGame(bytes32 hiddenMove) public payable {
        require(state == GameState.Stopped, "A game is already running!");
        require(msg.value >= minimumBet + playerOneDeposit, "Not enough coins sent for minimum bet and deposit!");
        
        betSize = msg.value - playerOneDeposit;
        potSize += betSize;
        playerOne = msg.sender;
        hiddenMovePlayerOne = hiddenMove;

        setGameState(GameState.WaitingForPlayerTwo);
    }

    function joinGame(Shape move) public payable {
        require(state == GameState.WaitingForPlayerTwo, "Cannot join a game when it is not waiting for a second player!");
        require(msg.value == betSize, "Please supply exactly `betSize` coins!");
        require(msg.sender != playerOne, "Cannot play against yourself!");

        potSize += msg.value;
        playerTwo = msg.sender;
        movePlayerTwo = move;

        emit Move(msg.sender, move);

        setGameState(GameState.WaitingForReveal);
    }

    function revealMove(Shape move, uint256 nonce) public {
        require(state == GameState.WaitingForReveal, "Cannot reveal the move when the game is not waiting for a reveal!");

        bytes32 hashed = keccak256(abi.encode(move, nonce));
        assert(hashed == hiddenMovePlayerOne);
        movePlayerOne = move;
        balances[playerOne] += playerOneDeposit;

        emit Move(playerOne, move);

        setGameState(GameState.WaitingForCompletion);

        completeGame();
    }

    function completeGame() public {
        require(state != GameState.Stopped, "Cannot complete a game when none is running!");

        if (state == GameState.WaitingForPlayerTwo) {
            require(isTimedOut(), "Cannot complete a game without a second player before the timeout!");

            balances[playerOne] += potSize;
            balances[playerOne] += playerOneDeposit;

            emit TimeOut(playerOne, potSize);
        }
        else if (state == GameState.WaitingForReveal) {
            require(isTimedOut(), "Cannot complete a game waiting for reveal before the timeout!");

            balances[playerTwo] += potSize;
            balances[playerTwo] += playerOneDeposit;

            emit TimeOut(playerTwo, potSize);
        } else if (state == GameState.WaitingForCompletion) {
            int8 winner = checkWinner[uint(movePlayerOne)][uint(movePlayerTwo)];

            if (winner > 0) {
                balances[playerOne] += potSize;

                emit Winner(playerOne, potSize);
            } else if (winner < 0) {
                balances[playerTwo] += potSize;

                emit Winner(playerTwo, potSize);
            } else {
                balances[playerOne] += potSize / 2;
                balances[playerTwo] += potSize / 2;

                emit Tie(playerOne, playerTwo, potSize);
            }
        } else {
            revert("Invalid game state!");
        }

        delete potSize;
        delete betSize;
        delete playerOne;
        delete hiddenMovePlayerOne;
        delete movePlayerOne;
        delete playerTwo;
        delete movePlayerTwo;

        setGameState(GameState.Stopped);
    }

    function withdraw(address target) public {
        require(balances[msg.sender] > 0, "Cannot withdraw without a balance!");

        uint256 balanceToTransfer = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = target.call{value: balanceToTransfer}("");

        if (!success) {
            balances[msg.sender] = balanceToTransfer;
        }
    }

    function timeoutAt() public view returns (uint256) {
        return lastActionTimestamp + timeout;
    }

    function isTimedOut() private view returns (bool) {
        return block.timestamp >= timeoutAt();
    }

    function setGameState(GameState newState) private {
        state = newState;
        lastActionTimestamp = block.timestamp;
    }
}