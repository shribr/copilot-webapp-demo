var iconStyle = "color";
let blobs = [];
let currentSortColumn = '';
let currentSortDirection = 'asc';
let answerResponseNumber = 1;
let aiEnhancedAnswersArray = [];

let thread = { "messages": [] };

let tool_resources = {
    "azure_ai_search": {
        "indexes": [
            {
                "index_connection_id": "",
                "index_name": ""
            }
        ]
    }
};

$(document).ready(async function () {

    //setChatDisplayHeight();

    hideLeftNav();

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const magnifyingGlassIcon = config.ICONS.MAGNIFYING_GLASS.MONOTONE;
    const editIcon = config.ICONS.EDIT.MONOTONE;
    const deleteIcon = config.ICONS.DELETE.MONOTONE;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    const fullStorageUrl = storageUrl + `?comp=list&include=metadata&restype=container&${sasToken}`;

    setSiteLogo();

    getDocuments(blobs, storageUrl, fullStorageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon);

    const chatDisplayContainer = document.getElementById('chat-display-container');
    const chatDisplay = document.getElementById('chat-display');
    const loadingAnimation = document.createElement('div');

    loadingAnimation.setAttribute('class', 'loading-animation');
    loadingAnimation.innerHTML = '<div class="spinner"></div> Fetching results...';
    loadingAnimation.style.display = 'none'; // Hide it initially
    chatDisplayContainer.insertBefore(loadingAnimation, chatDisplay);

    $('#send-button').on('click', postQuestion);
    $('#clear-button').on('click', clearChatDisplay);

    if (document.getElementById('chat-input').value.trim() === '') {
        $('#send-button').prop('disabled', true);
    }
    else {
        $('#send-button').prop('disabled', false);
    }

    document.getElementById('hamburger-menu').addEventListener('click', function () {
        const leftNav = document.getElementById('left-nav-container');
        leftNav.style.display = (leftNav.style.display === 'block' || leftNav.style.display === 'block !important' || leftNav.style.display === "") ? 'none' : 'block';
    });

    const chatInput = document.getElementById('chat-input');

    chatInput.addEventListener('keyup', function () {
        if (chatInput.value.trim() === '') {
            $('#send-button').prop('disabled', true);
            //$('#send-button').addClass('button-disabled');
        }
        else {
            $('#send-button').prop('disabled', false);
            //$('#send-button').removeClass('button-disabled');
        }
    });

    $(document).on('keydown', function (event) {
        if (event.key === 'Enter') {
            postQuestion();
        }
    });

    document.addEventListener('click', function (event) {
        const settingsDialog = document.getElementById('settings-dialog');
        const settingsOverlay = document.getElementById('settings-overlay');

        const leftNavContainer = document.getElementById('left-nav-container');

        const width = window.innerWidth;
        const height = window.innerHeight;

        if (settingsDialog.style.display === 'block' && !settingsDialog.contains(event.target) && !document.getElementById('link-settings').contains(event.target)) {
            settingsDialog.style.display = 'none';
            settingsOverlay.style.display = 'none';
        }

        if (width < 601 && leftNavContainer.style.display === 'block' && !leftNavContainer.contains(event.target) && !document.getElementById('hamburger-menu').contains(event.target)) {
            leftNavContainer.style.display = 'none';
        }
    });

    // ...existing code...

    window.addEventListener('resize', function () {
        const width = window.innerWidth;
        const height = window.innerHeight;

        // Add your resize logic here
        console.log(`Window resized to width: ${width}, height: ${height}`);

        // Example: Adjust the display of leftNavContainer based on the new width
        const leftNavContainer = document.getElementById('left-nav-container');
        if (width > 600) {
            leftNavContainer.style.display = 'block';
        } else {
            leftNavContainer.style.display = 'none';
        }
    });

    // ...existing code...

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

        showSettingsDialog();

        // Handle settings click
        console.log('Settings clicked');
    });

    document.getElementById('settings-container').addEventListener('click', function (event) {
        event.preventDefault();

        showSettingsDialog();

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

// Function to build chat history
function addMessageToChatHistory(thread, message) {
    //code to build chat history
    thread.messages.push(message);

    console.log(thread);
}

// Function to clear the chat display
function clearChatDisplay() {
    const chatDisplayContainer = document.getElementById('chat-display-container');
    const chatInfoCurrentQuestionContainer = document.getElementById('chat-info-current-question-container');

    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.innerHTML = ''; // Clear all content

    chatInfoCurrentQuestionContainer.innerHTML = ''; // Clear the current question

    const loadingAnimation = document.createElement('div');
    loadingAnimation.setAttribute('class', 'loading-animation');
    loadingAnimation.innerHTML = '<div class="spinner"></div> Fetching results...';
    loadingAnimation.style.display = 'none'; // Hide it initially
    chatDisplayContainer.appendChild(loadingAnimation);

    document.getElementById('expand-chat-svg-container').style.display = 'none';
    document.getElementById('jump-to-top-arrow').style.display = 'none';

    thread.messages = []; // Clear the chat history
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
function createChatResponseContent(azureOpenAIResults, chatResponse, answerContent, persona, storageUrl, sasToken, downloadChatResultsSVG) {

    var sourceNumber = 0;
    var citationContentResults = "";
    var openAIModelResultsId = "";
    var answers = "";

    // Initialize a Set to store unique document paths
    const listedPaths = new Set();

    var footNoteLinks = "";

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults.error) {

        // Loop through the answers and create the response content   
        for (const choice of azureOpenAIResults[0].choices) {

            console.log(`Choice: ${choice}`);

            const answer = choice.message;
            const role = answer.role;
            var answerText = answer.content.replace(/\*\*/g, "").replace(/\s+/g, " ");
            var followUpQuestions = answerText.split("$$$$")[2].trim();

            //followUpQuestions = followUpQuestions.replace('<li>', '<li class="followup-questions">');

            answerText = answerText.split("$$$$")[0];

            const message = { "role": role, "content": answerText };

            if (answerText.startsWith("The requested information is not available in the retrieved data.")) {
                answerText = persona.NoResults;
            }
            else {
                addMessageToChatHistory(thread, message);
            }

            const context = answer.context;

            const citations = context.citations;

            if (citations) {

                console.log(`Citations: ${citations}`);

                for (const citation of citations) {
                    const docTitle = citation.title;
                    //const docTitle = toProperCase(citation.title);;
                    const docUrl = `${storageUrl}/${docTitle}?${sasToken}`;

                    //https://stcopilotdemo005.blob.core.windows.net/content/Fy22_all_staff-626645-v1-ecm_implementation__posted__pws__attachment_f_ecm_reference_and_target_architecture_final.docx?sv=2022-11-02&ss=bfqt&srt=co&sp=rwdxylacupfti&se=2026-01-05T23:59:59Z&spr=https&sig=7Fbqeh9M%2B4be9Rbq38qrhUocLLZiiI9nOr9Fb6X7fGo%3D
                    //https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fstcopilotdemo005.blob.core.windows.net%2Fcontent%2FFY22_ALL_STAFF-626662-v4-ECM_IMPLEMENTATION__POSTED__PWS.docx%3Fsv%3D2022-11-02%26ss%3Dbfqt%26srt%3Dco%26sp%3Drwdxylacupfti%26se%3D2026-01-05T23%3A59%3A59Z%26spr%3Dhttps%26sig%3D7Fbqeh9M%252B4be9Rbq38qrhUocLLZiiI9nOr9Fb6X7fGo%253D&wdOrigin=BROWSELINK
                    //https://stcopilotdemo005.blob.core.windows.net/content/power-pages-guidance.pdf?sv=2022-11-02&ss=bfqt&srt=co&sp=rwdxylacupfti&se=2026-01-05T23:59:59Z&spr=https&sig=7Fbqeh9M%2B4be9Rbq38qrhUocLLZiiI9nOr9Fb6X7fGo%3D

                    // Detect and replace [doc*] with [page *] and create hyperlink
                    answerText = answerText.replace(/\[doc(\d+)\]/g, (match, p1) => {
                        return `<sup class="answer-citations page-number"><a href="${docUrl}#page=${p1}" target="_blank">[page ${p1}]</a></sup>`;
                    });

                    if (!listedPaths.has(docTitle)) {
                        listedPaths.add(docTitle);

                        sourceNumber++;

                        const supportingContentLink = `<a class="answer-citations" title="${docTitle}" href="${docUrl}" style="text-decoration: underline" target="_blank">${sourceNumber}. ${truncateText(docTitle, 90)}</a>`;

                        citationContentResults += `<div id="answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${supportingContentLink}</div>`;

                        footNoteLinks += `<sup class="answer-citations"><a title="${docTitle}" href="#answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${sourceNumber}</a></sup>`;
                    }
                    else {
                        console.log(`Document already listed: ${docTitle}`);
                    }

                }
            }

            const answerListHTML = '<div class="answer-results">' + answerText + footNoteLinks + '</div>';

            answers += answerListHTML;

        }

    }
    else {
        const answerListHTML = `<div class="answer-results">${persona.NoResults}</div>`;

        answers += answerListHTML;
    }

    answerContent.innerHTML += '<div id="openai-model-results-header">Search Results</div>';

    const openAIModelResultsContainerId = `openai-model-results-container-${answerResponseNumber}`;
    openAIModelResultsId = `openai-model-results-${answerResponseNumber}`;

    if (answers.length > 0) {
        answerContent.innerHTML += `<div id="${openAIModelResultsContainerId}" class="openai-model-results"><div id="${openAIModelResultsId}"><div class="ai-enhanced-answer-results">${answers}</div><br/></div>`;
        answerContent.innerHTML += `<div id="followup-questions-container"><h6 class="followup-question">Suggested Follow Up Questions:</h6>${followUpQuestions}</div>`;
        answerContent.innerHTML += `<div id="answer-sources-container"><h6 class="answer-sources">Sources:</h6>${citationContentResults}</div ></div> `;
    }
    else {
        answerContent.innerHTML += `<div id = "${openAIModelResultsId}"> No results found.</div>`;
    }

    chatResponse.appendChild(answerContent);

    // Add download chat results button
    if (openAIModelResultsId != "" && openAIModelResultsId != undefined) {

        const openAIResultsContainer = document.getElementById(openAIModelResultsId);

        const downloadChatResultsContainer = document.createElement('div');
        downloadChatResultsContainer.id = `download - chat - results - container - ${answerResponseNumber} `;
        downloadChatResultsContainer.className = 'download-chat-results-container';

        const downloadChatResultsButtonId = `download - chat - results - button - ${answerResponseNumber} `;

        const downloadChatResultsButton = `<div id = "${downloadChatResultsButtonId}" onclick = "downloadChatResults()" class="download-chat-results-button">${downloadChatResultsSVG}</div> `;

        downloadChatResultsContainer.innerHTML = downloadChatResultsButton;

        openAIResultsContainer.appendChild(downloadChatResultsContainer);

        document.getElementById(downloadChatResultsButtonId).addEventListener('click', downloadChatResults);
    }

}

// Function to collect chat results
function collectChatResults(chatResultsId) {
    const chatDisplay = document.getElementById(`${chatResultsId} `);
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
                sidenavLink.setAttribute('id', `sidenav - item - ${key} `);
                sidenavLink.innerHTML = `${value.SVG} ${value.TEXT} `;

                sidenavItem.appendChild(sidenavLink);
                sidenav.appendChild(sidenavItem);

                console.log(`Key: ${key}, Text: ${value.TEXT} `);
            }
        } else {
            console.error('sidenavLinks is not an array:', sidenavLinks);
        }
    } catch (error) {
        console.error('Failed to create sidenav links:', error);
    }
}

