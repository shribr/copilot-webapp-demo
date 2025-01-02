var iconStyle = "color";
let blobs = [];
let currentSortColumn = '';
let currentSortDirection = 'asc';
let answerResponseNumber = 1;
let chatHistory = [];
let thread = [];
let threadId = '';

//const config = await fetchConfig();

$(document).ready(function () {

    setChatDisplayHeight();

    setSiteLogo();

    // Add an event listener to adjust the height on window resize
    //window.addEventListener('resize', setChatDisplayHeight);

    getDocuments();

    createSidenavLinks();

    const chatDisplay = document.getElementById('chat-display');
    const loadingAnimation = document.createElement('div');
    loadingAnimation.setAttribute('class', 'loading-animation');
    loadingAnimation.innerHTML = '<div class="spinner"></div> Fetching results...';
    loadingAnimation.style.display = 'none'; // Hide it initially
    chatDisplay.appendChild(loadingAnimation);

    $('#send-button').on('click', postQuestion);
    $('#clear-button').on('click', clearChatDisplay);

    $(document).on('keydown', function (event) {
        if (event.key === 'Enter') {
            postQuestion();
        }
    });

    document.addEventListener('click', function (event) {
        const settingsDialog = document.getElementById('settings-dialog');
        const settingsOverlay = document.getElementById('settings-overlay');

        if (settingsDialog.style.display === 'block' && !settingsDialog.contains(event.target) && !document.getElementById('link-settings').contains(event.target)) {
            settingsDialog.style.display = 'none';
            settingsOverlay.style.display = 'none';
        }
    });

    const screen = getQueryParam('screen');

    toggleDisplay(screen);

    // Add event listeners to navigation links
    $('#left-nav-container nav ul li').on('click', function (event) {
        const link = $(this).find('a')[0];
        if (link) {
            event.preventDefault();
            const screen = new URL(link.href).searchParams.get('screen');
            toggleDisplay(screen);
            history.pushState(null, '', link.href);
        }
    });

    document.getElementById('datasource-all').addEventListener('change', toggleAllCheckboxes);

    // Add event listeners to column headers for sorting
    document.getElementById('header-content-type').addEventListener('click', () => sortDocuments('Size'));
    document.getElementById('header-name').addEventListener('click', () => sortDocuments('Name'));
    document.getElementById('header-date').addEventListener('click', () => sortDocuments('Last-Modified'));
    document.getElementById('header-status').addEventListener('click', () => sortDocuments('Content-Type'));

    document.getElementById('svg-expander').addEventListener('click', setChatDisplayHeight);

    // Add event listener to the file input
    document.getElementById('file-input').addEventListener('change', function (event) {
        const fileList = document.getElementById('file-list');
        const noFilesPlaceholder = document.getElementById('num-files-selected-placeholder');
        const uploadButton = document.getElementById('upload-button');
        fileList.innerHTML = ''; // Clear the list

        updatePlaceholder();

        Array.from(event.target.files).forEach((file, index) => {
            const listItem = document.createElement('li');
            listItem.textContent = `${file.name} (${(file.size / 1024).toFixed(2)} KB)`;

            const removeButton = document.createElement('button');
            removeButton.textContent = 'Remove';
            removeButton.addEventListener('click', (e) => {
                e.stopPropagation(); // Prevent triggering the file input click event

                const filesArray = Array.from(document.getElementById('file-input').files);
                filesArray.splice(index, 1);

                const dataTransfer = new DataTransfer();
                filesArray.forEach(file => dataTransfer.items.add(file));
                document.getElementById('file-input').files = dataTransfer.files;

                listItem.remove();
                updatePlaceholder();
                updateFileCount(); // Update the file count whenever a file is removed

                // Clear the file input if no files are left
                if (filesArray.length === 0) {
                    document.getElementById('file-input').value = '';
                }
            });

            listItem.appendChild(removeButton);
            fileList.appendChild(listItem);
        });

        updatePlaceholder();
    });

    // Trigger file input click when custom button is clicked
    document.getElementById('choose-files-button').addEventListener('click', function (event) {
        event.preventDefault(); // Prevent default button behavior
        document.getElementById('file-input').click();
    });

    // Filter existing documents based on the name field
    document.getElementById('filter-input').addEventListener('input', function (event) {
        const filterValue = event.target.value.toLowerCase();
        const documentRows = document.querySelectorAll('#document-table .document-row:not(.header)');
        const clearFilterButton = document.getElementById('clear-filter-button');
        const filterButton = document.getElementById('filter-button');

        if (filterValue) {
            clearFilterButton.style.display = 'block';
            filterButton.style.display = 'none';
        } else {
            clearFilterButton.style.display = 'none';
            filterButton.style.display = 'block';
            documentRows.forEach(row => {
                if (!row.classList.contains('sample')) {
                    row.style.display = ''; // Reset the visibility of all rows except sample ones
                }
            });
        }

        documentRows.forEach(row => {
            if (row.style.display === 'none') {
                return; // Skip hidden rows
            }
            const nameCell = row.querySelector('.document-cell:nth-child(3)');
            if (nameCell.textContent.toLowerCase().includes(filterValue)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });

    document.getElementById('clear-filter-button').addEventListener('click', function () {
        document.getElementById('filter-input').value = ''; // Clear the filter input
        const documentRows = document.querySelectorAll('#document-list .document-row:not(.header)');
        documentRows.forEach(row => {
            if (!row.classList.contains('sample')) {
                row.style.display = ''; // Reset the visibility of all rows except sample ones
            }
        });
        this.style.display = 'none'; // Hide the clear filter button
        document.getElementById('filter-button').style.display = 'block'; // Show the filter button
    });

    // Event listener for upload button
    document.getElementById('upload-button').addEventListener('click', function () {
        const files = document.getElementById('file-input').files;
        if (files.length > 0) {
            //uploadFilesToAzure(files);
            uploadFilesToAzure(files);
        } else {
            console.log('No files selected for upload.');
        }
    });

    document.getElementById('link-settings').addEventListener('click', function (event) {
        event.preventDefault();

        const settingsDialog = document.getElementById('settings-dialog');
        const settingsOverlay = document.getElementById('settings-overlay');

        if (settingsDialog.style.display === 'none' || settingsDialog.style.display === '') {
            settingsDialog.style.display = 'block';
            settingsOverlay.style.display = 'block';
        } else {
            settingsDialog.style.display = 'none';
            settingsOverlay.style.display = 'none';
        }

        // Handle settings click
        console.log('Settings clicked');
    });

    document.getElementById('link-profile').addEventListener('click', function (event) {
        event.preventDefault();
        // Handle profile click
        console.log('Profile clicked');
    });

    document.getElementById('link-help').addEventListener('click', function (event) {
        event.preventDefault();
        // Handle help click
        console.log('Help clicked');
    });

    document.getElementById('close-settings-dialog').addEventListener('click', function () {
        document.getElementById('settings-dialog').style.display = 'none';
        document.getElementById('settings-overlay').style.display = 'none';
    });

    document.getElementById('jump-to-top-arrow').addEventListener('click', function () {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    document.getElementById('datasources-header').addEventListener('click', function () {
        const content = document.getElementById('datasources-container');
        const arrow = document.querySelector('#datasources-header .accordion-arrow');
        if (content.style.display === 'none' || content.style.display === '') {
            content.style.display = 'block';
            arrow.innerHTML = '&#9650;'; // Up arrow
        } else {
            content.style.display = 'none';
            arrow.innerHTML = '&#9660;'; // Down arrow
        }
    });

    document.getElementById('chat-personas-header').addEventListener('click', function () {
        const content = document.getElementById('chat-personas-container');
        const arrow = document.querySelector('#chat-personas-header .accordion-arrow');
        if (content.style.display === 'none' || content.style.display === '') {
            content.style.display = 'block';
            arrow.innerHTML = '&#9650;'; // Up arrow
        } else {
            content.style.display = 'none';
            arrow.innerHTML = '&#9660;'; // Down arrow
        }
    });

    renderChatPersonas();
});

// Function to add a message to a thread
async function addMessageToThread(threadId, message, role) {

    const config = await fetchConfig();
    const apiVersion = config.OPENAI_API_VERSION;
    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    //const openAIRequestBody = config.OPENAI_REQUEST_BODY;

    const endpoint = `https://${config.REGION}.api.cognitive.microsoft.com/openai/threads/${threadId}/messages?api-version=${apiVersion}`;

    const jsonMessage = JSON.stringify(message);

    const jsonString = `{ "role": "${role}", "content": ${jsonMessage} }`;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const message = await response.json();

        console.log(`Message added to thread: ${threadId}`, message);
    }
    catch (error) {
        console.log('Error adding message to thread:', error);
    }
}

// Function to build chat history
function buildChatHistory(answerResponseNumber, question, rawAnswers, opentAiRefinedAnswers, persona, dateTimestamp) {

    const chatEntry = {
        responseNum: `response-${answerResponseNumber}`,
        details: {
            question: question,
            rawAnswers: rawAnswers,
            opentAiRefinedAnswers: opentAiRefinedAnswers,
            persona: persona,
            dateTimestamp: dateTimestamp
        }
    };

    chatHistory.push(chatEntry);

    console.log(chatHistory);
}

// Function to clear the chat display
function clearChatDisplay() {
    const chatDisplayContainer = document.getElementById('chat-display-container');

    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.innerHTML = ''; // Clear all content

    const loadingAnimation = document.createElement('div');
    loadingAnimation.setAttribute('class', 'loading-animation');
    loadingAnimation.innerHTML = '<div class="spinner"></div> Fetching results...';
    loadingAnimation.style.display = 'none'; // Hide it initially
    chatDisplayContainer.appendChild(loadingAnimation);

    document.getElementById('expand-chat-svg-container').style.display = 'none';
    document.getElementById('jump-to-top-arrow').style.display = 'none';
}

//code to clear file input
function clearFileInput() {
    const fileInput = document.getElementById('file-input');
    fileInput.value = ''; // Clear the file input

    const selectedFilesDiv = document.getElementById('file-list');
    selectedFilesDiv.innerHTML = ''; // Clear the list of selected files
    updatePlaceholder(); // Update the placeholder text
}

// Function to create chat response content
async function createChatResponseContent(chatInput, rawAnswers, chatResponse, answerContent, sasToken, persona) {

    const config = await fetchConfig();

    const downloadChatResultsSVG = config.ICONS.DOWNLOAD_BUTTON.SVG;

    var aiEnhancedAnswers = "";
    var sourceNumber = 0;
    var citationContentResults = "";
    var dateTimestamp = new Date().toLocaleString();
    var openAIModelResultsId = "";

    var aiEnhancedAnswersArray = rawAnswers;

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;

    // Initialize a Set to store unique document paths
    const listedPaths = new Set();

    for (const answer of rawAnswers) {

        const docPath = `${answer.document.title}?${sasToken}`;
        const docTitle = answer.document.title;

        const docUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${docTitle}?${sasToken}`;

        if (!listedPaths.has(docPath)) {
            listedPaths.add(docPath);

            sourceNumber++;

            const supportingContentLink = `<a class="answer_citations" title="${docTitle}" href="${docUrl}" style="text-decoration: underline" target="_blank">${sourceNumber}. ${answer.document.title}</a>`;

            citationContentResults += `<div id="answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${supportingContentLink}</div>`;

        } else {
            console.log(`Document already listed: ${docPath}`);
        }

        //aiEnhancedAnswer = await getAnswersFromAzureOpenAIModel(`${chatPersonaPrompt} Rephrase the following text and use complete sentences only. Be specific and reference the specific document ${answer.document.title}: '${answer.text}'`, "gpt-4o");
        aiEnhancedAnswer = await getAnswersFromAzureOpenAIModel(answer.text, "gpt-4o", persona);
        aiEnhancedAnswer = aiEnhancedAnswer.replace(/\*\*(.*?)\*\*:?/g, '<b class="bullet-title">$1:</b>:');

        await addMessageToThread(threadId, aiEnhancedAnswer, "assistant");

        aiEnhancedAnswersArray[0].text = aiEnhancedAnswer;

        const footNoteLink = `<sup class="answer_citations"><a title="${docTitle}" href="#answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${sourceNumber}</a></sup>`;

        const aiEnhancedAnswerHtml = '<li class="answer_results">' + aiEnhancedAnswer + footNoteLink + '</li>';
        aiEnhancedAnswers += aiEnhancedAnswerHtml;
    }

    // Build chat history
    if (aiEnhancedAnswersArray.length > 0) {
        buildChatHistory(answerResponseNumber, chatInput, rawAnswers, aiEnhancedAnswersArray, persona, dateTimestamp);
    }

    answerContent.innerHTML += '<div id="openai-model-results-header">OpenAI Enhanced Search Results from Azure Storage</div>';

    //document.getElementById('download-chat-results-button').style.display = 'block';
    const openAIModelResultsContainerId = `openai-model-results-container-${answerResponseNumber}`;
    openAIModelResultsId = `openai-model-results-${answerResponseNumber}`;

    if (aiEnhancedAnswers.length > 0) {
        answerContent.innerHTML += `<div id="${openAIModelResultsContainerId}" class="openai-model-results"><div id="${openAIModelResultsId}"><ol class="ai_enhanced_answer_results">${aiEnhancedAnswers}</ol><br/></div>`;
        answerContent.innerHTML += `<div class="pt-4"><h6 class="mud-typography mud-typography-subtitle2 pb-2">Sources:</h6>${citationContentResults}</div></div>`;
    }
    else {
        answerContent.innerHTML += `<div id="${openAIModelResultsId}">No results found.</div>`;
    }

    chatResponse.appendChild(answerContent);

    // Add download chat results button
    if (openAIModelResultsId != "" && openAIModelResultsId != undefined) {

        const openAIResultsContainer = document.getElementById(openAIModelResultsId);

        const downloadChatResultsContainer = document.createElement('div');
        downloadChatResultsContainer.id = `download-chat-results-container-${answerResponseNumber}`;
        downloadChatResultsContainer.className = 'download-chat-results-container';

        const downloadChatResultsButtonId = `download-chat-results-button-${answerResponseNumber}`;

        const downloadChatResultsButton = `<div id="${downloadChatResultsButtonId}" onclick="downloadChatResults('${openAIModelResultsId}')" class="download-chat-results-button">${downloadChatResultsSVG}</div>`;

        downloadChatResultsContainer.innerHTML = downloadChatResultsButton;

        openAIResultsContainer.appendChild(downloadChatResultsContainer);

        //document.getElementById(downloadChatResultsButtonId).addEventListener('click', downloadChatResults(openAIModelResultsId));
    }

}

// Function to collect chat results
function collectChatResults(chatResultsId) {
    const chatDisplay = document.getElementById(`${chatResultsId}`);
    return chatDisplay.innerHTML;
}

//function to create side navigation links
async function createSidenavLinks() {

    const config = await fetchConfig();

    try {


        const sidenav = document.getElementById('left-nav-container').querySelector('nav ul');
        const sidenavLinks = Object.values(config.SIDEBAR_NAV_ITEMS);

        // Debugging: Log the sidenavLinks to check its type and content
        console.log('sidenavLinks:', sidenavLinks);

        // Validate that sidenavLinks is an array
        if (Array.isArray(sidenavLinks)) {
            for (const [key, value] of Object.entries(config.SIDEBAR_NAV_ITEMS)) {
                const sidenavItem = document.createElement('li');
                const sidenavLink = document.createElement('a');

                sidenavLink.href = value.URL;
                sidenavLink.setAttribute('aria-label', value.TEXT);
                sidenavLink.setAttribute('title', value.TEXT);
                sidenavLink.setAttribute('data-tooltip', value.TEXT);
                sidenavLink.setAttribute('id', `sidenav-item-${key}`);
                sidenavLink.innerHTML = `${value.SVG} ${value.TEXT}`;

                sidenavItem.appendChild(sidenavLink);
                sidenav.appendChild(sidenavItem);

                console.log(`Key: ${key}, Text: ${value.TEXT}`);
            }
        } else {
            console.error('sidenavLinks is not an array:', sidenavLinks);
        }
    } catch (error) {
        console.error('Failed to create sidenav links:', error);
    }
}

// Function to create tabs
async function createTabs() {

    const config = await fetchConfig();

    const tabs = document.createElement('div');
    tabs.className = 'tabs';

    // Loop through CHAT_TABS to create tabs dynamically
    Object.entries(config.RESPONSE_TABS).forEach(([key, value], index) => {
        const tab = document.createElement('div');
        tab.className = `tab ${index === 0 ? 'active' : ''}`;
        tab.innerHTML = `${value.SVG} ${value.TEXT}`;
        tabs.appendChild(tab);
    });

    return tabs;
}

// Function to create tab contents for supporting content results returned from Azure Search
function createTabContentSupportingContent(answers, docStorageResponse, supportingContent, sasToken) {

    if (docStorageResponse && docStorageResponse["@search.answers"] && docStorageResponse.value && docStorageResponse.value.length > 0) {

        //var answerResults = "";
        var citationContentResults = "";
        var supportingContentResults = "";
        var answerNumber = 1;
        var sourceNumber = 1;

        // Initialize a Set to store unique document paths
        const listedPaths = new Set();

        answers.forEach(answer => {
            if (answer.text) {
                const docPath = `${answer.document.metadata_storage_path}?${sasToken}`;
                const docTitle = answer.document.title;

                const footNoteLink = `<sup class="answer_citations"><a href="#answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${sourceNumber}</a></sup>`;
                const docLink = ` <a href="${docPath}" class="supporting_content_link" title="${docTitle}" target="_blank">(${docTitle})</a>`;
                //supportingContentResults += '<li class="answer_results">' + answer.text.replace(" **", "").replace(/\s+/g, " ") + footNoteLink + '</li>';
                supportingContentResults += '<li class="answer_results">' + answer.text.replace(" **", "").replace(/\s+/g, " ") + docLink + '</li>';
                if (!listedPaths.has(docPath)) {
                    listedPaths.add(docPath);

                    //const supportingContentLink = `<a class="answer_citations" title="${docPath}" href="${docPath}" style="text-decoration: underline" target="_blank">${sourceNumber}. ${docTitle}</a>`;

                    //citationContentResults += `<div id="citation-link-${answerResultsNumber}-${sourceNumber}">${supportingContentLink}</div>`;

                    sourceNumber++;
                } else {
                    console.log(`Document already listed: ${docPath}`);
                }

                answerNumber++;
            }
        });

        if (supportingContentResults != "") {
            supportingContent.innerHTML += '<div id="azure-storage-results-container"><div id="azure-storage-results-header">Supporting Content from Azure Storage</div>' + '<ol id="supporting_content_results">' + supportingContentResults + '</ol><br/></div>';
            //supportingContent.innerHTML += `<div class="pt-4"><h6 class="mud-typography mud-typography-subtitle2 pb-2">Sources:</h6>${citationContentResults}</div></div>`;
        }

        console.log('Cross-referenced answers:', answers);
    }

    return supportingContent;
}

// Function to create a new thread for an AI conversation
async function createThread(metadata, toolResources) {

    const config = await fetchConfig();
    const apiVersion = config.OPENAI_API_VERSION;
    const apiKey = config.AZURE_AI_SERVICE_API_KEY;

    const endpoint = `https://${config.REGION}.api.cognitive.microsoft.com/openai/threads?api-version=${apiVersion}`;

    const jsonMetadata = JSON.stringify(metadata);
    const jsonToolResources = JSON.stringify(toolResources);
    const jsonString = ` { "metadata": ${jsonMetadata}, "tool_resources": ${jsonToolResources} } `;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const thread = await response.json();

        console.log('Thread created:', thread);

        return thread;
    }
    catch (error) {
        console.log('Error creating thread:', error);
    }

    return null;
}

// function to delete documents
function deleteDocuments() {
    //code to delete documents

}

// Function to download chat results to a file
function downloadChatResults(chatResultsId) {

    const chatResults = collectChatResults(chatResultsId);
    const blob = new Blob([chatResults], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'chat-results.html';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// Function to fetch the configuration
async function fetchConfig() {

    const response = await fetch('../config.json');
    const config = await response.json();
    return config;
}

// Function to convert bytes to KB/MB
function formatBytes(bytes) {
    if (bytes < 1024) return bytes + ' B';
    else if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    else return (bytes / 1048576).toFixed(2) + ' MB';
}

// Function to format response as bulleted list
function formatReponseAsBulletedList(text) {
    try {
        const lines = text.split('\n');
        const bulletedList = lines.map(line => {
            // Remove standalone numbers and replace them with <li> elements
            return line.replace(/\b\d+\b(?!<\/li>)/g, '').replace(" **", "<li>").replace("**:", "</li>");
        }).join('');
        return `<ol>${bulletedList}</ol>`;
    } catch (error) {
        console.error('Error formatting response as bulleted list:', error);
        return text;
    }
}

// Function to generate embeddings
async function generateEmbeddingAsync(text, model) {

    const config = await fetchConfig();

    try {
        const endpoint = `https://eastus.api.cognitive.microsoft.com/openai/deployments/${model.Name}/embeddings?api-version=${model.ApiVersion}`;

        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': model.ApiKey
            },
            body: JSON.stringify({
                input: text,
                model: modelType // Example model
            })
        });

        const data = await response.json();
        return data.data[0].embedding;
    } catch (error) {
        return null;
    }
}

//code to send message to Azure Search via Azure Function
async function getAnswersFromAzureSearch(userInput, aiModelName, indexName, useEmbeddings) {
    if (!userInput) return;

    const config = await fetchConfig();

    const aiModels = config.AI_MODELS;
    const apiKey = config.AZURE_SEARCH_API_KEY;
    const aiModel = aiModels.find(item => item.Name === aiModelName);
    const apiVersion = config.AZURE_SEARCH_API_VERSION;
    const searchServiceName = config.AZURE_SEARCH_SERVICE_NAME;

    var embeddings = null;

    if (useEmbeddings) {
        try {
            embeddings = await generateEmbeddingAsync(userInput, aiModel);
        } catch (error) {
            embeddings = null;
            console.error('Error generating embeddings:', error);
        }

    }

    const endpoint = `https://${searchServiceName}.search.windows.net/indexes/${indexName}/docs/search?api-version=${apiVersion}`;

    var searchQuery = {};

    if (!useEmbeddings || embeddings == null) {
        searchQuery = {
            search: userInput,
            count: true,
            vectorQueries: [
                {
                    kind: "text",
                    text: userInput,
                    fields: "text_vector,image_vector"
                }
            ],
            queryType: "semantic",
            semanticConfiguration: config.AZURE_SEARCH_SEMANTIC_CONFIG,
            captions: "extractive",
            answers: "extractive|count-3",
            queryLanguage: "en-us"
        };
    }
    else {
        searchQuery = {
            search: userInput,
            count: true,
            vectorQueries: [
                {
                    kind: "vector",
                    vector: embeddings,
                    k: 7,
                    fields: "embedding"
                }
            ],
            queryType: "semantic",
            semanticConfiguration: config.AZURE_SEARCH_SEMANTIC_CONFIG,
            captions: "extractive",
            answers: "extractive|count-3",
            queryLanguage: "en-us"
        };
    }
    const jsonString = JSON.stringify(searchQuery);

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true',
                'mode': 'no-cors'
            },
            body: jsonString
        });

        const data = await response.json();
        console.log(data);

        try {
            // Process the search results to extract relevant chunks
            const relevantChunks = data.value.map(result => {
                return {
                    score: result['@search.score'],
                    text: result.text,
                    // Add other fields as necessary
                };
            });

            // Sort chunks by score (descending)
            relevantChunks.sort((a, b) => b.score - a.score);

            // Use the top chunks based on your criteria
            const topChunks = relevantChunks.slice(0, 3); // Example: top 3 chunks

            console.log('Top chunks:', topChunks);

        } catch (error) {
            console.error('Error processing search results:', error);

        }

        return data;
    }
    catch (error) {
        console.log('Error fetching answers from Azure Search:', error);
    }
}

