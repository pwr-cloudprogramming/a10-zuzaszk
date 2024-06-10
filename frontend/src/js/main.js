document.addEventListener("DOMContentLoaded", function() {
    const registerUrl = 'http://localhost:8080/auth/register';
    const confirmUrl = 'http://localhost:8080/auth/confirm';
    const loginUrl = 'http://localhost:8080/auth/login';
    const gameUrl = 'http://localhost:8080/game';

    function showGameBoard() {
        document.getElementById('auth').classList.add('hidden');
        document.getElementById('game').classList.remove('hidden');
    }

    window.register = function() {
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        fetch(registerUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password }),
            credentials: 'include' // Include credentials in the request
        })
        .then(response => response.text())
        .then(message => {
            alert(message);
            const confirmationCode = prompt("Enter the confirmation code sent to your email:");
            confirmUser(email, confirmationCode);
        })
        .catch(error => alert('Error: ' + error));
    };

    function confirmUser(email, confirmationCode) {
        fetch(confirmUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, confirmationCode }),
            credentials: 'include' // Include credentials in the request
        })
        .then(response => response.text())
        .then(message => alert(message))
        .catch(error => alert('Error: ' + error));
    }

    window.login = function() {
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        fetch(loginUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password }),
            credentials: 'include' // Include credentials in the request
        })
        .then(response => response.json())
        .then(data => {
            alert('Login successful!');
            showGameBoard();
        })
        .catch(error => alert('Error: ' + error));
    };

    // Game-related functions
    var turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
    var turn = "";
    var gameOn = false;
    let stompClient;
    let gameId;
    let playerType;

    function connectToSocket(gameId) {
        let socket = new SockJS(gameUrl + "/gameplay");
        stompClient = Stomp.over(socket);
        stompClient.connect({}, function (frame) {
            console.log("connected to the frame: " + frame);
            stompClient.subscribe("/topic/game-progress/" + gameId, function (response) {
                let data = JSON.parse(response.body);
                console.log(data);
                displayResponse(data);
            })
        })
    }

    window.create_game = function() {
        let login = document.getElementById("login").value;
        if (login == null || login === '') {
            alert("Please enter login");
        } else {
            fetch(gameUrl + "/start", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ login: login }),
                credentials: 'include' // Include credentials in the request
            })
            .then(response => response.json())
            .then(data => {
                gameId = data.gameId;
                playerType = 'X';
                reset();
                connectToSocket(gameId);
                alert("You created a game.");
                gameOn = true;
            })
            .catch(error => console.error('Error:', error));
        }
    };

    window.connectToRandom = function() {
        let login = document.getElementById("login").value;
        if (login == null || login === '') {
            alert("Please enter login");
        } else {
            fetch(gameUrl + "/connect/random", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ login: login }),
                credentials: 'include' // Include credentials in the request
            })
            .then(response => response.json())
            .then(data => {
                gameId = data.gameId;
                playerType = 'O';
                reset();
                connectToSocket(gameId);
                alert("Congrats, you're playing with: " + data.player1.login);
            })
            .catch(error => console.error('Error:', error));
        }
    };

    window.playerTurn = function(turn, id) {
        if (gameOn) {
            var spotTaken = document.getElementById(id).innerText;
            if (spotTaken === "#") {
                makeAMove(playerType, id.split("_")[0], id.split("_")[1]);
            }
        }
    };

    function makeAMove(type, xCoordinate, yCoordinate) {
        fetch(gameUrl + "/gameplay", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                "type": type,
                "coordinateX": xCoordinate,
                "coordinateY": yCoordinate,
                "gameId": gameId
            }),
            credentials: 'include' // Include credentials in the request
        })
        .then(response => response.json())
        .then(data => {
            gameOn = false;
            displayResponse(data);
        })
        .catch(error => console.error('Error:', error));
    }

    function displayResponse(data) {
        let board = data.board;
        for (let i = 0; i < board.length; i++) {
            for (let j = 0; j < board[i].length; j++) {
                if (board[i][j] === 1) {
                    turns[i][j] = 'X';
                } else if (board[i][j] === 2) {
                    turns[i][j] = 'O';
                }
                let id = i + "_" + j;
                document.getElementById(id).innerText = turns[i][j];
            }
        }
        if (data.winner != null) {
            alert("Winner is " + data.winner);
        }
        gameOn = true;
    }

    function reset() {
        turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
        var elements = document.getElementsByClassName("tic");
        for (var i = 0; i < elements.length; i++) {
            elements[i].innerText = "#";
        }
    }

    var resetButton = document.getElementById("reset");
    if (resetButton) {
        resetButton.addEventListener("click", function() {
            reset();
        });
    } else {
        console.error('Reset button not found');
    }

    var elements = document.getElementsByClassName("tic");
    for (var i = 0; i < elements.length; i++) {
        elements[i].addEventListener("click", function() {
            var slot = this.getAttribute('id');
            playerTurn(turn, slot);
        });
    }
});