// Function to create tabs
function createTabs(responseTabs) {

    const tabs = document.createElement('div');
    tabs.className = 'tabs';

    // Loop through CHAT_TABS to create tabs dynamically

    for (let index = 0; index < responseTabs.length; index++) {
        const [key, value] = responseTabs[index];
        const tab = document.createElement('div');
        tab.className = `tab ${index === 0 ? 'active' : ''} `;
        tab.id = value.ID;
        tab.innerHTML = `${value.SVG} ${value.TEXT} `;
        tabs.appendChild(tab);
    }

    return tabs;
}

// Function to create tab contents for follow-up questions
function createFollowUpQuestionsContent(azureOpenAIResults, followUpQuestionsContent) {

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults.error) {

        var followUpQuestionsResults = "";

        for (const choice of azureOpenAIResults[0].choices) {

            const answerText = choice.message.content.replace("**", "");
            const followUpQuestions = answerText.split("$$$$")[2].trim();

            if (followUpQuestions) {
                followUpQuestionsResults += followUpQuestions;
            }
        }

        if (followUpQuestionsResults != "") {
            followUpQuestionsContent.innerHTML += '<div id="follow-up-questions-results-container">' + followUpQuestionsResults + '</div>';
        }
    }

    return followUpQuestionsContent;

}