//code to send chat message to Azure OpenAI model
async function getAnswersFromAzureOpenAIModel(userInput, aiModelName, persona, threadId) {

    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    const apiVersion = config.OPENAI_API_VERSION;
    const deploymentName = aiModelName;
    const openAIRequestBody = config.OPENAI_REQUEST_BODY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/chat/completions?api-version=${apiVersion}`;

    const userMessageContent = openAIRequestBody.messages.find(message => message.role === 'user').content[0];
    const getThoughtProcess = "Provide a step-by-step thought process for your answer. Results for the answer should be separate from your original response and surrounded by triple brackets.";

    userMessageContent.text = userInput;

    const systemMessageContent = openAIRequestBody.messages.find(message => message.role === 'system').content[0];
    systemMessageContent.text = persona;

    const jsonString = JSON.stringify(openAIRequestBody);

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const data = await response.json();

        // Extract the source documents from the response
        try {
            var sourceDocuments = "";

            if (data.choices[0].message.metadata == undefined) {
                sourceDocuments = "No source documents found.";
            }
            else {
                sourceDocuments = data.choices[0].message.metadata.sources;
            }
        }
        catch (error) {
            console.error('Error extracting source documents:', error);
        }

        var responseText = data.choices[0].message.content.trim();
        responseText = responseText.replace(/\*\*(.*?)\*\*:?/g, '<b class="bullet-title">$1:</b>:').trim();

        //only returning the first response
        return responseText;
    }
    catch (error) {
        if (error.code == 429) {

            const data = { error: 'Token rate limit exceeded. Please try again later.' };
            return data;
        }
        else {
            const data = { error: 'An error occurred. Please try again later.' };
            return data;
        }
    }
}

//code to send chat message to Bing Search API (still under development)
async function getAnswersFromPublicInternet(userInput) {

    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    const apiVersion = config.OPENAI_API_VERSION;
    const aiModels = config.AI_MODELS;
    const aiGPTModel = aiModels.find(item => item.Name === "gpt-4o");
    const deploymentName = aiGPTModel.Name;
    const openAIRequestBody = config.OPENAI_REQUEST_BODY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/chat/completions?api-version=${apiVersion}`;

    const userMessageContent = openAIRequestBody.messages.find(message => message.role === 'user').content[0];
    userMessageContent.text = userInput;

    const jsonString = JSON.stringify(openAIRequestBody);

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const data = await response.json();

        // Extract the source documents from the response
        try {
            var sourceDocuments = "";

            if (data.choices[0].message.metadata == undefined) {
                sourceDocuments = "No source documents found.";
            }
            else {
                sourceDocuments = data.choices[0].message.metadata.sources;
            }


        }
        catch (error) {
            console.error('Error extracting source documents:', error);
        }


        return data;
    }
    catch (error) {
        if (error.code == 429) {

            const data = { error: 'Token rate limit exceeded. Please try again later.' };
            return data;
        }
        else {
            const data = { error: 'An error occurred. Please try again later.' };
            return data;
        }
    }
}

