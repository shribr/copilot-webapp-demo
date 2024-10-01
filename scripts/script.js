$(document).ready(function() {
    $('#send-button').on('click', sendMessage);

    async function sendMessage() {
        const userInput = $('#user-input').val();
        if (!userInput) return;

        displayMessage('User', userInput);
        $('#user-input').val('');

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
        const chatDisplay = $('#chat-display');
        const messageElement = $('<div>').text(`${sender}: ${message}`);
        chatDisplay.append(messageElement);
        chatDisplay.scrollTop(chatDisplay[0].scrollHeight);
    }

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

    // Add event listeners to navigation links
    $('#nav-container nav ul li a').on('click', function(event) {
        event.preventDefault();
        const screen = new URL(this.href).searchParams.get('screen');
        toggleDisplay(screen);
        history.pushState(null, '', this.href);
    });
});