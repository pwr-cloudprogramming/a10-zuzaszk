// authentication-related functions
const registerUrl = 'http://localhost:8080/auth/register';
const confirmUrl = 'http://localhost:8080/auth/confirm';
const loginUrl = 'http://localhost:8080/auth/login';
const refreshUrl = 'http://localhost:8080/auth/refresh-token';

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
        // localStorage.setItem('accessToken', data.AccessToken);
        // localStorage.setItem('refreshToken', data.RefreshToken);
        alert('Login successful!');
        showGameBoard();
    })
    .catch(error => alert('Error: ' + error));
};

window.logout = function() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    alert('Logged out successfully!');
    document.getElementById('auth').classList.remove('hidden');
    document.getElementById('game').classList.add('hidden');
};


function refreshAccessToken() {
    const refreshToken = localStorage.getItem('refreshToken');

    if (!refreshToken) {
        alert('No refresh token found. Please login again.');
        return;
    }

    fetch(refreshUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refreshToken }),
        credentials: 'include'
    })
    .then(response => response.json())
    .then(data => {
        localStorage.setItem('accessToken', data.AccessToken);
        alert('Token refreshed successfully!');
    })
    .catch(error => alert('Error: ' + error));
}

// async function authFetch(url, options = {}) {
//     const accessToken = localStorage.getItem('accessToken');

//     if (!accessToken) {
//         alert('No access token found. Please login again.');
//         return Promise.reject('No access token');
//     }

//     options.headers = {
//         ...options.headers,
//         'Authorization': `Bearer ${accessToken}`
//     };

//     const response = await fetch(url, options);
//     if (response.status === 401) {
//         return refreshAccessToken().then(() => {
//             const newAccessToken = localStorage.getItem('accessToken');
//             options.headers['Authorization'] = `Bearer ${newAccessToken}`;
//             return fetch(url, options);
//         });
//     }
//     return response;
// }