// Function to show responses to questions
async function getChatResponse(questionBubble) {

    const config = await fetchConfig();

    const chatInput = document.getElementById('chat-input').value.trim();
    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.style.display = 'none';

    const chatCurrentQuestionContainer = document.getElementById('chat-info-current-question-container');
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const indexes = config.SEARCH_INDEXES;
    const searchServiceEndpoint = `https://${config.AZURE_SEARCH_SERVICE_NAME}.search.windows.net`;

    const indexName = indexes.filter(item => /vector-srch-index-copilot-demo-\d{3}/.test(item.Name))[0].Name;
    const metadata = { "user": "John Smith" };

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    // Create a map of documents using their key
    const docMap = new Map();

    // Get the selected chat persona
    const persona = getSelectedChatPersona();

    const toolResources = {
        "azure_ai_search": {
            "indexes": [
                {
                    "index_connection_id": searchServiceEndpoint,
                    "index_name": indexName
                }
            ]
        }
    };

    try {
        // First see if there is an existing thread
        if (threadId == null || threadId == undefined || threadId == "") {
            thread = await createThread(metadata, toolResources);
            threadId = thread.id;
        }
        else {
            thread = await getThread(threadId);
        }

    } catch (error) {
        console.log('Error getting thread ID:', error);
    }

    // Show the loading animation
    const loadingAnimation = document.querySelector('.loading-animation');
    loadingAnimation.style.display = 'flex';

    if (chatInput) {

        await addMessageToThread(threadId, chatInput, "user");

        const chatExamplesContainer = document.getElementById('chat-examples-container');
        chatExamplesContainer.style.display = 'none';

        // Get answers from Azure Search
        const docStorageResponse = await getAnswersFromAzureSearch(chatInput, "gpt-4o", indexName, false);

        // Get answers from Azure OpenAI model
        const openAIModelResults = await getAnswersFromAzureOpenAIModel(chatInput, "gpt-4o", persona);

        // Create a new chat bubble element
        const chatResponse = document.createElement('div');
        chatResponse.setAttribute('class', 'chat-response user slide-up'); // Add slide-up class
        chatResponse.setAttribute('id', `chat-response-${answerResponseNumber}`);

        const tabs = await createTabs();

        const thoughtProcessContent = document.createElement('div');
        thoughtProcessContent.className = 'tab-content';
        //thoughtProcessContent.style.fontStyle = 'italic';

        const supportingContent = document.createElement('div');
        supportingContent.className = 'tab-content';
        supportingContent.style.fontStyle = 'italic';

        const answerContent = document.createElement('div');
        answerContent.className = 'tab-content active';
        answerContent.style.fontStyle = 'italic';

        if (config.SEARCH_AZURE_OPENAI_MODEL == true) {
            answerContent.innerHTML += '<div id="openai-model-results-header">Results from Azure Generic OpenAI Model</div>';
            answerContent.innerHTML += `<div id="openai-model-results">${openAIModelResults}</div>`;

            const codeContent = document.createElement('div');
            codeContent.className = 'code-content';
            codeContent.innerHTML = 'Thought process content goes here.';
            thoughtProcessContent.appendChild(codeContent);
        }

        try {
            docStorageResponse.value.forEach(doc => {
                //var key = "Page " + doc.chunk_id.split('_pages_')[1];
                var key = doc.chunk_id;

                docMap.set(key, doc);
            });

            //This call to mapAnswersToDocSources is for the raw answers from Azure Search and used to populate the supporting content tab. 
            // //It needs to be the same data returned from the Azure Search call above completely untouched.
            const searchAnswers = docStorageResponse["@search.answers"];

            const rawAnswers = await mapAnswersToDocSources(searchAnswers, docMap, "gpt-4o", false);

            //const sortedAnswers = sortAnswers(docMap);

            // Create tab contents for supporting content
            createTabContentSupportingContent(rawAnswers, docStorageResponse, supportingContent, sasToken);

            // Get answers from Azure Search with embeddings

            //const docStorageResponseWithEmbeddings = await getAnswersFromAzureSearch(chatInput, "text-embedding-3-large", indexName, true);
            //const docStorageResponseWithEmbeddings = await getAnswersFromAzureSearch(chatInput, "gpt-4o", indexName, false);

            // Append tabs and contents to chat bubble
            chatResponse.appendChild(tabs);

            // Append the chat bubble to the chat-display div
            chatDisplay.appendChild(chatResponse);

            await createChatResponseContent(chatInput, rawAnswers, chatResponse, answerContent, sasToken, persona);

            chatResponse.appendChild(thoughtProcessContent);
            chatResponse.appendChild(supportingContent);

            setEqualHeightForTabContents();

            // Add event listeners to tabs
            const tabElements = tabs.querySelectorAll('.tab');
            const tabContents = chatResponse.querySelectorAll('.tab-content');

            setEqualHeightForTabContents();

            tabElements.forEach((tab, index) => {
                tab.addEventListener('click', () => {
                    tabElements.forEach(t => t.classList.remove('active'));
                    tabContents.forEach(tc => tc.classList.remove('active'));

                    tab.classList.add('active');
                    tabContents[index].classList.add('active');
                });
            });

            chatDisplay.style.display = 'block';

        } catch (error) {
            console.error('Error processing search results:', error);
        }

        // Hide the loading animation once results are returned
        loadingAnimation.style.display = 'none';

        // Clear the input field
        chatInput.value = '';

        // Scroll to the position right above the newest questionBubble
        const questionBubbleTop = chatResponse.offsetTop;
        chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

        questionBubble.style.display = 'block'; // Show the question bubble

        // Scroll to the position right above the newest questionBubble
        chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

        chatCurrentQuestionContainer.innerHTML = ''; // Clear the current question

    }
    else {
        loadingAnimation.style.display = 'none';
    }

    document.getElementById('expand-chat-svg-container').style.display = 'block';
    document.getElementById('jump-to-top-arrow').style.display = 'block';

    answerResponseNumber++;
}

