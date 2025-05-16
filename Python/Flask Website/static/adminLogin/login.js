function toggleMode(mode) {
    const formTitle = document.getElementById('form-title');
    const submitBtn = document.getElementById('submit-btn');
    const form = document.getElementById('auth-form');

    const switchRegister = document.getElementById('switch-to-register');
    const switchLogin = document.getElementById('switch-to-login');

    if (mode === 'login') {
        formTitle.textContent = 'Login';
        submitBtn.textContent = 'Einloggen';
        form.dataset.mode = 'login';
        form.method = 'POST';
        form.action = '/admin/login';
        switchRegister.classList.remove('hidden');
        switchLogin.classList.add('hidden');
    } else {
        formTitle.textContent = 'Registrieren';
        submitBtn.textContent = 'Registrieren';
        form.dataset.mode = 'register';
        form.method = 'POST';
        form.action = '/admin/register';
        switchRegister.classList.add('hidden');
        switchLogin.classList.remove('hidden');
    }
}

window.onload = () => {
    toggleMode('login');

    document.getElementById('responseMessage').style.display = 'none';

    document.getElementById('auth-form').addEventListener('submit', async function (e) {
        e.preventDefault();

        const form = e.target;
        const action = form.action;
        const username = form.username.value;
        const password = form.password.value;

        try {
            const response = await fetch(action, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });

            const responseMessageDiv = document.getElementById('responseMessage');

            // Sofort die Nachricht setzen und anzeigen
            const result = await response.text();

            if (!response.ok) {
                log(`Fehler ${response.status}: ${result}`);
                responseMessageDiv.style.display = 'block';
                responseMessageDiv.style.color = 'red';
                responseMessageDiv.style.border = '5px solid red'
                responseMessageDiv.innerHTML = 'Falscher Benutzername oder Passwort!';
                return;
            }

            // Erfolgsmeldung anzeigen und Countdown starten
            let seconds = 3;
            const countdown = setInterval(() => {
                responseMessageDiv.style.color = 'green';
                responseMessageDiv.style.border = '5px solid green'
                responseMessageDiv.innerHTML = `Login erfolgreich...Weiterleitung in ${seconds}`;
                seconds--;
                if (seconds < 0) {
                    clearInterval(countdown);
                    localStorage.setItem("Session ID", generateRandomNumber())
                    window.location.href = '/';
                }
            }, 1000);

            responseMessageDiv.style.display = 'block';
        } catch (error) {
            console.error('Netzwerk-/Serverfehler:', error);
            alert("Serverfehler oder keine Verbindung.");
        }
    });
}

function generateRandomNumber(pairs = 4) {
  let result = [];
  for (let i = 0; i < pairs; i++) {
    let number = Math.floor(1000 + Math.random() * 9000);
    result.push(number.toString());
  }
  return result.join('-');
}