### Technical Details

The `script.js` file contains various functions that handle different aspects of the web application's functionality. Some of those tasks include:

- Clearing the chat display and file input.
- Creating side navigation links and tab contents for displaying responses.
- Deleting documents and fetching configuration from a `config.json` file.
- Converting bytes to KB/MB.
- Generating embeddings and getting answers using Azure OpenAI Service and Azure Search.
- Fetching documents from Azure Storage and getting SAS tokens from Azure Key Vault and an Azure Function App.
- Checking if a text is a question and posting questions to the chat display.
- Rephrasing text using Azure OpenAI Service.

Below is a list of these functions and their purposes:

- `clearChatDisplay`: Clears the chat display.
- `clearFileInput`: Clears the file input.
- `createSidenavLinks`: Creates side navigation links based on the configuration.
- `createTabContent`: Creates tab contents for displaying responses.
- `createTabs`: Creates tabs for displaying responses.
- `deleteDocuments`: Deletes documents.
- `fetchConfig`: Fetches the configuration from the `config.json` file.
- `formatBytes`: Converts bytes to KB/MB.
- `generateEmbeddingAsync`: Generates embeddings using Azure OpenAI Service.
- `getAnswersFromAzureSearch`: Gets answers from Azure Search.
- `getAnswersFromPublicInternet`: Gets answers from the public internet using Azure OpenAI Service.
- `getDocuments`: Fetches documents from Azure Storage.
- `getQueryParam`: Gets a query parameter from the URL.
- `getSasToken`: Gets a SAS token from Azure Key Vault.
- `getSasTokenOld`: Gets a SAS token from an Azure Function App.
- `isQuestion`: Checks if a text is a question.
- `postQuestion`: Posts a question to the chat display.
- `rephraseResponseFromAzureOpenAI`: Rephrases text using Azure OpenAI Service.
- `rephraseResponseText`: Rephrases text using Azure OpenAI Service.
- `renderDocuments`: Renders documents in the document list.
- `runSearchIndexer`: Runs the search indexer after a new file is uploaded.
- `setChatDisplayHeight`: Sets the height of the chat display container.
- `setSiteLogo`: Sets the site logo based on the configuration.
- `showResponse`: Shows responses to questions.
- `showToastNotification`: Shows a toast notification.
- `sortAnswers`: Sorts answers based on their keys.
- `sortDocuments`: Sorts documents based on the specified criteria.
- `toggleAllCheckboxes`: Toggles all checkboxes in the document list.
- `toggleDisplay`: Toggles between chat and document screens.
- `updateFileCount`: Updates the file count display.
- `updatePlaceholder`: Updates the placeholder text for the file input.
- `uploadFilesToAzure`: Uploads files to Azure Storage.

1. **User Input**:

   - The user types a question into the chat input textbox (`<input type="text" id="chat-input" />`) and clicks the "Send" button (`<button id="send-button">Send</button>`).

2. **Event Listener**:

   - An event listener for the "Send" button is triggered:
     ```javascript
     $("#send-button").on("click", postQuestion);
     ```