//code to get documents from Azure Storage
async function getDocuments() {

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const fileTypes = config.FILE_TYPES;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    //const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;
    const storageUrl = config.AZURE_STORAGE_FULL_URL;

    try {
        const response = await fetch(`${storageUrl}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'text/xml',
                'Cache-Control': 'no-cache'
            }
        });

        if (response.ok) {
            const data = await response.text();
            // Parse the XML response
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(data, "text/xml");
            blobs = xmlDoc.getElementsByTagName("Blob");

            // Render documents
            //renderDocuments(blobs);
            renderDocumentsHtmlTable(blobs);
        } else {
            console.error('Failed to fetch documents:', response.statusText);
        }
    } catch (error) {
        console.error('Error fetching documents:', error);
    }
}

// Function to get messages from a thread
async function getMessagesFromThread(threadId) {

    //https://eastus.api.cognitive.microsoft.com/openai/threads/thread_hhKYL7GP2vvhM5j8D7TvetGT/messages?api-version=2024-08-01-preview
}

// Function to get SAS token from Azure Key Vault
async function getSasToken() {

    const config = await fetchConfig();

    const credential = new DefaultAzureCredential();
    const vaultName = config.KEY_VAULT_NAME;
    const url = `https://${vaultName}.vault.azure.net`;
    const client = new SecretClient(url, credential);

    const sasTokenConfig = {};
    const secretNames = ['SV', 'INCLUDE', 'SS', 'SRT', 'SP', 'SE', 'SPR', 'SIG'];

    for (const name of secretNames) {
        const secret = await client.getSecret(`AZURE_STORAGE_SAS_TOKEN_${name}`);
        sasTokenConfig[name] = secret.value;
    }

    return `sv=${sasTokenConfig.SV}&include=${sasTokenConfig.INCLUDE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;
}

// Function to get a thread for an AI conversation
async function getThread(threadId) {

    const config = await fetchConfig();
    const apiVersion = config.OPENAI_API_VERSION;
    const apiKey = config.AZURE_AI_SERVICE_API_KEY;

    const endpoint = `https://${config.REGION}.api.cognitive.microsoft.com/openai/threads/${threadId}?api-version=${apiVersion}`;

    try {
        const response = await fetch(endpoint, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            }
        });

        const thread = await response.json();

        return thread;
    }
    catch (error) {
        console.log('Error getting thread:', error);
    }

    return null;
}