// Function to create tab contents for supporting content results returned from Azure Search
function createTabContentSupportingContent(azureOpenAIResults, supportingContent, storageUrl, sasToken) {

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults.error) {

        //var answerResults = "";
        var citationContentResults = "";
        var supportingContentResults = "";
        var answerNumber = 1;
        var sourceNumber = 1;

        // Initialize a Set to store unique document paths
        const listedPaths = new Set();

        console.log(`Azure OpenAI Results: ${azureOpenAIResults} `);

        for (const choice of azureOpenAIResults[0].choices) {

            const answer = choice.message;
            const context = answer.context;

            const citations = context.citations;

            if (citations) {

                for (const citation of citations) {

                    const docTitle = citation.title;
                    const docPath = `${storageUrl}/${docTitle}`;

                    var answerText = citation.content.replace(" **", "").replace(/\s+/g, " ");
                    answerText = answerText.split(docPath)[0];

                    const footNoteLink = `<sup class="answer-citations"><a href="#answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${sourceNumber}</a></sup>`;
                    const docLink = ` <a href="${docPath}?${sasToken}" class="supporting-content-link" title="${docTitle}" target="_blank">(${docTitle})</a>`;

                    supportingContentResults += '<li class="answer-results">' + answerText + docLink + '</li>';

                    if (!listedPaths.has(docPath)) {
                        listedPaths.add(docPath);

                        sourceNumber++;
                    } else {
                        console.log(`Document already listed: ${docPath}`);
                    }
                }
                answerNumber++;
            }
        }

        if (supportingContentResults != "") {
            supportingContent.innerHTML += '<div id="azure-storage-results-container"><div id="azure-storage-results-header">Supporting Content from Azure Storage</div>' + '<ol id="supporting-content-results">' + supportingContentResults + '</ol><br/></div>';
        }
    }

    return supportingContent;
}

