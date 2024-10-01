document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('send-button').addEventListener('click', sendMessage);

    async function sendMessage() {
        const userInput = document.getElementById('user-input').value;
        if (!userInput) return;

        displayMessage('User', userInput);
        document.getElementById('user-input').value = '';

        const response = await fetch('https://eastus.api.cognitive.microsoft.com/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer 835bba103fea40c9adab54ee45dc6902'
            },
            body: JSON.stringify({ message: userInput })
        });

        const data = await response.json();
        displayMessage('Azure Copilot', data.reply);
    }

    function displayMessage(sender, message) {
        const chatDisplay = document.getElementById('chat-display');
        const messageElement = document.createElement('div');
        messageElement.textContent = `${sender}: ${message}`;
        chatDisplay.appendChild(messageElement);
        chatDisplay.scrollTop = chatDisplay.scrollHeight;
    }

    $(document).ready(function() {
        function getQueryParam(param) {
            const urlParams = new URLSearchParams(window.location.search);
            return urlParams.get(param);
        }
    });
});

$(document).ready(function() {
    function getQueryParam(param) {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get(param);
    }

    function toggleDisplay(screen) {
        const $chatContainer = $('#chat-container');
        const $documentContainer = $('#document-container');

        if (screen === 'chat') {
            $chatContainer.show();
            $documentContainer.hide();
        } else if (screen === 'documents') {
            $chatContainer.hide();
            $documentContainer.show();
        } else {
            $chatContainer.hide();
            $documentContainer.hide();
        }
    }

    const screen = getQueryParam('screen');
    toggleDisplay(screen);
});