//code to toggle between chat and document screens
function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

// Function to get the selected chat persona
function getSelectedChatPersona() {
    const selectedRadio = document.querySelector('input[name="chat-persona"]:checked');
    if (selectedRadio) {
        return selectedRadio.title;
    }
    return "";
}

// Function to check if a text is a question
function isQuestion(text) {
    const questionWords = ['who', 'what', 'where', 'when', 'why', 'how'];
    const words = text.trim().toLowerCase().split(/\s+/);
    return questionWords.includes(words[0]);
}

// Function to rephrase text
async function mapAnswersToDocSources(searchAnswers, docMap, aiModelName, openAIEnhanced) {

    const config = await fetchConfig();

    const apiVersion = config.OPENAI_API_VERSION;
    const aiModels = config.AI_MODELS;
    const aiModel = aiModels.find(item => item.Name === aiModelName);
    const apiKey = aiModel.ApiKey;
    const deploymentName = aiModel.Name;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/chat/completions?api-version=${apiVersion}`;

    const answers = [];

    // Iterate over the answers and cross-reference with documents
    searchAnswers.forEach(async answer => {
        var answerText = answer.text;
        var rephrasedResponseText = "";

        answerText = answerText.replace("  ", " ");
        if (answer.text) {
            const correspondingDoc = docMap.get(answer.key);
            if (correspondingDoc || openAIEnhanced) {

                try {
                    if (openAIEnhanced) {
                        //rephrasedResponseText = await rephraseResponseFromAzureOpenAI(answer.text, aiModel);
                        rephrasedResponseText = await rephraseResponseFromAzureOpenAI(`Rephrase the following text to sound more human: '${answer.text}'`, aiModel);
                    }
                    else {
                        rephrasedResponseText = answer.text;
                    }

                    answers.push({
                        text: rephrasedResponseText,
                        document: correspondingDoc
                    });
                } catch (error) {
                    answers.push({
                        text: answer.text,
                        document: correspondingDoc
                    });
                }
            }
        }
    });

    return answers;
}

// Function to post a question to the chat display
async function postQuestion() {

    const config = await fetchConfig();

    let chatInput = document.getElementById('chat-input').value;
    const chatDisplay = document.getElementById('chat-display');
    const chatCurrentQuestionContainer = document.getElementById('chat-info-current-question-container');
    const dateTimestamp = new Date().toLocaleString();

    // Check if chatInput ends with a question mark, if not, add one
    if (!chatInput.trim().endsWith('?') && isQuestion(chatInput)) {
        chatInput += '?';
    }

    // Capitalize the first letter if it is not already capitalized
    if (chatInput.length > 0 && chatInput[0] !== chatInput[0].toUpperCase()) {
        chatInput = chatInput[0].toUpperCase() + chatInput.slice(1);
    }

    // Create a new div for the chat bubble
    const questionBubble = document.createElement('div');
    questionBubble.setAttribute('class', 'question-bubble fade-in'); // Add fade-in class

    const svg = document.createElement("div");
    svg.className = 'question-bubble-svg';
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

    questionBubble.style.display = 'none'; // Hide the question bubble initially

    // Append the chat bubble to the chat-info div
    chatDisplay.appendChild(questionBubble);

    const chatCurrentQuestionBubble = questionBubble.cloneNode(true);
    chatCurrentQuestionBubble.style.display = 'block'; // Show the current question bubble

    chatCurrentQuestionContainer.innerHTML = ''; // Clear the current question
    chatCurrentQuestionContainer.appendChild(chatCurrentQuestionBubble);

    // Scroll to the position right above the newest questionBubble
    const questionBubbleTop = questionBubble.offsetTop;
    chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

    getChatResponse(questionBubble);
}

// Function to render chat personas
async function renderChatPersonas() {
    const config = await fetchConfig();

    const chatPersonas = config.CHAT_PERSONAS;

    const chatPersonasContainer = document.getElementById('chat-personas-container');

    chatPersonas.innerHTML = '';

    chatPersonas.forEach(persona => {
        const chatPersona = document.createElement('div');

        chatPersona.className = 'chat-persona';

        const chatRadioButtonChecked = persona.Type === 'Default' ? 'checked' : '';

        chatPersona.innerHTML = `<div class="form-group form-group-flex">
                    <div>
                        <input type="radio" ${chatRadioButtonChecked} class="chat-persona-radio" name="chat-persona" title="${persona.Prompt}" id="chat-persona-${persona.Type}" />
                    </div>
                    <div>
                        <label for="chat-persona-icons">${persona.Type}</label>
                    </div>
                </div>`;

        chatPersonasContainer.appendChild(chatPersona);
    });


}

// Function to render documents
async function renderDocuments(blobs) {

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const fileTypes = config.FILE_TYPES;

    const docList = document.getElementById('document-list');
    const sampleRows = document.querySelectorAll('.document-row.sample');

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    //const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;
    const storageUrl = config.AZURE_SEARCH_FULL_URL;

    // Clear existing document rows except the header
    const existingRows = docList.querySelectorAll('.document-row:not(.header)');
    existingRows.forEach(row => row.style.display = 'none');

    if (blobs.length === 0) {
        // Show sample rows if no results
        sampleRows.forEach(row => row.style.display = '');
    } else {
        // Hide sample rows if there are results
        sampleRows.forEach(row => row.style.display = 'none');

        // Extract blob data into an array of objects
        const blobData = Array.from(blobs).map(blob => {
            const blobName = blob.getElementsByTagName("Name")[0].textContent;
            const lastModified = new Date(blob.getElementsByTagName("Last-Modified")[0].textContent).toLocaleString('en-US', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: true
            });
            const contentType = blob.getElementsByTagName("Content-Type")[0].textContent.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
            let blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;
            blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = formatBytes(parseInt(blob.getElementsByTagName("Content-Length")[0].textContent));
            return { blobName, lastModified, contentType, blobUrl, blobSize };
        });

        // Iterate over the sorted blob data and create document rows
        blobData.forEach(blob => {
            // Create the document row
            const documentRow = document.createElement('div');
            documentRow.className = 'document-row';

            const blobName = blob.blobName;
            const lastModified = blob.lastModified;
            const contentType = blob.contentType.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
            let blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;
            //blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = blob.blobSize;

            // Create the document cells
            const previewCell = document.createElement('div');
            previewCell.className = 'document-cell preview';

            previewCell.innerHTML = `<span class="mud-fab-label" style="display: flex !important"><button class="magnifyButton mud-button-root mud-fab mud-fab-primary mud-fab-size-small mud-ripple"><a href="${blobUrl}" target="_blank">${config.ICONS.MAGNIFYING_GLASS.MONOTONE}</a></button></span>`;

            const statusCell = document.createElement('div');
            statusCell.className = 'document-cell preview';
            statusCell.textContent = 'Active';

            const nameCell = document.createElement('div');
            nameCell.className = 'document-cell';
            const nameLink = document.createElement('a');
            nameLink.href = blobUrl;
            nameLink.textContent = blobName;
            nameLink.target = '_blank'; // Open link in a new tab
            nameCell.appendChild(nameLink);

            const contentTypeCell = document.createElement('div');
            contentTypeCell.className = 'document-cell content-type';

            let fileTypeFound = false;
            for (const [key, value] of Object.entries(fileTypes)) {
                const svgStyle = iconStyle === 'color' ? `${value.SVG_COLOR}` : `${value.SVG}`;
                if (value.EXTENSION.some(ext => blobName.toLowerCase().endsWith(ext))) {
                    contentTypeCell.innerHTML = `<code>${contentType}</code>`;
                    fileTypeFound = true;
                    break;
                }
            }

            if (!fileTypeFound) {
                const svgStyle = iconStyle === 'color' ? `${fileTypes.TXT.SVG_COLOR}` : `${fileTypes.TXT.SVG}`;
                contentTypeCell.innerHTML = `<code>${contentType}</code>`;
            }

            const fileSizeCell = document.createElement('div');
            fileSizeCell.className = 'document-cell';
            fileSizeCell.innerHTML = `<div class="file-size mud-chip mud-chip-filled mud-chip-size-small mud-chip-color-default"><span class="mud-chip-content">${blobSize}</span></div>`;

            const lastModifiedCell = document.createElement('div');
            lastModifiedCell.className = 'document-cell';
            lastModifiedCell.textContent = lastModified;

            const deleteCell = document.createElement('div');
            deleteCell.className = 'document-cell action-delete';
            deleteCell.innerHTML = `<a href="#" class="delete-button">${config.ICONS.DELETE.COLOR}${config.ICONS.DELETE.MONOTONE}</a>`;

            const editCell = document.createElement('div');
            editCell.className = 'document-cell action-edit';
            editCell.innerHTML = `<a href="#" class="edit-button">${config.ICONS.EDIT.COLOR}${config.ICONS.EDIT.MONOTONE}</a>`;

            const actionCell = document.createElement('div');
            actionCell.className = 'document-cell action-container';
            actionCell.appendChild(deleteCell);
            actionCell.appendChild(editCell);

            // Append cells to the document row
            documentRow.appendChild(previewCell);
            documentRow.appendChild(statusCell);
            documentRow.appendChild(nameCell);
            documentRow.appendChild(contentTypeCell);
            documentRow.appendChild(fileSizeCell);
            documentRow.appendChild(lastModifiedCell);
            documentRow.appendChild(actionCell);
            // Append the document row to the document list
            docList.appendChild(documentRow);
        });
    }
}

async function renderDocumentsHtmlTable(blobs) {

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const fileTypes = config.FILE_TYPES;

    const docList = document.getElementById('document-table-body');
    const sampleRows = document.querySelectorAll('.document-row.sample');

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    // Clear existing document rows except the header
    const existingRows = docList.querySelectorAll('document-table .document-row:not(.header)');
    existingRows.forEach(row => row.style.display = 'none');

    if (blobs.length === 0) {
        // Show sample rows if no results
        sampleRows.forEach(row => row.style.display = '');
    } else {
        // Hide sample rows if there are results
        sampleRows.forEach(row => row.style.display = 'none');

        // Extract blob data into an array of objects
        const blobData = Array.from(blobs).map(blob => {
            const blobName = blob.getElementsByTagName("Name")[0].textContent;
            const lastModified = new Date(blob.getElementsByTagName("Last-Modified")[0].textContent).toLocaleString('en-US', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: true
            });
            const contentType = blob.getElementsByTagName("Content-Type")[0].textContent.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
            let blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;
            blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = formatBytes(parseInt(blob.getElementsByTagName("Content-Length")[0].textContent));
            return { blobName, lastModified, contentType, blobUrl, blobSize };
        });

        // Iterate over the sorted blob data and create document rows
        blobData.forEach(blob => {
            // Create the document row
            const documentRow = document.createElement('tr');
            documentRow.className = 'document-row';

            const blobName = blob.blobName;
            const lastModified = blob.lastModified;
            const contentType = blob.contentType.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
            let blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;
            //blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = blob.blobSize;

            // Create the document cells
            const previewCell = document.createElement('td');
            previewCell.className = 'document-cell preview';

            previewCell.innerHTML = `<span class="mud-fab-label" style="display: flex !important"><button class="magnifyButton mud-button-root mud-fab mud-fab-primary mud-fab-size-small mud-ripple"><a href="${blobUrl}" target="_blank">${config.ICONS.MAGNIFYING_GLASS.MONOTONE}</a></button></span>`;

            const statusCell = document.createElement('td');
            statusCell.className = 'document-cell preview';
            statusCell.textContent = 'Active';

            const nameCell = document.createElement('td');
            nameCell.className = 'document-cell';
            const nameLink = document.createElement('a');
            nameLink.href = blobUrl;
            nameLink.textContent = blobName;
            nameLink.target = '_blank'; // Open link in a new tab
            nameCell.appendChild(nameLink);

            const contentTypeCell = document.createElement('td');
            contentTypeCell.className = 'document-cell content-type';

            let fileTypeFound = false;
            for (const [key, value] of Object.entries(fileTypes)) {
                const svgStyle = iconStyle === 'color' ? `${value.SVG_COLOR}` : `${value.SVG}`;
                if (value.EXTENSION.some(ext => blobName.toLowerCase().endsWith(ext))) {
                    contentTypeCell.innerHTML = `<code>${contentType}</code>`;
                    fileTypeFound = true;
                    break;
                }
            }

            if (!fileTypeFound) {
                const svgStyle = iconStyle === 'color' ? `${fileTypes.TXT.SVG_COLOR}` : `${fileTypes.TXT.SVG}`;
                contentTypeCell.innerHTML = `<code>${contentType}</code>`;
            }

            const fileSizeCell = document.createElement('td');
            fileSizeCell.className = 'document-cell';
            fileSizeCell.innerHTML = `<td class="file-size mud-chip mud-chip-filled mud-chip-size-small mud-chip-color-default"><span class="mud-chip-content">${blobSize}</span></td>`;

            const lastModifiedCell = document.createElement('td');
            lastModifiedCell.className = 'document-cell';
            lastModifiedCell.textContent = lastModified;

            const deleteCell = document.createElement('td');
            deleteCell.className = 'document-cell action-delete';
            deleteCell.innerHTML = `<a href="#" class="delete-button">${config.ICONS.DELETE.COLOR}${config.ICONS.DELETE.MONOTONE}</a>`;

            const editCell = document.createElement('td');
            editCell.className = 'document-cell action-edit';
            editCell.innerHTML = `<a href="#" class="edit-button">${config.ICONS.EDIT.COLOR}${config.ICONS.EDIT.MONOTONE}</a>`;

            const actionCell = document.createElement('td');
            actionCell.className = 'document-cell action-container';
            actionCell.appendChild(deleteCell);
            actionCell.appendChild(editCell);

            // Append cells to the document row
            documentRow.appendChild(previewCell);
            documentRow.appendChild(statusCell);
            documentRow.appendChild(nameCell);
            documentRow.appendChild(contentTypeCell);
            documentRow.appendChild(fileSizeCell);
            documentRow.appendChild(lastModifiedCell);
            documentRow.appendChild(actionCell);
            // Append the document row to the document list
            docList.appendChild(documentRow);
        });
    }
}

// Function to rephrase text using Azure OpenAI Service
async function rephraseResponseFromAzureOpenAI(userInput, aiModel) {

    const config = await fetchConfig();

    const apiVersion = config.OPENAI_API_VERSION;
    const aiModels = config.AI_MODELS;
    const apiKey = aiModel.ApiKey;
    const deploymentName = aiModel.Name;
    const openAIRequestBody = config.OPENAI_REQUEST_BODY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/chat/completions?api-version=${apiVersion}`;

    const userMessageContent = openAIRequestBody.messages.find(message => message.role === 'user').content[0];
    userMessageContent.text = userInput;

    const answers = [];

    const jsonString = JSON.stringify(openAIRequestBody)

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': apiKey
            },
            body: jsonString
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Error: ${errorData.error.message}`);
        }

        const data = await response.json();
        return data.choices[0].message.content.trim();
    } catch (error) {
        console.error('Error rephrasing text:', error);
        return "error";
        //throw error;
    }
}

// Function to run Search Indexer after new file is uploaded
async function runSearchIndexer(searchIndexers) {

    const config = await fetchConfig();

    const apiKey = config.AZURE_SEARCH_API_KEY;
    const searchServiceName = config.AZURE_SEARCH_SERVICE_NAME;
    const searchServiceApiVersion = config.AZURE_SEARCH_API_VERSION;

    // Iterate over the search indexers and run each one
    searchIndexers.forEach(searchIndexer => {

        var searchIndexerName = searchIndexer.Name;
        //var searchIndexName = searchIndexer.IndexName;
        //var searchIndexerSchema = searchIndexer.Schema;

        var searchIndexerUrl = `https://${searchServiceName}.search.windows.net/indexers/${searchIndexerName}/run?api-version=${searchServiceApiVersion}`;

        var headers = {
            'api-key': apiKey,
            'Content-Type': 'application/json',
            'mode': 'no-cors',
        };

        // Invoke the REST method to run the search indexer
        try {
            fetch(searchIndexerUrl, {
                method: 'POST',
                headers: headers
            })
                .then(response => response.json())
                .then(data => console.log('Indexer run response:', data))
                .catch(error => console.error('Error running indexer:', error));
        } catch (error) {
            console.error(`Error running search indexer`, error.message);
        }
    });
}

