let iconStyle = "color";
let blobs = [];
let currentSortColumn = '';
let currentSortDirection = 'asc';
let currentQuestion = '';
let answerResponseNumber = 1;
let aiEnhancedAnswersArray = [];
let originalDocumentCount = 0;
let existingDocumentCount = 0;
let filteredDocumentCount = 0;
let useSaS;

let timerInterval;
let startTime;
let isImageQuestion = false;

let previousPersona = { "Type": "", "Prompt": "" };
let creationTerms = [];

let aiModel = {};

let msalInstance = {};
let accessToken = '';
let activeAccount = {};
let profilePic = '';
let presence = '';

let presenceIndicatorIcons;

let presenceIndicators = [{
    "name": "Available",
    "color": "green",
    "icon": "🟢"
},
{
    "name": "Busy",
    "color": "red",
    "icon": "🔴"
},
{
    "name": "Do not disturb",
    "color": "red",
    "icon": "🔴"
},
{
    "name": "Be right back",
    "color": "yellow",
    "icon": "🟡"
},
{
    "name": "Away",
    "color": "orange",
    "icon": "🟠"
},
{
    "name": "Offline",
    "color": "gray",
    "icon": "⚪"
},
{
    "name": "Presence unknown",
    "color": "gray",
    "icon": "⚪"
}];

let loggedIn = false;

let config = {};
let authMode = '';

const loginRequest = {
    scopes: [`Presence.Read`, `User.Read`, `Files.Read.All`, `Sites.Read.All`, `Sites.Selected`]
};

let thread = { "messages": [] };

let ai_assistant = {};
let ai_assistant_thread_list = [];
let ai_assistant_thread = [];
let ai_assistant_threadId = "";

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

