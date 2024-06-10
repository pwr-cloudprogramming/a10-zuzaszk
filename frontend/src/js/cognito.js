// authentication-related functions
const registerUrl = 'http://localhost:8080/auth/register';
const confirmUrl = 'http://localhost:8080/auth/confirm';
const loginUrl = 'http://localhost:8080/auth/login';

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