// Function to set the height of the chat display container
function setChatDisplayHeight() {
    const chatDisplayContainer = document.getElementById('chat-display-container');
    const chatInfoTextCopy = document.getElementById('chat-info-text-copy');

    const windowHeight = window.innerHeight - (chatInfoTextCopy.offsetHeight + 200);

    // Calculate the desired height (e.g., 80% of the window height)
    const desiredHeight = windowHeight * 0.65;

    if (chatDisplayContainer.style.height == "") {
        // Set the height of the chat-display-container
        chatDisplayContainer.style.height = `${desiredHeight}px`;
    }
    else {
        chatDisplayContainer.style.height = "";
    }
}

// Function to set equal height for all tab-content divs
function setEqualHeightForTabContents() {
    const tabContents = document.querySelectorAll('.tab-content');
    let maxHeight = 0;

    // Calculate the maximum height
    tabContents.forEach(tabContent => {
        const height = tabContent.offsetHeight;
        if (height > maxHeight) {
            maxHeight = height;
        }
    });

    // Set the maximum height to all tab-content divs
    tabContents.forEach(tabContent => {
        tabContent.style.height = `${maxHeight}px`;
    });
}

// Function to set the site logo
async function setSiteLogo() {

    const config = await fetchConfig();

    const siteLogo = document.getElementById('site-logo');
    const siteLogoText = document.getElementById('site-logo-text');
    const siteLogoTextCopy = document.getElementById('site-logo-text-copy');



    if (config.SITE_LOGO == "default" || getQueryParam('sitelogo') == "default") {
        siteLogo.src = "images/site-logo-default.png";
        siteLogo.classList.remove('site-logo-custom');
        siteLogo.classList.add('site-logo-default');
    }
    else {
        siteLogo.src = "images/site-logo-custom.png";
        siteLogo.classList.remove('site-logo-default');
        siteLogo.classList.add('site-logo-custom');
    }
}