// Function to create tab contents for thought process content
function createThoughtProcessContent(azureOpenAIResults, thoughtProcessContent) {

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults.error) {

        var thoughtProcessResults = "";

        for (const choice of azureOpenAIResults[0].choices) {

            const answerText = choice.message.content.replace(/\*\*/g, "");
            const thoughtProcess = answerText.split("$$$$")[1].trim();

            if (thoughtProcess) {
                thoughtProcessResults += thoughtProcess;
            }
        }

        if (thoughtProcessResults != "") {
            thoughtProcessContent.innerHTML += '<div id="thought-process-results-container">' + thoughtProcessResults + '</div>';
        }
    }

    return thoughtProcessContent;

}

// function to delete documents
function deleteDocuments() {
    //code to delete documents

}

// Function to download chat results to a file
function downloadChatResults(event) {

    const chatResults = `<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Chat Results</title></head><body style="font-family: Arial; padding: 14px;"><div>${event.target.parentElement.parentElement.parentElement.previousElementSibling.previousSibling.firstChild.innerHTML}</div></body></html>`;
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

//Function to send chat message to Azure OpenAI model to either search the model directly or internal data sources
async function getAnswersFromAzureOpenAI(userInput, aiModelName, persona, dataSources) {

    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    const apiVersion = config.OPENAI_API_VERSION;
    const deploymentName = aiModelName;
    const openAIRequestBody = config.AZURE_OPENAI_REQUEST_BODY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/chat/completions?api-version=${apiVersion}`;

    var results = [];

    openAIRequestBody.messages = [];
    openAIRequestBody.messages = thread.messages;

    if (dataSources.length > 0) {

        for (const source of dataSources) {
            source.parameters.role_information = persona.Prompt;
            openAIRequestBody.data_sources.push(source);

            const jsonString = JSON.stringify(openAIRequestBody);

            const result = await invokeRESTAPI(jsonString, endpoint, apiKey);

            results.push(result);
        }
    }
    else {
        delete openAIRequestBody.data_sources;
    }

    return results;

}

//code to send chat message to Bing Search API (still under development)
async function getAnswersFromPublicInternet(userInput) {

    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    const apiVersion = config.OPENAI_API_VERSION;
    const aiModels = config.AI_MODELS;
    //const aiGPTModel = aiModels.find(item => item.Name === "gpt-4o");
    const aiGPTModel = config.AI_MODELS[0];
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

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const dataSources = config.DATA_SOURCES;
    const responseTabList = Object.entries(config.RESPONSE_TABS);
    const downloadChatResultsSVG = config.ICONS.DOWNLOAD_BUTTON.SVG;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;

    const chatInput = document.getElementById('chat-input').value.trim();
    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.style.display = 'none';

    const chatCurrentQuestionContainer = document.getElementById('chat-info-current-question-container');
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;

    const aiModel = config.AI_MODELS[0];
    const aiModelName = aiModel.Name;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    // Get the selected chat persona
    const persona = await getSelectedChatPersona();

    // Show the loading animation
    const loadingAnimation = document.querySelector('.loading-animation');
    loadingAnimation.style.display = 'flex';

    // Temporarary attachment for testing
    const attachment = "";

    if (chatInput) {

        const prompt = chatInput + " Include an explanation of your thought process to arrivate at this answer and have the thought process content placed at the end of your response using $$$$ to mark where the thought process content begins. Also include 3 possible follow up questions after the thought process with each one surrounded by <li class='followup-questions'> elements and the entire set followup questions surrounded by <ol> also separated by $$$$. For the follow up questions only return the questions. no header text or anything like that.";

        const message = { "role": "user", "content": prompt };

        addMessageToChatHistory(thread, message);

        const chatExamplesContainer = document.getElementById('chat-examples-container');
        chatExamplesContainer.style.display = 'none';

        // Get answers from Azure OpenAI model and datasources
        const azureOpenAIResults = await getAnswersFromAzureOpenAI(thread, aiModelName, persona, dataSources);

        // Create a new chat bubble element
        const chatResponse = document.createElement('div');
        chatResponse.setAttribute('class', 'chat-response user slide-up'); // Add slide-up class
        chatResponse.setAttribute('id', `chat-response-${answerResponseNumber}`);

        const tabs = createTabs(responseTabList);

        // Append tabs and contents to chat bubble
        chatResponse.appendChild(tabs);

        const answerContent = document.createElement('div');
        answerContent.className = 'tab-content active';
        answerContent.id = 'tab-content-answer';
        answerContent.style.fontStyle = 'italic';

        const thoughtProcessContent = document.createElement('div');
        thoughtProcessContent.className = 'tab-content';
        thoughtProcessContent.id = 'tab-content-thought-process';

        const supportingContent = document.createElement('div');
        supportingContent.className = 'tab-content';
        supportingContent.id = 'tab-content-supporting-content';
        supportingContent.style.fontStyle = 'italic';

        try {
            // Append the chat bubble to the chat-display div
            chatDisplay.appendChild(chatResponse);

            // Create tab contents for chat response content
            createChatResponseContent(azureOpenAIResults, chatResponse, answerContent, persona, storageUrl, sasToken, downloadChatResultsSVG);

            // Create tab contents for thought process content
            createThoughtProcessContent(azureOpenAIResults, thoughtProcessContent);

            // Create tab contents for supporting content
            createTabContentSupportingContent(azureOpenAIResults, supportingContent, storageUrl, sasToken);

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
            //chatDisplay.style.opacity = 1;

        } catch (error) {
            console.error('Error processing search results:', error);
        }

        // Hide the loading animation once results are returned
        loadingAnimation.style.display = 'none';

        // Clear the input field
        chatInput.value = '';

        var followUpQuestionLinks = document.getElementsByClassName('followup-questions');

        for (const link of followUpQuestionLinks) {
            link.addEventListener('click', function () {
                document.getElementById('chat-input').value = link.textContent;
            });
        }

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
async function getDocuments(blobs, storageUrl, fullStorageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon) {

    //const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;
    //const storageUrl = config.AZURE_STORAGE_FULL_URL;

    try {
        const response = await fetch(`${fullStorageUrl}`, {
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
            renderDocumentsHtmlTable(blobs, storageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon);
        } else {
            console.error('Failed to fetch documents:', response.statusText);
        }

    } catch (error) {
        console.error('Error fetching documents:', error);
    }
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

//code to toggle between chat and document screens
function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

// Function to get the selected chat persona
async function getSelectedChatPersona() {

    const config = await fetchConfig();

    const selectedRadio = document.querySelector('input[name="chat-persona"]:checked');

    var persona = {};

    if (selectedRadio) {
        const label = document.querySelector(`label[for="${selectedRadio.id}"]`);
        const personaType = label.innerText;

        const chatPersonas = config.CHAT_PERSONAS;

        persona = chatPersonas.find(p => p.Type === personaType) || {};
        return persona;
    }
    else {
        return persona;
    }
}

function hideLeftNav() {

    const width = window.innerWidth;
    const height = window.innerHeight;

    if (width < 601) {
        document.getElementById('left-nav-container').style.display = 'none';
    }
}

// Function to call the rest API
async function invokeRESTAPI(jsonString, endpoint, apiKey) {

    let data = {};

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

        data = await response.json();

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

// Function to check if a text is a question
function isQuestion(text) {
    const questionWords = ['who', 'what', 'where', 'when', 'why', 'how'];
    const words = text.trim().toLowerCase().split(/\s+/);
    return questionWords.includes(words[0]);
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

    document.getElementById("chat-info-text-copy").style.display = 'none';
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
                    <div id="chat-persona-container-${persona.Type.replace(" ", "-")}">
                        <input type="radio" ${chatRadioButtonChecked} class="chat-persona-radio" name="chat-persona" title="${persona.Prompt}" id="chat-persona-${persona.Type.replace(" ", "-")}" />
                    </div>
                    <div>
                        <label for="chat-persona-${persona.Type.replace(" ", "-")}" class="chat-persona-label">${persona.Type}</label>
                    </div>
                </div>`;

        chatPersonasContainer.appendChild(chatPersona);
    });


}