document.addEventListener("DOMContentLoaded", async () => {

    config = await fetchConfig();

    authMode = config.AUTHENTICATION_MODE;
    useSaS = config.USE_SAS;

    await checkIfLoggedIn();

    getQueryParam('status');

    var screen = getQueryParam('screen');

    document.title = config.USE_CUSTOM_APP_TITLE ? config.CUSTOM_APP_TITLE : config.DEFAULT_APP_TITLE;

    document.getElementById('main-header-title').innerText = config.USE_CUSTOM_APP_TITLE ? config.CUSTOM_APP_TITLE : config.DEFAULT_APP_TITLE;

    toggleDisplay(screen);

    var loginContainer = document.getElementById("login-container");
    var leftNavContainer = document.getElementById("left-nav-container");
    var settingsIcon = document.getElementById("settings-icon");
    var topNavToolbarLinkContainer = document.getElementById("top-navigation-toolbar-link-container");

    if (window.getComputedStyle(loginContainer).display === "flex" || status === "login" || screen === "login") {
        loginContainer.style.display = "flex !important";
        leftNavContainer.style.display = "none";
        topNavToolbarLinkContainer.style.display = "none";
        settingsIcon.style.display = "none";

        document.getElementById('hamburger-menu').style.display = 'none';
    }

    document.getElementById('site-logo-container').innerHTML = config.ICONS.BUILDING.SVG;

    hideLeftNav();

    setSiteLogo();

    // Initial resize
    //resizeIcons();

    // Resize on window resize
    //window.addEventListener('resize', resizeIcons);

    // Add event listeners to the buttons
    const elements = document.getElementsByClassName('document-cell-name');
    Array.from(elements).forEach(element => element.classList.add('no-before'));

    creationTerms = config.DALL_E_CREATION_TERMS;

    getDocuments(blobs);

    const chatDisplayContainer = document.getElementById('chat-display-container');
    const chatDisplay = document.getElementById('chat-display');
    const loadingAnimation = document.createElement('div');

    loadingAnimation.setAttribute('class', 'loading-animation');
    loadingAnimation.innerHTML = '<div class="spinner"></div> Fetching results...';
    loadingAnimation.style.display = 'none'; // Hide it initially
    chatDisplayContainer.insertBefore(loadingAnimation, chatDisplay);

    if (chatDisplay.innerHTML.trim() === '') {
        document.getElementById('clear-button').style.display = 'none';
    }

    let searchIndexers = config.SEARCH_INDEXERS;

    let searchIndexStatusMessage = `If files were recently uploaded it will take some time for the search indexer to complete executing so that the new documents are included in the search results. `;
    searchIndexStatusMessage += `The time will vary depending on the number of documents that were uploaded. `;
    searchIndexStatusMessage += `If you feel that enough time has passed and still aren't seeing the new results you can try to manually re-run the indexer by clicking the refresh button.`;

    // If this executes with a breakpoint then it works. If it doesn't then it doesn't work.
    //let searchIndexerStatus = await getSearchIndexerStatus(searchIndexers);

    document.getElementById('search-indexer-status-text').innerHTML = "";
    document.getElementById('search-indexer-status-refresh').innerHTML = `<a href="#" id="run-search-indexer-link">${config.ICONS.REFRESH.SVG}</a>`;
    document.getElementById('search-indexer-status-refresh').title = searchIndexStatusMessage;

    let downloadChatLogContainer = document.getElementById('download-chat-log-container');

    if (thread.messages.length > 0) {
        downloadChatLogContainer.style.display = 'block';
    }
    else {
        downloadChatLogContainer.style.display = 'none';
    }

    downloadChatLogContainer.addEventListener('click', downloadChatLog);

    document.getElementById('run-search-indexer-link').addEventListener('click', function (event) {
        event.preventDefault();
        runSearchIndexer(searchIndexers);
    });

    document.getElementById('send-button').addEventListener('click', postQuestion);
    document.getElementById('clear-button').addEventListener('click', clearChatDisplay);
    document.getElementById('login-button').addEventListener('click', login);

    if (document.getElementById('chat-input').value.trim() === '') {
        document.getElementById('send-button').disabled = true;
    }
    else {
        document.getElementById('send-button').disabled = false;
    }

    document.getElementById('hamburger-menu').addEventListener('click', function () {
        const leftNav = document.getElementById('left-nav-container');
        const computedDisplay = window.getComputedStyle(leftNav).display;
        if (computedDisplay === "none") {
            // Force display to block regardless of media queries.
            leftNav.style.setProperty("display", "block", "important");
        } else {
            leftNav.style.setProperty("display", "none", "important");
        }
    });

    const chatInput = document.getElementById('chat-input');

    chatInput.addEventListener('keyup', function () {
        if (chatInput.value.trim() === '') {
            document.getElementById('send-button').disabled = true;
        }
        else {
            document.getElementById('send-button').disabled = false;
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            postQuestion();
        }
    });

    document.addEventListener('click', function (event) {

        const settingsPanel = document.getElementById('settings-panel');
        const userProfilePanel = document.getElementById('user-profile-panel');
        const panelOverlay = document.getElementById('panel-overlay');
        const leftNavContainer = document.getElementById('left-nav-container');

        if (settingsPanel.style.display === 'block' && !settingsPanel.contains(event.target) && !document.getElementById('link-settings').contains(event.target) && !document.getElementById('settings-icon').contains(event.target)) {
            settingsPanel.style.display = 'none';
            panelOverlay.style.display = 'none';
        }

        if (userProfilePanel.style.display === 'block' && !userProfilePanel.contains(event.target) && !document.getElementById('link-user-profile').contains(event.target) && !document.getElementById('user-profile-icon').contains(event.target)) {
            userProfilePanel.style.display = 'none';
            panelOverlay.style.display = 'none';
        }

        const width = window.innerWidth;
        const height = window.innerHeight;

        if (width < 831 && leftNavContainer.style.display === 'block' && !leftNavContainer.contains(event.target) && !document.getElementById('hamburger-menu').contains(event.target)) {
            leftNavContainer.style.display = 'none';
        }

        // if (width < 601 && leftNavContainer.style.display === 'block' && !leftNavContainer.contains(event.target) && !document.getElementById('hamburger-menu').contains(event.target)) {
        //     leftNavContainer.style.display = 'none';
        // }
    });

    window.addEventListener('resize', function () {
        const width = window.innerWidth;
        const height = window.innerHeight;

        // Example: Adjust the display of leftNavContainer based on the new width
        const leftNavContainer = document.getElementById('left-nav-container');
        const mainContent = document.getElementById('main-content');
        const mainContentWidth = mainContent.getBoundingClientRect().width;

        const mainTitleWidth = document.getElementById("main-header-title").getBoundingClientRect().width;

        let resizeWidth = mainTitleWidth > mainContentWidth ? mainTitleWidth + 210 : 660;

        //resizeIcons();

        leftNavContainer.style.removeProperty("display");
        // Add your resize logic here
        //console.log(`Window resized to width: ${width}, height: ${height}`);
        //console.log(`Main title width: ${mainTitleWidth}`);
        //console.log(`Resize width: ${resizeWidth}`);

        //User to be compared to 600
        // if (width > resizeWidth) {
        //     leftNavContainer.style.display = 'block';
        //     mainContent.style.marginLeft = '210px';
        // } else {
        //     leftNavContainer.style.display = 'none';
        //     mainContent.style.marginLeft = '20px';
        // }

        if (width < 1350) {
            const elements = document.getElementsByClassName('blob-name');
            Array.from(elements).forEach(element => element.classList.remove('no-before'));
        }
        else {
            const elements = document.getElementsByClassName('blob-name');
            Array.from(elements).forEach(element => element.classList.add('no-before'));
        }
    });

    // Add event listeners to navigation links
    // document.querySelector("#left-nav-menu > ul > li").addEventListener('click', function (event) {
    //     const link = $(this).find('a')[0];
    //     if (link) {
    //         event.preventDefault();
    //         const screen = new URL(link.href).searchParams.get('screen');
    //         toggleDisplay(screen);
    //         history.pushState(null, '', link.href);
    //     }
    // });

    document.querySelectorAll('#left-nav-container nav ul li').forEach(function (item) {
        item.addEventListener('click', function (event) {
            const link = item.querySelector('a');
            if (link) {
                event.preventDefault();
                const screen = new URL(link.href).searchParams.get('screen');
                toggleDisplay(screen);
                history.pushState(null, '', link.href);
            }
        });
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

        filteredDocumentCount = 0;

        documentRows.forEach(row => {
            if (row.style.display === 'none') {
                return; // Skip hidden rows
            }
            const nameCell = row.querySelector('.document-cell:nth-child(3)');
            if (nameCell.textContent.toLowerCase().includes(filterValue)) {
                row.style.display = '';
                filteredDocumentCount++;
                console.log(`Filtered document count: ${filteredDocumentCount}`);
            } else {
                row.style.display = 'none';
            }

            document.getElementById('existing-documents-count').innerText = `(${filteredDocumentCount})`;
        });
    });

    document.getElementById('clear-filter-button').addEventListener('click', function () {
        document.getElementById('filter-input').value = ''; // Clear the filter input
        const documentRows = document.querySelectorAll('#document-table .document-row:not(.header)');
        documentRows.forEach(row => {
            if (!row.classList.contains('sample')) {
                row.style.display = ''; // Reset the visibility of all rows except sample ones
            }
        });
        this.style.display = 'none'; // Hide the clear filter button
        document.getElementById('filter-button').style.display = 'block'; // Show the filter button

        document.getElementById('existing-documents-count').innerText = `(${originalDocumentCount})`;
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

        togglePanel('settings-panel');

        // Handle settings click
        console.log('Settings clicked');
    });

    document.getElementById('settings-icon').addEventListener('click', function (event) {
        event.preventDefault();

        togglePanel('settings-panel');

        // Handle settings click
        console.log('Settings clicked');
    });

    document.getElementById('link-user-profile').addEventListener('click', async function (event) {
        event.preventDefault();

        togglePanel('user-profile-panel');

        await getUserPresence();

        // Handle profile click
        console.log('User Profile clicked');
    });

    document.getElementById('user-profile-icon').addEventListener('click', async function (event) {
        event.preventDefault();

        togglePanel('user-profile-panel');

        await getUserPresence();

        // Handle settings click
        console.log('User Profile clicked');
    });

    document.getElementById('link-help').addEventListener('click', function (event) {
        event.preventDefault();
        // Handle help click
        console.log('Help clicked');
    });

    document.getElementById('close-settings-panel').addEventListener('click', function () {
        document.getElementById('settings-panel').style.display = 'none';
        document.getElementById('panel-overlay').style.display = 'none';
    });

    document.getElementById('close-user-profile-panel').addEventListener('click', function () {
        document.getElementById('user-profile-panel').style.display = 'none';
        document.getElementById('panel-overlay').style.display = 'none';
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

    const persona = getSelectedChatPersona();

    const system_message = { "role": "assistant", "content": persona.Prompt };
    addMessageToChatHistory(thread, system_message);

    previousPersona.Type = persona.Type;

    if (authMode != 'MSAL') {
        document.getElementById('user-profile-panel').style.display = 'none';
        document.getElementById('link-user-profile').style.display = 'none';
        document.getElementById('user-profile-icon').style.display = 'none';
    }

    //await initAiAssistant();
});

// Function to build chat history
function addMessageToChatHistory(thread, message) {
    //code to build chat history
    thread.messages.push(message);

    console.log(thread);
}

// Function to check if user is requesting an image be generated.
function checkIfImageQuestion(input) {

    const firstWord = input.trim().split(' ')[0].toLowerCase();
    const createImage = creationTerms.includes(firstWord);

    return createImage;
}

// Function to check if user is logged in
async function checkIfLoggedIn() {

    //config = await fetchConfig();

    authMode = config.AUTHENTICATION_MODE;

    presenceIndicatorIcons = config.ICONS.PRESENCE_INDICATORS;

    const userProfilePanel = document.getElementById('user-profile-panel');

    const userProfileName = document.getElementById('user-profile-info-name-value');
    const userProfileEmail = document.getElementById('user-profile-info-email-value');
    const userProfilePic = document.getElementById('user-profile-info-pic-value');
    const userPresence = document.getElementById('user-profile-info-presence-value');

    const body = document.querySelector('body');

    if (authMode === 'MSAL') {

        await initMSALInstance(config);

        const accounts = msalInstance.getAllAccounts();

        const scopes = [`Presence.Read`, `User.Read`, `Files.Read.All`, `Sites.Read.All`, `Sites.Selected`];

        const tokenRequest = {
            scopes: scopes,
            account: activeAccount
        };

        let tokenResponse;

        try {
            tokenResponse = await msalInstance.acquireTokenSilent(tokenRequest);
            console.log("Token acquired silently");
        } catch (silentError) {
            console.warn("Silent token acquisition failed, acquiring token using popup", silentError);
            tokenResponse = await msalInstance.acquireTokenPopup(tokenRequest);
            console.log("Token acquired via popup");
        }

        accessToken = tokenResponse.accessToken;

        if (accounts.length > 0) {
            msalInstance.setActiveAccount(accounts[0]);

            activeAccount = accounts[0];

            let email = activeAccount.username.toLowerCase();
            let username = activeAccount.name.trim();

            console.log("User is logged in:", activeAccount);

            userProfileEmail.innerHTML = `<a href="mailto:${email}">${email}</a>`;

            //profilePic = await getUserProfilePic();
            presence = await getUserPresence();

            userProfileName.innerHTML = username + ' ' + presence;

            //userProfilePic.innerHTML = `<img src="${profilePic}" alt="User profile picture" class="user-profile-pic">`;
            //userPresence.innerHTML = presence;

            body.style.display = 'flex';
            //msalInstance.loginRedirect(loginRequest);
            loggedIn = true;
        } else {
            console.log("No user is logged in.");

            await login();
            loggedIn = false;
        }
    }
    else {
        body.style.display = 'flex';
        loggedIn = true;
    }
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

    document.getElementById('clear-button').style.display = 'none';

    thread.messages = []; // Clear the chat history

    let downloadChatLogContainer = document.getElementById('download-chat-log-container');

    downloadChatLogContainer.style.display = 'none';

    document.getElementById('chat-info-text-copy').style.display = 'block';
    document.getElementById('chat-examples-container').style.display = 'block';
}

// Function to clear file input
function clearFileInput() {
    const fileInput = document.getElementById('file-input');
    fileInput.value = ''; // Clear the file input

    const selectedFilesDiv = document.getElementById('file-list');
    selectedFilesDiv.innerHTML = ''; // Clear the list of selected files
    updatePlaceholder(); // Update the placeholder text
}

// Function to collect chat results
function collectChatResults(chatResultsId) {
    const chatDisplay = document.getElementById(`${chatResultsId} `);
    return chatDisplay.innerHTML;
}

// Function to count the number of occurrences of a string in another string
function countOccurrences(mainString, searchString) {

    //const count = countQuadrupleDollarSigns(mainString);

    const regex = new RegExp(searchString.replace(/\$/g, '\\$'), 'g');
    const matches = mainString.match(regex);
    return matches ? matches.length : 0;
}

// Function to count the number of dollar signs in the provided string
function countQuadrupleDollarSigns(str) {
    const regex = /\$\$\$\$/g;
    let count = 0;
    let match;
    while ((match = regex.exec(str)) !== null) {
        count++;
    }

    return count;
}

// Function to create chat response content
function createChatResponseContent(azureOpenAIResults, chatResponse, answerContent, persona, downloadChatResultsSVG) {

    let sourceNumber = 0;
    let citationContentResults = "";
    let openAIModelResultsId = "";
    let answers = "";

    let numOccurrences = 0;

    // Initialize a Set to store unique document paths
    const listedPaths = new Set();
    const sasToken = config.AZURE_STORAGE_SAS;
    const storageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const fullStorageUrl = `${storageUrl}/${containerName}`;

    const iconInfo = config.ICONS.INFO.MONOTONE;

    let footNoteLinks = "";
    let followUpQuestions = "";

    if (!isImageQuestion) {

        if (azureOpenAIResults.error === undefined) {

            if (azureOpenAIResults.length > 0 && azureOpenAIResults[0].choices) {
                // Loop through the answers and create the response content   
                try {
                    for (const choice of azureOpenAIResults[0].choices) {

                        console.log(choice);

                        const answer = choice.message;
                        const role = answer.role;
                        let rawText = answer.content.replace(/\*\*/g, "").replace(/\s+/g, " ");

                        //let answerText = ensureDollarSigns(rawText);
                        let answerText = rawText.replace("###", "");

                        console.log(answerText);

                        //numOccurrences = countOccurrences(answerText, "[$$$$]");
                        numOccurrences = countQuadrupleDollarSigns(answerText);

                        if (numOccurrences != 2) {
                            answerText = insertDollarSigns(answerText);
                            numOccurrences = countQuadrupleDollarSigns(answerText);
                        }

                        followUpQuestions = numOccurrences > 1 ? answerText.split("$$$$")[2] : "";

                        console.log('Number of occurrences of $$$$:', numOccurrences);

                        if (followUpQuestions.length > 0) {
                            followUpQuestions = followUpQuestions.trim();
                        }

                        //followUpQuestions = followUpQuestions.replace('<li>', '<li class="followup-questions">');

                        answerText = numOccurrences > 0 ? answerText.split("$$$$")[0] : answerText;

                        const message = { "role": role, "content": answerText };

                        if (answerText.startsWith(config.NO_RESULTS_FOUND)) {
                            answerText = answerText.replace(config.NO_RESULTS_FOUND, persona.NoResults);
                        }
                        else {
                            addMessageToChatHistory(thread, message);
                        }

                        const context = answer.context;

                        const citations = context.citations;

                        // NOTE #1: At the time of this writing if model version 2024-11-20 is not used, the title value from the citations object is not returned in the response.

                        // NOTE #2: If additional metadata like filepath, title or url are null, you may need to reset and rerun the indexer(s). 
                        // This may be the ACTUAL reason for the null values and not the model version as stated above. Need further investigation.

                        if (citations) {

                            console.log(citations);

                            for (const citation of citations) {
                                const docTitle = citation.title;

                                if (docTitle) {
                                    const docUrl = `${fullStorageUrl}/${docTitle}?${sasToken}`;

                                    // Detect and replace [doc*] with [page *] and create hyperlink
                                    answerText = answerText.replace(/\[doc(\d+)\]/g, (match, p1) => {
                                        return `<sup class="answer-citations page-number"><a href="${docUrl}#page=${p1}" target="_blank">[page ${p1}]</a></sup>`;
                                    });

                                    if (!listedPaths.has(docTitle) && docTitle != "") {
                                        listedPaths.add(docTitle);

                                        sourceNumber++;

                                        const supportingContentLink = `<a class="answer-citations" title="${docTitle}" href="${docUrl}" style="text-decoration: underline" target="_blank"><span style="text-decoration: none">${sourceNumber}.</span> ${truncateText(docTitle, 90)}</a>`;

                                        citationContentResults += `<div id="answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${supportingContentLink}</div>`;

                                        footNoteLinks += `<sup class="answer-citations"><a title="${docTitle}" href="#answer-response-number-${answerResponseNumber}-citation-link-${sourceNumber}">${sourceNumber}</a></sup>`;
                                    }
                                    else {
                                        console.log(`Document already listed: ${docTitle}`);
                                    }
                                }

                            }
                        }

                        // Regex explanation:
                        // - (\d+\.\s): Matches a number, a dot and a following space
                        // - (.*?)(?=\s+\d+\.|$): Lazily captures all characters until it finds another numbered item (preceded by some whitespace and a number and dot)
                        //   or reaches the end of the string.
                        const regex = /(\d+\.\s)(.*?)(?=\s+\d+\.|$)/g;

                        let formattedText = answerText.replace(regex, (_, marker, content) => `<li>${content.trim()}</li>`);

                        if (formattedText.includes('<li>')) {
                            formattedText = `<ol>${formattedText}</ol>`;
                        }

                        //console.log(formattedText);

                        const answerListHTML = '<div class="answer-results">' + formattedText + footNoteLinks + '</div>';

                        answers += answerListHTML;

                    }
                }
                catch (error) {

                    let answerListHTML = `<div class="answer-results no-results">${persona.NoResults}</div>`;

                    answers += answerListHTML;
                    console.error(error);
                }
            }
        }
        else {
            if (azureOpenAIResults[0].error && (azureOpenAIResults[0].error.code == 429 || azureOpenAIResults[0].error.code == 400)) {

                answerListHTML = `<div class="answer-results">Token rate limit exceeded. Please try again later.</div>`;
                console.error('Token rate limit exceeded. Please try again later.', azureOpenAIResults[0].error);
            }
            else {
                answerListHTML = `<div class="answer-results" title="${azureOpenAIResults[0].error}">${persona.NoResults}</div>`;
                console.error('Error getting results from Azure OpenAI:', azureOpenAIResults[0].error);
            }
        }
    }
    else {

        let answerListHTML = '';

        if (azureOpenAIResults.error === undefined) {
            if (azureOpenAIResults.data.length > 0) {
                answerListHTML = `<div class="answer-results"><img src='${azureOpenAIResults.data[0].url}' title='${azureOpenAIResults.data[0].revised_prompt}' style='width:100%'></div>`;
                console.log(azureOpenAIResults.data[0].revised_prompt);
            }
            else {
                answerListHTML = `<div class="answer-results" title="${azureOpenAIResults[0].error}">${persona.NoResults} <span class="icon-info">${iconInfo}</span></div>`;
                console.error('Error getting results from Azure OpenAI:', azureOpenAIResults[0].error);
            }
        }
        else {
            answerListHTML = `<div class="answer-results" title="${azureOpenAIResults.error.message}">${persona.NoResults} <span class="icon-info">${iconInfo}</span></div>`;
            console.error('Error getting results from Azure OpenAI:', azureOpenAIResults.error.message);
        }

        answers += answerListHTML;
    }

    if (previousPersona.Type != "Default") {
        answerContent.innerHTML += `<div class="openai-model-results-header-container"><div class="openai-model-results-header">Search Results</div><div class="openai-model-results-header-persona">(${previousPersona.Type})</div></div>`;
    }
    else {
        answerContent.innerHTML += `<div class="openai-model-results-header-container"><div class="openai-model-results-header">Search Results</div><div class="openai-model-results-header-persona"></div></div>`;
    }

    const openAIModelResultsContainerId = `openai-model-results-container-${answerResponseNumber}`;
    openAIModelResultsId = `openai-model-results-${answerResponseNumber}`;

    if (answers.length > 0) {

        if (isImageQuestion) {
            answerContent.innerHTML += `<div id="${openAIModelResultsContainerId}" class="openai-model-results"><div id="${openAIModelResultsId}"><div class="ai-enhanced-answer-results"></div><br/></div>`;

            chatResponse.appendChild(answerContent);

            let enhancedAnswerResults = document.getElementById(`${openAIModelResultsId}`);

            enhancedAnswerResults.getElementsByClassName('ai-enhanced-answer-results')[0].innerHTML = answers;

            //enhancedAnswerResults.appendChild(answers);

            //enhancedAnswerResults.innerHTML += answers;
        }
        else {
            answerContent.innerHTML += `<div id="${openAIModelResultsContainerId}" class="openai-model-results"><div id="${openAIModelResultsId}"><div class="ai-enhanced-answer-results">${answers}</div><br/></div>`;
            answerContent.innerHTML += `<div id="followup-questions-container">${followUpQuestions}</div>`;
            answerContent.innerHTML += `<div id="answer-sources-container"><h6 class="answer-sources">Sources:</h6>${citationContentResults}</div ></div> `;

            chatResponse.appendChild(answerContent);
        }
    }
    else {
        answerContent.innerHTML += `<div id = "${openAIModelResultsId}"> No results found.</div>`;

        chatResponse.appendChild(answerContent);
    }

    // Add download chat results button
    if (openAIModelResultsId != "" && openAIModelResultsId != undefined) {

        const openAIResultsContainer = document.getElementById(openAIModelResultsId);

        const downloadChatResultsContainer = document.createElement('div');
        downloadChatResultsContainer.id = `download-chat-results-container-${answerResponseNumber} `;
        downloadChatResultsContainer.className = 'download-chat-results-container';

        const downloadChatResultsButtonId = `download-chat-results-button-${answerResponseNumber} `;

        const downloadChatResultsButton = `<div id ="${downloadChatResultsButtonId}" onclick = "downloadChatResults()" class="download-chat-results-button">${downloadChatResultsSVG}</div> `;

        downloadChatResultsContainer.innerHTML = downloadChatResultsButton;

        openAIResultsContainer.appendChild(downloadChatResultsContainer);

        document.getElementById(downloadChatResultsButtonId).addEventListener('click', downloadChatResults);

        //answerResponseNumber++;
    }

}

// Function to create side navigation links
async function createSidenavLinks() {

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

// Function to create tab contents for follow-up questions [NOT USED]
function createFollowUpQuestionsContent(azureOpenAIResults, followUpQuestionsContent) {

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults[0].error && azureOpenAIResults[0].choices) {

        var followUpQuestionsResults = "";

        for (const choice of azureOpenAIResults[0].choices) {

            let answerText = choice.message.content.replace("**", "");

            //numOccurrences = countOccurrences(answerText, "[$$$$]");
            numOccurrences = countQuadrupleDollarSigns(answerText);

            if (numOccurrences != 2) {
                answerText = insertDollarSigns(answerText);
                numOccurrences = countQuadrupleDollarSigns(answerText);
            }

            const followUpQuestions = numOccurrences > 1 ? answerText.split("$$$$")[2] : "";

            if (followUpQuestions.length > 0) {
                followUpQuestions = followUpQuestions.trim();
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
function createTabContentSupportingContent(azureOpenAIResults, supportingContent) {

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults[0].error) {

        //var answerResults = "";
        let citationContentResults = "";
        let supportingContentResults = "";
        let answerNumber = 1;
        let sourceNumber = 1;

        // Initialize a Set to store unique document paths
        const listedPaths = new Set();
        const sasToken = config.AZURE_STORAGE_SAS;
        const storageUrl = config.AZURE_STORAGE_URL;
        const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
        const fullStorageUrl = `${storageUrl}/${containerName}`;

        console.log(azureOpenAIResults);

        for (const choice of azureOpenAIResults[0].choices) {

            const answer = choice.message;
            const context = answer.context;

            const citations = context.citations;

            if (citations) {

                for (const citation of citations) {

                    const docTitle = citation.title;
                    const docPath = `${fullStorageUrl}/${docTitle}`;

                    if (docTitle != "") {
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

    if (azureOpenAIResults.length > 0 && !azureOpenAIResults[0].error) {

        var thoughtProcessResults = "";
        let numOccurrences = 0;

        for (const choice of azureOpenAIResults[0].choices) {

            let answerText = choice.message.content.replace(/\*\*/g, "");

            //numOccurrences = countOccurrences(answerText, "[$$$$]");
            numOccurrences = countQuadrupleDollarSigns(answerText);

            if (numOccurrences != 2) {
                answerText = insertDollarSigns(answerText);
                numOccurrences = countQuadrupleDollarSigns(answerText);
            }

            const thoughtProcess = numOccurrences > 1 ? answerText.split("$$$$")[1].trim() : "";

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

// Function to delete a document
async function deleteDocument(docJson) {

    const doc = JSON.parse(docJson);
    const apiVersion = config.AZURE_STORAGE_API_VERSION;
    const keyVaultProxyOperation = config.AZURE_STORAGE_ACCOUNT_SECRET_NAME;
    const httpMethod = "DELETE";
    const httpContentType = "application/json";
    const httpBody = null;
    const returnData = false;

    let response;

    let httpHeaders = {
        'x-ms-date': new Date().toUTCString(),
        'x-ms-version': apiVersion,
        'mode': 'no-cors'
    };

    try {

        if (useSaS) {
            response = await fetch(doc.url, {
                method: httpMethod,
                headers: httpHeaders
            });
        }
        else {
            response = await invokeRESTAPI(doc.url, httpMethod, httpContentType, httpHeaders, httpBody, keyVaultProxyOperation, returnData);
        }

        if (response.ok) {
            console.log(`Deleted document: ${doc.title}`);
        } else {
            const errorText = await response.text();
            console.error(`Failed to delete document: ${doc.title}. Error: ${errorText}`);
        }
    } catch (error) {
        console.error(`Error deleting document: ${doc.title}. Error: ${error.message}`);
    }
}

// Function to delete documents
async function deleteDocuments() {
    const selectedDocs = getSelectedDocuments();

    if (selectedDocs.length === 0) {
        console.warn("No documents selected for deletion.");
        return;
    }

    await deleteSelectedDocuments(selectedDocs);
}

// Function to delete documents
async function deleteSelectedDocuments(selectedDocs) {
    if (!Array.isArray(selectedDocs) || selectedDocs.length === 0) {
        console.warn("No documents selected for deletion.");
        return;
    }

    let response;

    let keyVaultProxyOperation = config.AZURE_STORAGE_ACCOUNT_SECRET_NAME;

    // NEED TO UPDATE CODE TO USE AZURE STORAGE API KEY INSTEAD OF SAS TOKEN

    const storageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const apiVersion = config.AZURE_STORAGE_API_VERSION;
    const fullStorageUrl = `${storageUrl}/${containerName}`;
    const sasToken = config.AZURE_STORAGE_SAS;

    for (const doc of selectedDocs) {
        // Assume doc.docId holds the blob name; URL encode it for safety
        const blobName = encodeURIComponent(doc.docId);
        const deleteUrl = `${fullStorageUrl}/${blobName}?${sasToken}`;

        try {

            if (useSas) {
                response = await fetch(deleteUrl, {
                    method: 'DELETE',
                    headers: {
                        'x-ms-date': new Date().toUTCString(),
                        'x-ms-version': apiVersion
                    }
                });
            }
            else {
                response = invokeRESTAPI(deleteUrl, "DELETE", "application/json", null, null, keyVaultProxyOperation, false);
            }

            if (response.ok) {
                console.log(`Deleted document: ${doc.title}`);
            } else {
                const errorText = await response.text();
                console.error(`Failed to delete document: ${doc.title}. Error: ${errorText}`);
            }
        } catch (error) {
            console.error(`Error deleting document: ${doc.title}. Error: ${error.message}`);
        }
    }

    // Optionally, refresh the documents list after deletion:
    // getDocuments(blobs, storageUrl, fullStorageUrl, containerName, sasToken, magnifyingGlassIcon, editIcon, deleteIcon);
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

// Function to download chat log
function downloadChatLog() {
    let chatlog = thread.messages;
    let filename = 'chat-log.json';
    let chatLogJson = JSON.stringify(chatlog, null, 2);

    const blob = new Blob([chatLogJson], { type: 'application/json' });

    const url = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);


}

// Function to make sure $$$$ exists in query response.
function ensureDollarSigns(text) {
    // Split the text into paragraphs
    let paragraphs = text.split('\n\n');

    // Check if the second paragraph starts with $$$$
    if (!paragraphs[1].startsWith('$$$$')) {
        // Insert $$$$ at the beginning of the second paragraph
        paragraphs[1] = '$$$$\n\n' + paragraphs[1];
    }

    // Join the paragraphs back into a single string
    return paragraphs.join('\n\n');
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

// Function to get AI Assistant results
async function getAnswersFromAiAssistant(message) {

    const apiKey = config.AZURE_OPENAI_SERVICE_API_KEY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai`;
    const apiVersion = "2024-05-01-preview";

    let url = `${endpoint}/threads?api-version=${apiVersion}`;

    try {

        const assistantResponse = await initAiAssistant();

        // First get the thread ID
        const threadId = ai_assistant_thread.id;

        // Then send the message
        console.log('AI Assistant posting message:', message);

        url = `${endpoint}/threads/${threadId}/messages?api-version=${apiVersion}`;

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'api-key': apiKey,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(message)
        });

        const data = await response.json();

        // Then run the thread
        console.log('AI Assistant running thread...');

        const body = JSON.stringify({ "assistant_id": ai_assistant.first_id });

        url = `${endpoint}/threads/${threadId}/runs?api-version=${apiVersion}`;
        const runResponse = await fetch(url, {
            method: 'POST',
            headers: {
                'api-key': apiKey,
                'Content-Type': 'application/json'
            },
            body: body
        });

        const runData = await runResponse.json();

        // Then get the status of the run
        console.log('AI Assistant getting run status...');

        url = `${endpoint}/threads/${threadId}/runs/${runData.id}?api-version=${apiVersion}`;
        const statusResponse = await fetch(url, {
            method: 'GET',
            headers: {
                'api-key': apiKey,
                'Content-Type': 'application/json'
            }
        });

        const statusData = await statusResponse.json();

        console.log('AI Assistant run status:', statusData);

        // Then get the results of the run
        console.log('AI Assistant getting run results...');

        url = `${endpoint}/threads/${threadId}/messages?api-version=${apiVersion}`;
        const resultsResponse = await fetch(url, {
            method: 'GET',
            headers: {
                'api-key': apiKey,
                'Content-Type': 'application/json'
            }
        });

        const runResults = await resultsResponse.json();

        console.log('AI Assistant run results:', runResults);

        ai_assistant_thread_list = runResults.data;
    }
    catch (error) {
        console.error('Error fetching AI Assistant search results:', error);
        return null;
    }
}

//Function to send chat message to Azure OpenAI model to either search the model directly or internal data sources
async function getAnswersFromAzureOpenAI(userInput, aiModel, persona, dataSources) {

    if (!userInput) return;

    let openAIRequestBody = "";
    let openAIRequestBodyJson = "";
    let keyVaultProxyOperation = config.AZURE_OPENAI_SERVICE_SECRET_NAME;

    const returnData = true;
    const httpMethod = 'POST';
    let httpHeaders = {};
    let httpContentType = 'application/json';
    let apiKey;
    let searchApiKey;

    switch (isImageQuestion) {
        case true:
            openAIRequestBody = config.DALL_E_REQUEST_BODY;
            console.log('Image question detected');
            break;
        case false:
            openAIRequestBody = config.AZURE_OPENAI_REQUEST_BODY;
            console.log('Non-image question detected');
            break;
    }

    if (authMode == 'MSAL') {
        apiKey = await getSecretFromKeyVault(keyVaultProxyOperation);
        searchApiKey = await getSecretFromKeyVault(config.AZURE_SEARCH_SERVICE_SECRET_NAME);
    }
    else {
        apiKey = aiModel.ApiKey;
        searchApiKey = config.AZURE_SEARCH_SERVICE_API_KEY;
    }

    const apiVersion = aiModel.ApiVersion;
    const urlPath = aiModel.Path;
    const deploymentName = aiModel.DeploymentName;

    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentName}/${urlPath}?api-version=${apiVersion}`;

    var results = [];

    // Only copilot-demo-002 has a DALL-E model deployed and it is deployed using the ai-copilot-demo-002 and not the openai-service-copilot-demo-002.
    // As of right now I have deployed the javascript version that points to the openai-copilot-demo-002 which does not have the DALL-E model deployed.
    // This is why image creation is not working.
    if (isImageQuestion) {

        let aiImage = '';
        httpContentType = 'image/jpeg';

        openAIRequestBody.prompt = currentQuestion;
        //openAIRequestBody.n = 4;

        openAIRequestBodyJson = JSON.stringify(openAIRequestBody);

        let imageTable = document.createElement('table');
        imageTable.id = `image-table-${answerResponseNumber}`;
        imageTable.className = 'image-table-class';

        let imageTableBody = document.createElement('tbody');
        imageTableBody.class = 'image-table-body';

        const images = await invokeRESTAPI(endpoint, httpMethod, httpContentType, httpHeaders, openAIRequestBodyJson, keyVaultProxyOperation, returnData);

        if (!images.error) {
            for (const image of images.data) {

                let imageTableRow = document.createElement('tr');
                imageTableRow.class = 'image-table-row';

                let imageTableCell = document.createElement('td');
                imageTableCell.class = 'image-table-cell';

                imageTableCell.innerHTML = `<img src="${image.url}" alt="Generated image" title="${image.revised_prompt}" class="dall-e-generated-image">`;

                imageTableRow.appendChild(imageTableCell);
                imageTableBody.appendChild(imageTableRow);

                aiImage = `<img src="${image.url}" alt="Generated image" title="${image.revised_prompt}" class="dall-e-generated-image" style="width: 80%; height: auto;">`;

                results.push(aiImage);

                console.log('Image generation result URL: ' + image.url);
            }
        }

        imageTable.appendChild(imageTableBody);

        //return imageTable;

        return images
    }
    else {
        openAIRequestBody.messages = [];
        openAIRequestBody.messages = thread.messages;

        if (dataSources.length > 0) {

            openAIRequestBody.data_sources.length = 0;

            for (const source of dataSources) {
                source.parameters.role_information = persona.Prompt;
                //If authMode is MSAL then we use the searchTokenSecretName to get the search token from the Key Vault to store in the data source parameters for the search API
                //If the authMode is API_KEY then we just use the search API key directly from the config.json file.
                source.parameters.authentication.key = searchApiKey;
                //source.parameters.authentication.key = apiKey
                openAIRequestBody.data_sources.push(source);

                openAIRequestBodyJson = JSON.stringify(openAIRequestBody);

                //If authMode is MSAL we need to pass the openAiTokenSecretName to the invokeRESTAPI function so that getSecretFromKeyVault can be called to get the token from the Key Vault for the OpenAI service before calling the OpenAI API.
                //If the authMode is API_KEY then we just use the OpenAI API key directly from the config.json file.
                const result = await invokeRESTAPI(endpoint, httpMethod, httpContentType, httpHeaders, openAIRequestBodyJson, keyVaultProxyOperation, returnData);

                results.push(result);
            }
        }
        else {
            delete openAIRequestBody.data_sources;
        }

        return results;
    }
}

// Function to send chat message to Bing Search API (still under development)
async function getAnswersFromPublicInternet(userInput) {

    if (!userInput) return;

    const apiKey = config.AZURE_AI_SERVICE_API_KEY;
    const apiVersion = config.OPENAI_API_VERSION;
    const aiModels = config.AI_MODELS;
    //const aiGPTModel = aiModels.find(item => item.Name === "gpt-4o");
    const aiGPTModel = config.AI_MODELS[0];
    const deploymentName = aiGPTModel.DeploymentName;
    const openAIRequestBody = config.AZURE_OPENAI_REQUEST_BODY;
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

// Function to get the AUTH token
async function getAccessToken(clientId) {

    const tokenRequest = {
        scopes: [`api://${clientId}/access_as_user`],
        account: activeAccount
    };

    msalInstance.acquireTokenSilent(tokenRequest)
        .then(response => {
            console.log("Token acquired:", response.accessToken);

            return response.accessToken;
        })
        .catch(error => {
            console.error("Token acquisition error:", error);
            return null;
        });

    return null;
}

// Function to show responses to questions
async function getChatResponse(questionBubble) {

    const dataSources = config.DATA_SOURCES;

    const responseTabList = Object.entries(config.RESPONSE_TABS);
    const downloadChatResultsSVG = config.ICONS.DOWNLOAD_BUTTON.SVG;

    const chatInput = document.getElementById('chat-input').value.trim();
    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.style.display = 'none';

    const chatCurrentQuestionContainer = document.getElementById('chat-info-current-question-container');

    isImageQuestion = await checkIfImageQuestion(chatInput);

    const queryParam = getQueryParam('promptSuffix');

    let promptSuffix = !queryParam ? config.PROMPT_SUFFIX : queryParam;
    let prompt = '';

    if (isImageQuestion) {
        prompt = chatInput;
        aiModel = config.AI_MODELS.find(item => item.DeploymentName === "dall-e-3");
    }
    else {
        prompt = chatInput + promptSuffix;
        aiModel = config.AI_MODELS.find(item => item.DeploymentName === "gpt-4o");
    }

    // Construct the SAS token from the individual components
    //const sasToken = `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;
    const sasToken = getSasToken();

    // Get the selected chat persona
    const persona = getSelectedChatPersona();

    if (persona.Type != previousPersona.Type || thread.messages.length == 0) {
        const system_message = { "role": "assistant", "content": persona.Prompt };
        addMessageToChatHistory(thread, system_message);

        previousPersona.Type = persona.Type;
    }

    // Show the loading animation
    const loadingAnimation = document.querySelector('.loading-animation');
    loadingAnimation.style.display = 'flex';

    if (chatInput) {

        const message = { "role": "user", "content": prompt };

        addMessageToChatHistory(thread, message);

        const chatExamplesContainer = document.getElementById('chat-examples-container');
        chatExamplesContainer.style.display = 'none';

        // Get answers from Azure OpenAI model and datasources
        const azureOpenAIResults = await getAnswersFromAzureOpenAI(thread, aiModel, persona, dataSources);

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
            createChatResponseContent(azureOpenAIResults, chatResponse, answerContent, persona, downloadChatResultsSVG);

            if (isImageQuestion == false) {
                // Create tab contents for thought process content
                createThoughtProcessContent(azureOpenAIResults, thoughtProcessContent);

                // Create tab contents for supporting content
                createTabContentSupportingContent(azureOpenAIResults, supportingContent);

                chatResponse.appendChild(thoughtProcessContent);
                chatResponse.appendChild(supportingContent);
            }
            else {

                if (azureOpenAIResults.error === undefined) {
                    if (azureOpenAIResults.data.length > 0) {
                        thoughtProcessContent.innerHTML += `<div id="thought-process-results-container">Revised Prompt:<br/>${azureOpenAIResults.data[0].revised_prompt}</div>`;
                        chatResponse.appendChild(thoughtProcessContent);
                    }
                }
            }

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
        document.getElementById('chat-input').value = '';

        var followUpQuestionLinks = document.getElementsByClassName('followup-questions');

        for (const link of followUpQuestionLinks) {
            link.addEventListener('click', function () {
                document.getElementById('chat-input').value = link.textContent;
            });
        }

        // Scroll to the position right above the newest questionBubble
        //const questionBubbleTop = chatResponse.offsetTop;
        //chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

        scrollToNewestQuestionBubble();

        questionBubble.style.display = 'block'; // Show the question bubble

        // Scroll to the position right above the newest questionBubble
        //chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

        chatCurrentQuestionContainer.innerHTML = ''; // Clear the current question

        let downloadChatLogContainer = document.getElementById('download-chat-log-container');

        downloadChatLogContainer.style.display = 'block';
    }
    else {
        loadingAnimation.style.display = 'none';
    }

    document.getElementById('expand-chat-svg-container').style.display = 'block';
    document.getElementById('jump-to-top-arrow').style.display = 'block';

    document.getElementById('clear-button').style.display = '';

    answerResponseNumber++;

    scrollToNewestQuestionBubble();

    scrollToNewestQuestionBubble();

    const questionBubbleTop = questionBubble.offsetTop;
    chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

}

//Function to get documents from Azure Storage. This needs to be updated to have option to use MSAL in addition to API_KEY.
async function getDocuments(blobs) {

    const httpMethod = 'GET';
    const httpBody = "";
    const returnData = true;
    const contentType = 'text/xml';
    const httpHeaders = {
        'Content-Type': 'text/xml',
        'Cache-Control': 'no-cache'
    };

    let response;
    let fullStorageUrl;

    const keyVaultProxyOperation = config.AZURE_STORAGE_ACCOUNT_SECRET_NAME;

    try {
        if (useSaS) {

            fullStorageUrl = config.AZURE_STORAGE_FULL_URL_SAS;

            response = await fetch(fullStorageUrl, {
                method: httpMethod,
                headers: httpHeaders
            });
        }
        else {

            fullStorageUrl = config.AZURE_STORAGE_FULL_URL;

            response = await invokeRESTAPI(fullStorageUrl, httpMethod, contentType, httpHeaders, null, keyVaultProxyOperation, returnData);
        }

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

// Function to get answers for image related questions
async function getImageAnswers(input) {

}

// Function to get SAS token from config file
async function getSasToken() {
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;

    return `sv=${sasTokenConfig.SV}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;
}

// Function to get the search indexer status
async function getSearchIndexerStatus(searchIndexers) {
    // Retrieve configuration which should include your Azure Search service name and API key
    const httpMethod = 'GET';
    const returnData = true;
    const httpContentType = 'application/json';
    const httpHeaders = "";
    const httpBody = "";

    const keyVaultProxyOperation = config.AZURE_SEARCH_SERVICE_SECRET_NAME;
    const searchServiceUrl = config.AZURE_SEARCH_SERVICE_URL;
    const apiVersion = config.AZURE_SEARCH_SERVICE_API_VERSION;

    //https://learn.microsoft.com/en-us/rest/api/searchservice/indexers/get-status?view=rest-searchservice-2024-07-01&tabs=HTTP#indexerexecutionstatus

    let searchIndexerStatusArray = [];

    // Iterate over the search indexers to get their current statuses
    for (const searchIndexer of searchIndexers) {
        const searchIndexerName = searchIndexer.Name;
        //var searchIndexName = searchIndexer.IndexName;
        //var searchIndexerSchema = searchIndexer.Schema;

        if (searchIndexerName.indexOf("sharepoint") > -1) {
            continue;
        }

        // Invoke the REST method to get the search indexer status
        try {
            const searchIndexerUrl = `${searchServiceUrl}/indexers/${searchIndexerName}/status?api-version=${apiVersion}`;

            const data = await invokeRESTAPI(searchIndexerUrl, httpMethod, httpContentType, httpHeaders, httpBody, keyVaultProxyOperation, returnData);

            console.log(`Indexer: ${searchIndexerName} status:`, data.lastResult.status);

            searchIndexerStatusArray.push({ "name": searchIndexerName, "status": data.lastResult.status });
        } catch (error) {
            console.error(`Error getting search indexer status`, error.message);
        }
    }

    return searchIndexerStatusArray;
}

// Function to get the selected documents
function getSelectedDocuments() {
    const selectedDocs = [];
    const checkboxes = document.querySelectorAll('input[type="checkbox"]:checked');
    checkboxes.forEach(checkbox => {
        const docId = checkbox.getAttribute('data-doc-id');
        const docTitle = checkbox.getAttribute('data-doc-title');
        selectedDocs.push({ docId, docTitle });
    });
    return selectedDocs;
}

// Function to get user presence
async function getUserPresence() {

    const userProfileName = document.getElementById('user-profile-info-name-value');

    const endpoint = 'https://graph.microsoft.com/v1.0/me/presence';

    const username = activeAccount.name.trim();

    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
    };

    const response = await fetch(endpoint, {
        method: 'GET',
        headers: headers
    });

    let presence = '';
    let presenceIndicator = '';
    let presenceIndicatorIcon = '';

    if (response.ok) {
        const data = await response.json();

        const availability = data.availability.toLowerCase().replace(/\s+/g, '');

        presenceIndicator = await presenceIndicators.find(icon => icon.name.toLowerCase().replace(/\s+/g, '') === availability);
        presenceIndicatorIcon = await presenceIndicatorIcons.find(icon => icon.TEXT.toLowerCase().replace(/\s+/g, '') === availability);
    } else {

        presenceIndicator = await presenceIndicators.find(icon => icon.name === "Presence Unknown");
        presenceIndicatorIcon = await presenceIndicatorIcons.find(icon => icon.TEXT === "Presence Unknown");

        console.error('Error fetching presence data:', response.statusText);
    }

    presence = `<span class="presence-icon">${presenceIndicator.icon}</span><span class="presence-text ${presenceIndicator.color}">${presenceIndicator.name}</span>`;

    userProfileName.innerHTML = username + ' ' + presence;

    return presence;

}

// Function to get user profile picture
async function getUserProfilePic() {

    const endpoint = 'https://graph.microsoft.com/v1.0/me/photo/$value';

    const headers = {
        'Content-Type': 'image/jpg',
        'Authorization': `Bearer ${accessToken}`
    };

    const response = await fetch(endpoint, {
        method: 'GET',
        headers: headers
    });

    const data = await response.json();

    return data;
}

// Function to toggle between chat and document screens
function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

// Function to retrieve secret from Azure Key Vault
async function getSecretFromKeyVault(keyVaultProxyOperation) {

    let tokenResponse;
    let accessToken;

    const apimServiceName = config.AZURE_APIM_SERVICE_NAME;

    const tokenRequest = {
        scopes: [`https://vault.azure.net/.default`],
        account: activeAccount
    };

    const keyVaultApiVersion = config.AZURE_KEY_VAULT_API_VERSION;

    const keyVaultProxyEndPoint = `https://${apimServiceName}.azure-api.net/keyvault/secrets`
    const apimSubscriptionKey = config.AZURE_APIM_SUBSCRIPTION_KEY;

    try {
        tokenResponse = await msalInstance.acquireTokenSilent(tokenRequest);
        accessToken = tokenResponse.accessToken;
        console.log("Token acquired silently");
    } catch (silentError) {
        console.warn("Silent token acquisition failed, acquiring token using popup", silentError);
        tokenResponse = await msalInstance.acquireTokenPopup(tokenRequest);
        accessToken = tokenResponse.accessToken;
        console.log("Token acquired via popup");
    }

    const keyVaultUrl = `${keyVaultProxyEndPoint}/${keyVaultProxyOperation}?api-version=${keyVaultApiVersion}`;

    try {
        const response = await fetch(keyVaultUrl, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
                'Ocp-Apim-Subscription-Key': `${apimSubscriptionKey}`,
                'mode': 'no-cors'
            }
        });

        if (response.ok) {
            const data = await response.json();
            return data.value;
        } else {
            console.error('Failed to fetch secret:', response.statusText);
            return null;
        }
    } catch (error) {
        console.error('Error fetching secret:', error);
        return null;
    }
}

// Function to get the selected chat persona
function getSelectedChatPersona() {

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

// Function to hide the left navigation on small screens
function hideLeftNav() {

    const width = window.innerWidth;
    const height = window.innerHeight;

    if (width < 831) {
        document.getElementById('left-nav-container').style.display = 'none';
    }
}

// Function to initialize the AI Assistant
async function initAiAssistant() {

    if (ai_assistant_thread.length > 0) {
        return ai_assistant;
    }

    const apiKey = config.AZURE_OPENAI_SERVICE_API_KEY;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai`;
    const apiVersion = "2024-05-01-preview";

    let url = `${endpoint}/assistants?api-version=${apiVersion}`;

    const responseAssistant = await fetch(url, {
        method: 'GET',
        headers: {
            contentType: 'application/json',
            'api-key': apiKey,
        }
    });

    ai_assistant = await responseAssistant.json();

    // Get the main thread
    url = `${endpoint}/threads?api-version=${apiVersion}`;

    const responseThread = await fetch(url, {
        method: 'GET',
        headers: {
            'api-key': apiKey,
            'Content-Type': 'application/json'
        }
    });

    const threadList = await responseThread.json();

    ai_assistant_thread_list = threadList.data;

    ai_assistant_thread = threadList.data[0];

    ai_assistant_threadId = threadList.first_id;

    return ai_assistant;
}

// Function to initialize new instance of MSAL
async function initMSALInstance(config) {

    const tenantId = config.AZURE_TENANT_ID;
    const clientId = config.AZURE_APP_REG_CLIENT_APP_ID;
    const appServiceName = config.AZURE_APP_SERVICE_NAME;

    const msalConfig = {
        auth: {
            clientId: `${clientId}`,
            authority: `https://login.microsoftonline.com/${tenantId}`,
            redirectUri: `https://${appServiceName}.azurewebsites.net`
        },
        cache: {
            cacheLocation: "localStorage", // This configures where your cache will be stored
            storeAuthStateInCookie: true // Set this to true if you are having issues on IE11 or Edge
        }
    };

    msalInstance = new msal.PublicClientApplication(msalConfig);

    // Insert a delay of 5 seconds
    await new Promise(resolve => setTimeout(resolve, 1000));

    msalInstance.handleRedirectPromise()
        .then(response => {
            if (response) {
                msalInstance.setActiveAccount(response.account);
                console.log("Login successful:", response);
            } else {
                console.log("No redirect response found.");
            }
        })
        .catch(error => {
            console.error("Error handling redirect:", error);
        });
}

// Function to insert dollar signs at the end of the last sentence before an ordered list
function insertDollarSigns(str) {
    // Find the index of the <ol> tag
    const olIndex = str.indexOf('<ol');

    if (olIndex === -1) {
        // If no <ol> tag is found, return the original string
        return str;
    }

    // Find the last period before the <ol> tag (we look for the last period before the <ol> tag starts)
    const lastPeriodIndex = str.lastIndexOf('.', olIndex);

    if (lastPeriodIndex === -1) {
        // If there's no period before the <ol> tag, return the original string (no sentence end found)
        return str;
    }

    // Extract the last sentence before the <ol> tag
    const lastSentence = str.slice(lastPeriodIndex + 1, olIndex).trim();

    // Check if the last sentence contains $$$$
    if (!lastSentence.includes('$$$$')) {
        // If $$$$ is not present, insert $$$$ after the period at the end of the last sentence
        return str.slice(0, lastPeriodIndex + 1) + ' $$$$' + str.slice(lastPeriodIndex + 1);
    }

    // If $$$$ is already present, return the string as is
    return str;
}

// Function to call the rest API
async function invokeRESTAPI(httpEndpoint, httpMethod, httpContentType, httpHeaders, httpBody, keyVaultProxyOperation, returnData) {

    let data = {};
    let apiKey = "";
    let response;

    //httpMethod = (httpMethod === undefined || httpMethod === "") ? "POST" : httpMethod;

    try {

        if (authMode === "MSAL") {
            apiKey = await getSecretFromKeyVault(keyVaultProxyOperation);
        }
        else {
            switch (keyVaultProxyOperation) {
                case "OpenAIServiceApiKey":
                    apiKey = config.AZURE_OPENAI_SERVICE_API_KEY;
                    break;
                case "SearchServiceApiKey":
                    apiKey = config.AZURE_SEARCH_SERVICE_API_KEY;
                    break;
                case "StorageServiceApiKey":
                    apiKey = config.AZURE_STORAGE_API_KEY;
                    break;
            }
        }

        // Using this code because I can't deploy DALL-E-3 due to quota restrictions.
        if (httpContentType === "image/jpeg") {
            //apikey = aiModel.ApiKey;
            apiKey = "617fbecd68bb4835af175a0503bac785";
        }

        //httpContentType = isImageQuestion ? 'image/jpeg' : 'application/json';

        if (httpHeaders === undefined || httpHeaders === "" || httpHeaders === null) {
            httpHeaders = {
                'Content-Type': `${httpContentType}`,
                'api-key': `${apiKey}`,
                'http2': 'true',
                'mode': 'no-cors'
            };
        }
        else {
            httpHeaders['api-key'] = apiKey;
        }

        if (httpBody === undefined || httpBody === "" || httpBody === null) {
            response = await fetch(httpEndpoint, {
                method: httpMethod,
                headers: httpHeaders
            });
        }
        else {
            response = await fetch(httpEndpoint, {
                method: httpMethod,
                headers: httpHeaders,
                body: httpBody
            });
        }

        if (returnData) {

            data = await response.json();

            return data;
        }
    }
    catch (error) {
        if (error.code == 429 || error.code == 400) {

            const data = { error: 'Token rate limit exceeded. Please try again later.' };
            console.error('Token rate limit exceeded. Please try again later.', error);
            return data;
        }
        else {
            const data = { error: 'An error occurred. Please try again later.' };
            console.error('Error retrieving apikey from Azure Key Vault:', error);
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

// Function to authenticate the user
async function login() {
    msalInstance.loginRedirect(loginRequest);
}

// Function to log out the user
function logout() {
    msalInstance.logout();
}

// Function to post a question to the chat display
async function postQuestion() {

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

    currentQuestion = chatInput;

    // Create a new div for the chat bubble
    const questionBubble = document.createElement('div');
    questionBubble.setAttribute('class', 'question-bubble fade-in'); // Add fade-in class
    questionBubble.setAttribute('id', `question-bubble-${answerResponseNumber}`);

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

    startTimer(); // Start the timer

    getChatResponse(questionBubble);

    stopTimer(); // Stop the timer

    document.getElementById("chat-info-text-copy").style.display = 'none';

    //await getAnswersFromAiAssistant(chatInput);
}

// Function to render chat personas
async function renderChatPersonas() {


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

        // document.getElementById(`chat-persona-${persona.Type.replace(" ", "-")}`).addEventListener('click', function () {
        //     selectedPersona = persona.type;
        // });
    });


}

// Function to render documents in HTML table format
function renderDocumentsHtmlTable(blobs) {

    const docList = document.getElementById('document-table-body');
    const sampleRows = document.querySelectorAll('.document-row.sample');
    const storageUrl = config.AZURE_STORAGE_URL;
    const storageContainerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasToken = config.AZURE_STORAGE_SAS;
    const editIcon = config.ICONS.EDIT_BUTTON.MONOTONE;
    const deleteIcon = config.ICONS.DELETE_BUTTON.MONOTONE;
    const magnifyingGlassIcon = config.ICONS.MAGNIFYING_GLASS.MONOTONE;

    // Clear existing document rows except the header
    const existingRows = docList.querySelectorAll('tr.document-row');
    existingRows.forEach(row => docList.removeChild(row));

    if (blobs.length === 0) {
        // Show sample rows if no results
        sampleRows.forEach(row => row.style.display = '');
    } else {
        // Hide sample rows if there are results
        sampleRows.forEach(row => row.style.display = 'none');

        // Extract blob data into an array of objects
        const blobData = Array.from(blobs).map(blob => {
            const title = blob.getElementsByTagName("Name")[0].textContent;
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
            let url = `${storageUrl}/${storageContainerName}/${title}?${sasToken}`;
            url = url.replace("&comp=list", "").replace("&restype=container", "");
            const size = formatBytes(parseInt(blob.getElementsByTagName("Content-Length")[0].textContent));
            return { title, lastModified, contentType, url, size };
        });

        originalDocumentCount = blobData.length;
        existingDocumentCount = blobData.length;
        filteredDocumentCount = originalDocumentCount;

        document.getElementById('existing-documents-count').innerText = `(${filteredDocumentCount})`;

        // Iterate over the sorted blob data and create document rows
        blobData.forEach(blob => {
            // Create the document row
            const documentRow = document.createElement('tr');
            documentRow.className = 'document-row';

            var blobName = blob.title;
            const lastModified = blob.lastModified;
            const contentType = blob.contentType.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
            let blobUrl = blob.url;
            //blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
            const blobSize = blob.size;
            const blobJson = JSON.stringify(blob);

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
            nameCell.className = 'document-cell document-cell-name no-before';
            nameCell.setAttribute('data-label', 'Name');
            const nameLink = document.createElement('a');
            nameLink.href = blobUrl;

            blobName = truncateString(blobName, 40);

            nameLink.textContent = blobName;
            nameLink.target = '_blank';

            const nameContainer = document.createElement('div');
            nameContainer.className = 'blob-name';
            nameContainer.appendChild(nameLink);

            nameCell.appendChild(nameContainer);

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
            actionDiv.innerHTML = `<span title='${blobJson}' class="document-edit-button">${editIcon}</span><span title='${blobJson}' class="document-delete-button">${deleteIcon}</span>`;

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

    const width = window.innerWidth;

    if (width < 1350) {
        const elements = document.getElementsByClassName('blob-name');
        Array.from(elements).forEach(element => element.classList.remove('no-before'));
    }
    else {
        const elements = document.getElementsByClassName('blob-name');
        Array.from(elements).forEach(element => element.classList.add('no-before'));
    }

    document.querySelectorAll('.document-delete-button').forEach(function (item) {
        item.addEventListener('click', function (event) {
            event.preventDefault();
            deleteDocument(item.title);
        });
    });

    document.querySelectorAll('.document-edit-button').forEach(function (item) {
        item.addEventListener('click', function (event) {
            event.preventDefault();
            editDocument(item.title);
        });
    });
}

// Function to render panel icons
async function renderPanelIcons() {


    const settingsIcon = config.ICONS.SETTINGS.MONOTONE;
    const userProfileIcon = config.ICONS.USER_PROFILE.MONOTONE;

    const settingsIconContainer = document.getElementById('settings-container');
    const profileIconContainer = document.getElementById('user-profile-container');

    settingsIconContainer.innerHTML = settingsIcon;
    profileIconContainer.innerHTML = userProfileIcon;

}

// Function to resize icons (currently doesn't work as expected)
function resizeIcons() {
    const windowWidth = window.innerWidth; // Use window.innerWidth for viewport width
    const calculatedWidth = Math.floor(windowWidth / 60);
    const iconWidth = Math.min(42, Math.max(16, calculatedWidth));
    const iconHeight = iconWidth; // Keep it square

    console.log("windowWidth:", windowWidth);
    console.log("calculatedWidth:", calculatedWidth);
    console.log("iconWidth:", iconWidth);

    const settingsIcon = document.getElementById('settings-icon');
    const userProfileIcon = document.getElementById('user-profile-icon');

    const newMinX = 0;
    const newMinY = 0;
    const newWidth = iconWidth;
    const newHeight = iconHeight;

    if (settingsIcon) {
        settingsIcon.style.setProperty('width', `${iconWidth}px`, 'important');
        settingsIcon.style.setProperty('height', `${iconHeight}px`, 'important');
        settingsIcon.setAttribute('viewBox', `${newMinX} ${newMinY} ${newWidth} ${newHeight}`);
    }

    if (userProfileIcon) {
        userProfileIcon.style.setProperty('width', `${iconWidth}px`, 'important');
        userProfileIcon.style.setProperty('height', `${iconHeight}px`, 'important');
        userProfileIcon.setAttribute('viewBox', `${newMinX} ${newMinY} ${newWidth} ${newHeight}`);
    }

    console.log(`Icon resized to ${iconWidth}px by ${iconHeight}px`);
}

// Function to run Search Indexer after new file is uploaded
async function runSearchIndexer(searchIndexers) {

    const httpMethod = 'POST';
    const httpContentType = 'application/json';
    let httpBody = "";
    const httpHeaders = {};
    const returnData = false;

    const searchServiceName = config.AZURE_SEARCH_SERVICE_NAME;
    const searchServiceApiVersion = config.AZURE_SEARCH_SERVICE_API_VERSION;
    const searchServiceUrl = config.AZURE_SEARCH_SERVICE_URL;

    let keyVaultProxyOperation = config.AZURE_SEARCH_SERVICE_SECRET_NAME;

    const searchIndexerStatus = await getSearchIndexerStatus(searchIndexers);

    // Iterate over the search indexers and run each one
    for (const searchIndexer of searchIndexers) {
        var searchIndexerName = searchIndexer.Name;
        //var searchIndexName = searchIndexer.IndexName;
        //var searchIndexerSchema = searchIndexer.Schema;

        const indexer = searchIndexerStatus.find(indexer => indexer.name === searchIndexerName);
        const indexerStatus = indexer ? indexer.status : 'unknown';

        // Skip the indexer if it is already running
        if (indexerStatus === "inProgress" || indexerStatus === "running") {
            console.log(`Indexer ${searchIndexerName} is already running. Skipping...`);
            continue;
        }
        if (searchIndexerName.indexOf("sharepoint") > -1) {
            continue;
        }

        var searchIndexerUrl = `${searchServiceUrl}/indexers/${searchIndexerName}/run?api-version=${searchServiceApiVersion}`;

        // Invoke the REST method to run the search indexer
        try {

            await invokeRESTAPI(searchIndexerUrl, httpMethod, httpContentType, httpHeaders, httpBody, keyVaultProxyOperation, returnData);

            //No need to return anything from the search indexer
            //const data = await response.json();
            console.log('Operation "run search indexer" is now executing for', searchIndexerName);
        } catch (error) {
            console.error(`Error running search indexer`, error.message);
        }
    }
}

function scrollToLatestBubbleMessage() {
    const chatDisplay = document.getElementById('chat-display');
    if (!chatDisplay) return;

    const bubbles = chatDisplay.getElementsByClassName('chat-response');
    if (bubbles.length === 0) return;

    const latestBubble = bubbles[bubbles.length - 1];
    latestBubble.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// Function to scroll to the newest question bubble
function scrollToNewestQuestionBubble() {

    // Get all elements with the specified class name
    const elements = document.getElementsByClassName("chat-response user slide-up");

    // Access the last element in the HTMLCollection
    const lastElement = elements[elements.length - 1];

    // Get the bounding rectangle of the last element
    const rect = lastElement.getBoundingClientRect();

    // Access the position properties
    const top = rect.top;
    const left = rect.left;
    const bottom = rect.bottom;
    const right = rect.right;

    // Get the top coordinate of the element
    const topPosition = top + window.scrollY;

    // Scroll to the top coordinate of the element
    window.scrollTo({
        top: topPosition,
        behavior: 'smooth' // This makes the scroll smooth
    });

    console.log(`Top: ${top}, Left: ${left}, Bottom: ${bottom}, Right: ${right}`);

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

    const siteLogo = document.getElementsByClassName('site-logo')[0];


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
function showSettingsPanel() {

    const settingsDialog = document.getElementById('settings-panel');
    const settingsOverlay = document.getElementById('panel-overlay');

    if (settingsDialog.style.display === 'none' || settingsDialog.style.display === '') {
        settingsDialog.style.display = 'block';
        //settingsOverlay.style.display = 'block';
    } else {
        settingsDialog.style.display = 'none';
        //settingsOverlay.style.display = 'none';
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

// Function to start the timer
function startTimer() {
    startTime = Date.now();
    timerInterval = setInterval(() => {
        const elapsedTime = Math.floor((Date.now() - startTime) / 1000);
        document.getElementById('chat-response-timer').innerText = `Elapsed Time: ${elapsedTime}s`;
    }, 1000);
}

// Function to stop the timer
function stopTimer() {
    clearInterval(timerInterval);
    //document.getElementById('chat-response-timer').innerText = `Time: 0s`;
}

// Function to toggle all checkboxes
function toggleAllCheckboxes() {

    const allCheckbox = document.getElementById('datasource-all');
    const datasourceCheckboxes = document.querySelectorAll('input[type="checkbox"][id^="datasource-"]:not(#datasource-all)');

    datasourceCheckboxes.forEach(checkbox => {
        checkbox.checked = allCheckbox.checked;
    });
}

// Function to insert field title into search results
function toggleBeforeAfter(width) {
    if (width < 1350) {
        const elements = document.getElementsByClassName('document-cell-name');
        Array.from(elements).forEach(element => element.classList.add('no-before'));

        const nameElements = document.getElementsByClassName('blob-name');
        Array.from(nameElements).forEach(element => element.classList.remove('no-before'));
    }
    else {
        const elements = document.getElementsByClassName('blob-name');
        Array.from(elements).forEach(element => element.classList.add('no-before'));
    }
}

// Function to toggle between chat and document screens
function toggleDisplay(screen) {
    const chatContainer = document.getElementById('chat-container');
    const documentContainer = document.getElementById('document-container');
    const homeContainer = document.getElementById('home-container');
    const loginContainer = document.getElementById('login-container');
    const leftNavContainer = document.getElementById('left-nav-container');
    const topNavToolbarLinkContainer = document.getElementById('top-navigation-toolbar-link-container');
    const settingsIcon = document.getElementById('settings-icon');
    const userProfileIcon = document.getElementById('user-profile-icon');

    const status = getQueryParam('status');

    //Remove "true" for production
    if (loggedIn) {
        if (screen === 'chat') {
            chatContainer.style.display = 'block';
            documentContainer.style.display = 'none';
            homeContainer.style.display = 'none';
        } else if (screen === 'documents') {
            chatContainer.style.display = 'none';
            homeContainer.style.display = 'none';
            documentContainer.style.display = 'block';
        } else {
            chatContainer.style.display = 'none';
            documentContainer.style.display = 'none';
            homeContainer.style.display = 'block';
        }
    }
    else {
        chatContainer.style.display = 'none';
        documentContainer.style.display = 'none';
        homeContainer.style.display = 'none';
        topNavToolbarLinkContainer.style.display = 'none';
        leftNavContainer.style.display = 'none';
        loginContainer.style.display = 'none';
        settingsIcon.style.display = 'none';
        userProfileIcon.style.display = 'none';
    }
}

// Function to show the selected panel
function togglePanel(panel) {
    const panelOverlay = document.getElementById('panel-overlay');

    const panelElement = document.getElementById(panel);

    panelElement.style.display = panelElement.style.display === 'block' ? 'none' : 'block';

    panelOverlay.style.display = panelOverlay.style.display === 'block' ? 'none' : 'block';
}

// Function to format string in proper case
function toProperCase(str) {
    return str.replace(/\w\S*/g, function (txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    });
}

// Function to truncate a string
function truncateString(str, num) {
    if (str.length <= num) {
        return str;
    }
    return str.slice(0, num) + '...';
}

// Function to truncate text
function truncateText(text, maxLength) {
    if (!text) {
        return '';
    }

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

// Function to update placeholder text
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

// Function to upload files to Azure Storage
async function uploadFilesToAzure(files) {

    let httpContentType = 'application/json';
    let httpHeaders = {};
    let httpBody = "";
    let response = "";

    const httpMethod = 'PUT';
    const returnData = false;
    const keyVaultProxyOperation = config.AZURE_STORAGE_ACCOUNT_SECRET_NAME;
    const storageUrl = config.AZURE_STORAGE_URL;
    const sasToken = config.AZURE_STORAGE_SAS;

    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const apiVersion = config.AZURE_STORAGE_API_VERSION;

    const searchIndexers = config.SEARCH_INDEXERS;

    let fullStorageUrl;

    for (const file of files) {
        const fileName = file.name.replace("#", "");
        const date = new Date().toUTCString();

        httpContentType = file.type;

        httpHeaders = {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': file.type,
            'Content-Length': file.size.toString(),
            'x-ms-date': date,
            'x-ms-version': apiVersion,
            'x-ms-blob-content-type': file.type,
            'mode': 'no-cors',
            'http2': 'true'
        };

        try {
            if (useSaS) {
                fullStorageUrl = `${storageUrl}/${containerName}/${fileName}?&${sasToken}`;

                response = await fetch(fullStorageUrl, {
                    method: httpMethod,
                    headers: httpHeaders,
                    body: file
                });
            }
            else {
                fullStorageUrl = `${storageUrl}/${containerName}/${fileName}`;

                response = await invokeRESTAPI(fullStorageUrl, httpMethod, httpContentType, httpHeaders, file, keyVaultProxyOperation, returnData);
            }

            if (response.ok) {
                showToastNotification(`Upload successful for ${file.name}.`, true);
                console.log(`Upload successful for ${file.name}.`);
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

    getDocuments(blobs); // Refresh the document list after successful upload

    //The isn't working yet because of permissions issues
    await runSearchIndexer(searchIndexers);
}

// Function to batch upload files to Azure
async function uploadFilesToAzureBatch(files) {
    if (!files || files.length === 0) {
        console.log('No files selected for upload.');
        return;
    }

    const httpMethod = 'PUT';
    const returnData = false;
    const keyVaultProxyOperation = config.AZURE_STORAGE_ACCOUNT_SECRET_NAME;

    const apiVersion = config.AZURE_STORAGE_API_VERSION;
    const searchIndexers = config.SEARCH_INDEXERS;

    let fullStorageUrl;

    let response;

    // Create an array of upload promises for concurrent processing.
    const uploadPromises = Array.from(files).map(file => {
        return (async () => {
            const fileName = file.name.replace("#", "");
            const date = new Date().toUTCString();
            const httpContentType = file.type;
            const fileHeaders = {
                'x-ms-blob-type': 'BlockBlob',
                'Content-Type': file.type,
                'Content-Length': file.size.toString(),
                'x-ms-date': date,
                'x-ms-version': apiVersion,
                'x-ms-blob-content-type': file.type,
                'mode': 'no-cors',
                'http2': 'true'
            };

            try {

                if (useSaS) {
                    fullStorageUrl = config.AZURE_STORAGE_FULL_URL_SAS;

                    response = await fetch(fullStorageUrl, {
                        method: httpMethod,
                        headers: fileHeaders,
                        body: file
                    });
                }
                else {
                    fullStorageUrl = config.AZURE_STORAGE_URL;

                    response = await invokeRESTAPI(fullStorageUrl, httpMethod, httpContentType, fileHeaders, file, keyVaultProxyOperation, returnData);
                }

                // Check for success—if not, throw error for Promise.all rejection.
                if (response && response.ok) {
                    console.log(`Upload successful for ${file.name}.`);
                    showToastNotification(`Upload successful for ${file.name}.`, true);
                } else {
                    let errorText = "";
                    try {
                        errorText = response ? await response.text() : 'Unknown error';
                    } catch (e) {
                        errorText = 'Unknown error';
                    }
                    console.error(`Error uploading file ${file.name} to Azure Storage:`, errorText);
                    showToastNotification(`Error uploading file ${file.name}: ${errorText}`, false);
                    throw new Error(`Error uploading ${file.name}`);
                }
            } catch (error) {
                console.error(`Error uploading file ${file.name}:`, error.message);
                throw error;
            }
        })();
    });

    try {
        await Promise.all(uploadPromises);
        // Clear file input and refresh document list after all uploads complete
        clearFileInput();
        getDocuments(blobs);
        // Optionally, run the search indexer after batch uploading
        await runSearchIndexer(searchIndexers);
    } catch (error) {
        console.error('One or more file uploads failed:', error);
    }
}