// Function to show a toast notification
function showToastNotification(message, isSuccess) {
    // Remove existing toast notifications
    const existingToasts = document.querySelectorAll('.toast-notification');
    existingToasts.forEach(toast => toast.remove());

    // Create a new div for the toast notification
    const toastNotification = document.createElement('div');
    toastNotification.setAttribute('class', 'toast-notification fade-in');
    toastNotification.style.backgroundColor = isSuccess ? 'rgba(34, 139, 34, 0.9)' : 'rgb(205, 92, 92, 0.9)';

    // Create a close button
    const closeButton = document.createElement('span');
    closeButton.setAttribute('class', 'close-button');
    closeButton.innerHTML = '&times;';
    closeButton.onclick = function () {
        toastNotification.style.display = 'none';
    };

    // Create the message text
    const messageText = document.createElement('div');
    messageText.setAttribute('class', 'toast-message');
    messageText.innerHTML = message;

    // Append the close button and message text to the toast notification

    toastNotification.appendChild(messageText);
    toastNotification.appendChild(closeButton);

    // Append the toast notification to the body
    document.body.appendChild(toastNotification);

    // Automatically remove the toast notification after 5 seconds
    setTimeout(() => {
        toastNotification.style.display = 'none';
    }, 5000);
}

// Function to sort answers
function sortAnswers(docMap) {
    try {
        // Convert Map to an array for sorting
        const docArray = Array.from(docMap.values());

        docArray.sort((a, b) => {
            if (a.key < b.key) {
                return -1;
            }
            if (a.key > b.key) {
                return 1;
            }
            return 0;
        });

        // Convert sorted array back to Map
        const sortedDocMap = new Map(docArray.map(doc => [doc.chunk_id, doc]));

        return sortedDocMap;

    }
    catch (error) {
        return "error";
    }
}