// Function to render documents in HTML table format
function renderDocumentsHtmlTable(blobs, storageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon) {

    const docList = document.getElementById('document-table-body');
    const sampleRows = document.querySelectorAll('.document-row.sample');

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
            let blobUrl = `${storageUrl}/${containerName}/${blobName}?${sasToken}`;
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
            let blobUrl = `${storageUrl}/${containerName}/${blobName}?${sasToken}`;
            //blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = blob.blobSize;

            // Create the document cells
            const previewCell = document.createElement('td');
            previewCell.className = 'document-cell document-cell-preview';
            previewCell.setAttribute('data-label', 'Preview');
            previewCell.innerHTML = `<button class="button-magnifying-glass" title="Preview"><a href="${blobUrl}" target="_blank">${magnifyingGlassIcon}</a></button>`;

            const statusCell = document.createElement('td');
            statusCell.className = 'document-cell document-cell-status';
            statusCell.setAttribute('data-label', 'Status');
            statusCell.innerHTML = '<span class="status-content">Active</span>';

            const nameCell = document.createElement('td');
            nameCell.className = 'document-cell document-cell-name';
            nameCell.setAttribute('data-label', 'Name');
            const nameLink = document.createElement('a');
            nameLink.href = blobUrl;
            //nameLink.textContent = truncateText(blobName, 20);
            nameLink.textContent = truncateString(blobName, 60);
            nameLink.target = '_blank'; // Open link in a new tab
            nameCell.appendChild(nameLink);

            const contentTypeCell = document.createElement('td');
            contentTypeCell.className = 'document-cell document-cell-content-type';
            contentTypeCell.setAttribute('data-label', 'Content Type');

            contentTypeCell.innerHTML = `<code>${contentType}</code>`;

            const fileSizeCell = document.createElement('td');
            fileSizeCell.className = 'document-cell document-cell-file-size';
            fileSizeCell.setAttribute('data-label', 'File Size');
            fileSizeCell.innerHTML = `<span class="file-size-content">${blobSize}</span>`;

            const lastModifiedCell = document.createElement('td');
            lastModifiedCell.className = 'document-cell';
            lastModifiedCell.setAttribute('data-label', 'Last Modified');
            lastModifiedCell.textContent = lastModified;

            const actionDiv = document.createElement('div');
            actionDiv.className = 'action-content';
            actionDiv.innerHTML = `<a href="#" title="delete file" class="edit-button">${editIcon}</a><a href="#" title="edit file" class="delete-button">${deleteIcon}</a>`;

            const actionCell = document.createElement('td');
            actionCell.className = 'document-cell action-container';
            actionCell.appendChild(actionDiv);

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

    const siteLogo = document.getElementsByClassName('site-logo')[0];
    const siteLogoText = document.getElementById('site-logo-text');
    const siteLogoTextCopy = document.getElementById('site-logo-text-copy');



    if (config.SITE_LOGO == "default" || getQueryParam('sitelogo') == "default") {
        siteLogo.display = 'block';
        siteLogo.classList.remove('site-logo-custom');
        siteLogo.classList.add('site-logo-default');
    }
    else {
        siteLogo.display = 'none';
        siteLogo.src = "images/site-logo-custom.png";
        siteLogo.classList.remove('site-logo-default');
        siteLogo.classList.add('site-logo-custom');
    }
}