3. **Post Question**:

   - The [`postQuestion`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A27%2C%22character%22%3A34%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function is called:

     ```javascript
     async function postQuestion() {
       const config = await fetchConfig();
       let chatInput = document.getElementById("chat-input").value;
       const chatDisplay = document.getElementById("chat-display");
       const dateTimestamp = new Date().toLocaleString();

       // Check if chatInput ends with a question mark, if not, add one
       if (!chatInput.trim().endsWith("?")) {
         chatInput += "?";
       }

       // Capitalize the first letter if it is not already capitalized
       if (
         chatInput.length > 0 &&
         chatInput[0] !== chatInput[0].toUpperCase()
       ) {
         chatInput = chatInput[0].toUpperCase() + chatInput.slice(1);
       }

       // Create a new div for the chat bubble
       const questionBubble = document.createElement("div");
       questionBubble.setAttribute("class", "question-bubble fade-in");

       const svg = document.createElement("div");
       svg.className = "question-bubble-svg";
       svg.innerHTML = config.ICONS.QUESTION_MARK.SVG;

       const questionText = document.createElement("div");
       questionText.className = "question-bubble-text";
       questionText.innerHTML = `Question: "${chatInput}"`;

       const dateText = document.createElement("div");
       dateText.className = "question-bubble-date";
       dateText.innerHTML = `Date: ${dateTimestamp}`;

       questionBubble.appendChild(svg);
       questionBubble.appendChild(questionText);
       questionBubble.appendChild(dateText);

       // Append the chat bubble to the chat-info div
       chatDisplay.appendChild(questionBubble);

       // Scroll to the position right above the newest questionBubble
       const questionBubbleTop = questionBubble.offsetTop;
       chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

       showResponse();
     }
     ```

4. **Show Response**:

   - The [`showResponse`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A314%2C%22character%22%3A4%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function is called:

     ```javascript
     async function showResponse() {
       const config = await fetchConfig();
       const chatInput = document.getElementById("chat-input").value.trim();
       const chatDisplay = document.getElementById("chat-display");

       if (chatInput) {
         const response = await getAnswers(chatInput);

         // Create a new chat bubble element
         const chatBubble = document.createElement("div");
         chatBubble.setAttribute("class", "chat-bubble user slide-up");

         // Create tabs
         const tabs = document.createElement("div");
         tabs.className = "tabs";

         // Loop through CHAT_TABS to create tabs dynamically
         Object.entries(config.CHAT_TABS).forEach(([key, value], index) => {
           const tab = document.createElement("div");
           tab.className = `tab ${index === 0 ? "active" : ""}`;
           tab.innerHTML = `${value.SVG} ${value.TEXT}`;
           tabs.appendChild(tab);
         });

         // Create tab contents
         const answerContent = document.createElement("div");
         answerContent.className = "tab-content active";
         answerContent.textContent = response.choices[0].message.content;

         const thoughtProcessContent = document.createElement("div");
         thoughtProcessContent.className = "tab-content";
         thoughtProcessContent.textContent =
           "Thought process content goes here.";

         const supportingContentContent = document.createElement("div");
         supportingContentContent.className = "tab-content";
         supportingContentContent.textContent = "Supporting content goes here.";

         // Append tabs and contents to chat bubble
         chatBubble.appendChild(tabs);
         chatBubble.appendChild(answerContent);
         chatBubble.appendChild(thoughtProcessContent);
         chatBubble.appendChild(supportingContentContent);

         // Append the chat bubble to the chat-display div
         chatDisplay.appendChild(chatBubble);

         // Clear the input field
         chatInput.value = "";

         // Scroll to the position right above the newest questionBubble
         const questionBubbleTop = chatBubble.offsetTop;
         chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

         // Add event listeners to tabs
         const tabElements = tabs.querySelectorAll(".tab");
         const tabContents = chatBubble.querySelectorAll(".tab-content");

         tabElements.forEach((tab, index) => {
           tab.addEventListener("click", () => {
             tabElements.forEach((t) => t.classList.remove("active"));
             tabContents.forEach((tc) => tc.classList.remove("active"));

             tab.classList.add("active");
             tabContents[index].classList.add("active");
           });
         });
       }
     }
     ```

5. **Fetch Configuration**:

   - The [`fetchConfig`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A8%2C%22character%22%3A15%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function is called to retrieve configuration settings:
     ```javascript
     async function fetchConfig() {
       const response = await fetch("../config.json");
       const config = await response.json();
       return config;
     }
     ```

6. **Get Answers**:

   - The [`getAnswers`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A328%2C%22character%22%3A31%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function is called to send the user input to the AI service and retrieve the response:

     ```javascript
     async function getAnswers(userInput) {
       if (!userInput) return;

       const config = await fetchConfig();

       const apiKey = config.OPEN_AI_KEY;
       const apiVersion = config.API_VERSION;
       const deploymentId = config.DEPLOYMENT_ID;
       const region = config.REGION;
       const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentId}/chat/completions?api-version=${apiVersion}`;

       const userMessageContent = config.OPEN_AI_REQUEST_BODY.messages.find(
         (message) => message.role === "user"
       ).content[0];
       userMessageContent.text = userInput;

       const jsonString = JSON.stringify(config.OPEN_AI_REQUEST_BODY);

       try {
         const response = await fetch(endpoint, {
           method: "POST",
           headers: {
             "Content-Type": "application/json",
             "api-key": `${apiKey}`,
           },
           body: jsonString,
         });

         const data = await response.json();
         return data;
       } catch (error) {
         if (error.code == 429) {
           const data = {
             error: "Token rate limit exceeded. Please try again later.",
           };
           return data;
         } else {
           const data = { error: "An error occurred. Please try again later." };
           return data;
         }
       }
     }
     ```

7. **Render Response**:
   - The response from the AI service is rendered in a new chat bubble with tabs for different types of content (e.g., answer, thought process, supporting content).

### Summary

- The user enters a question and clicks "Send".
- The [`postQuestion`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A27%2C%22character%22%3A34%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function processes the input, formats it, and displays it in a chat bubble.
- The [`showResponse`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A314%2C%22character%22%3A4%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") function calls [`getAnswers`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2Fapp%2Ffrontend%2Fscripts%2Fscript.js%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A328%2C%22character%22%3A31%7D%7D%5D%2C%224502417a-3760-4f65-8377-3bda7b79547c%22%5D "Go to definition") to send the input to the AI service and retrieve the response.
- The response is rendered in a new chat bubble with tabs for different types of content.