// Function to sort documents
function sortDocuments(criteria) {
    const sortDirection = currentSortColumn === criteria && currentSortDirection === 'asc' ? 'desc' : 'asc';
    currentSortColumn = criteria;
    currentSortDirection = sortDirection;

    criteria = criteria.toLowerCase();

    const sortedBlobs = Array.from(blobs).sort((a, b) => {
        const aValue = a.getElementsByTagName(criteria)[0].textContent.toLowerCase();
        const bValue = b.getElementsByTagName(criteria)[0].textContent.toLowerCase();
        if (aValue < bValue) return sortDirection === 'asc' ? -1 : 1;
        if (aValue > bValue) return sortDirection === 'asc' ? 1 : -1;
        return 0;
    });

    // Update sort arrows
    document.querySelectorAll('.sort-arrow').forEach(arrow => arrow.classList.remove('active'));
    const arrow = document.getElementById(`${criteria}-arrow`);
    if (arrow) {
        arrow.classList.add('active');
        arrow.innerHTML = sortDirection === 'asc' ? '&#9650;' : '&#9660;';
    }

    renderDocuments(sortedBlobs);
}

// Function to toggle all checkboxes
function toggleAllCheckboxes() {

    const allCheckbox = document.getElementById('datasource-all');
    const datasourceCheckboxes = document.querySelectorAll('input[type="checkbox"][id^="datasource-"]:not(#datasource-all)');

    datasourceCheckboxes.forEach(checkbox => {
        checkbox.checked = allCheckbox.checked;
    });
}

//code to toggle between chat and document screens
function toggleDisplay(screen) {
    const $chatContainer = $('#chat-container');
    const $documentContainer = $('#document-container');
    const $homeContainer = $('#home-container');

    if (screen === 'chat') {
        $chatContainer.show();
        $documentContainer.hide();
        $homeContainer.hide();
    } else if (screen === 'documents') {
        $chatContainer.hide();
        $homeContainer.hide();
        $documentContainer.show();
    } else if (screen === 'home') {
        $chatContainer.hide();
        $documentContainer.hide();
        $homeContainer.show();
    } else {
        $chatContainer.hide();
        $documentContainer.hide();
        $homeContainer.show();
    }
}

// Function to update the file count
function updateFileCount() {
    const fileCount = document.getElementById('file-input').files.length;
    document.getElementById('file-count').textContent = `Files selected: ${fileCount}`;
}

async function updateMessage(threadId, messageId, metadata) {
    const config = await fetchConfig();
    const apiVersion = config.OPENAI_API_VERSION;
    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    //const openAIRequestBody = config.OPENAI_REQUEST_BODY;

    const endpoint = `https://${config.REGION}.api.cognitive.microsoft.com/openai/threads/${threadId}/messages/${messageId}?api-version=${apiVersion}`;

    const jsonMetadata = JSON.stringify(metadata);
    const jsonString = `{ "metadata": ${jsonMetadata} }`;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const data = await response.json();

        console.log(`Message ${messageId} updated:`, data);
    }
    catch (error) {
        console.log(`Error updating message ${messageId}:`, error);
    }
}

//code to update placeholder text
function updatePlaceholder() {
    const noFilesPlaceholder = document.getElementById('num-files-selected-placeholder');
    const fileList = document.getElementById('file-list');
    const files = document.getElementById('file-input').files;
    const uploadButton = document.getElementById('upload-button');

    const fileCount = files.length;
    let totalSize = 0;

    for (let i = 0; i < fileCount; i++) {
        totalSize += files[i].size;
    }

    // Convert total size to KB
    const totalSizeKB = (totalSize / 1024).toFixed(2);
    if (fileCount === 0) {
        noFilesPlaceholder.textContent = 'No files selected';
        noFilesPlaceholder.style.display = 'block';
        uploadButton.disabled = true;
    } else {
        noFilesPlaceholder.textContent = `${fileCount} file(s) selected (${totalSizeKB} KB)`;
        noFilesPlaceholder.style.display = 'block';
        uploadButton.disabled = false;
    }
}

async function updateThread(threadId, metadata, toolResources) {

    const config = await fetchConfig();
    const apiVersion = config.OPENAI_API_VERSION;
    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    //const openAIRequestBody = config.OPENAI_REQUEST_BODY;

    const endpoint = `https://${config.REGION}.api.cognitive.microsoft.com/openai/threads/${threadId}?api-version=${apiVersion}`;

    const jsonMetadata = JSON.stringify(metadata);
    const jsonToolResources = JSON.stringify(toolResources);

    const jsonString = `{ "metadata": ${jsonMetadata}, "tool_resources": ${jsonToolResources} }`;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`,
                'http2': 'true'
            },
            body: jsonString
        });

        const data = await response.json();

        console.log(`Thread: ${threadId} updated.`, data);
    }
    catch (error) {
        console.log(`Error updating thread ${threadId} :`, error);
    }
}

//code to upload files to Azure Storage
async function uploadFilesToAzure(files) {

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const apiVersion = config.AZURE_STORAGE_API_VERSION;
    const searchIndexers = config.SEARCH_INDEXERS;
    const fileTypes = config.FILE_TYPES;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&include=${sasTokenConfig.INCLUDE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;

    for (const file of files) {
        const fileName = file.name.replace("#", "");
        const uploadUrl = `${storageUrl}/${fileName}?&${sasToken}`;
        const date = new Date().toUTCString();

        try {
            const response = await fetch(uploadUrl, {
                method: 'PUT',
                headers: {
                    'x-ms-blob-type': 'BlockBlob',
                    'Content-Type': file.type,
                    'Content-Length': file.size.toString(),
                    'x-ms-date': date,
                    'x-ms-version': apiVersion,
                    'x-ms-blob-content-type': file.type,
                    'x-ms-blob-type': 'BlockBlob'
                },
                body: file
            });

            if (response.ok) {
                showToastNotification(`Upload successful for ${file.name}.`, true);
                console.log(`Upload successful for ${file.name}.`);
                getDocuments(); // Refresh the document list after successful upload
            } else {
                const errorText = await response.text();
                showToastNotification(`Error uploading file ${file.name} to Azure Storage: ${errorText}`, false);
                console.error(`Error uploading file ${file.name} to Azure Storage:`, errorText);
            }
        } catch (error) {
            console.error(`Error uploading file ${file.name} to Azure Storage:`, error.message);
        }
    }
    // Clear the file input after successful upload
    clearFileInput();

    //The isn't working yet because of permissions issues
    //await runSearchIndexer(searchIndexers);
}