// Function to show the settings dialog
function showSettingsDialog() {

    const settingsDialog = document.getElementById('settings-dialog');
    const settingsOverlay = document.getElementById('settings-overlay');

    if (settingsDialog.style.display === 'none' || settingsDialog.style.display === '') {
        settingsDialog.style.display = 'block';
        //settingsOverlay.style.display = 'block';
    } else {
        settingsDialog.style.display = 'none';
        //settingsOverlay.style.display = 'none';
    }

    // const formGroupDeleteAllThreads = document.getElementById('form-group-delete-all-threads');
    // const deleteAllThreadsButton = document.getElementById('delete-all-threads-button');

    // const loadingDeleteAllThreadsAnimation = document.createElement('div');

    // loadingDeleteAllThreadsAnimation.setAttribute('class', 'loading-animation');
    // loadingDeleteAllThreadsAnimation.innerHTML = '<div class="spinner" id="loading-delete-all-threads-animation"></div> Loading threads...'; // Hide it initially
    // formGroupDeleteAllThreads.insertBefore(loadingDeleteAllThreadsAnimation, deleteAllThreadsButton);
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

// Function to format string in proper case
function toProperCase(str) {
    return str.replace(/\w\S*/g, function (txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    });
}

function truncateString(str, num) {
    if (str.length <= num) {
        return str;
    }
    return str.slice(0, num) + '...';
}

// Function to truncate text
function truncateText(text, maxLength) {
    if (text.length > maxLength) {
        return text.substring(0, maxLength) + '...';
    }
    return text;
}

// Function to update the file count
function updateFileCount() {
    const fileCount = document.getElementById('file-input').files.length;
    document.getElementById('file-count').textContent = `Files selected: ${fileCount}`;
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

//code to upload files to Azure Storage
async function uploadFilesToAzure(files) {

    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const apiVersion = config.AZURE_STORAGE_API_VERSION;
    const magnifyingGlassIcon = config.ICONS.MAGNIFYING_GLASS.SVG;
    const editIcon = config.ICONS.EDIT.MONOTONE;
    const deleteIcon = config.ICONS.DELETE.MONOTONE;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&include=${sasTokenConfig.INCLUDE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;
    const fullStorageUrl = `${storageUrl}?${sasToken}`;

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
                getDocuments(blobs, storageUrl, fullStorageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon); // Refresh the document list after successful upload
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
