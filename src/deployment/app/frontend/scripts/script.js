

var iconStyle = "color";

// Function to fetch the configuration
async function fetchConfig() {
    const response = await fetch('../config.json');
    const config = await response.json();
    return config;
}

$(document).ready(function () {

    setChatDisplayHeight();

    // Add an event listener to adjust the height on window resize
    window.addEventListener('resize', setChatDisplayHeight);

    getDocuments();

    createSidenavLinks();

    $('#send-button').on('click', postQuestion);
    $('#clear-button').on('click', clearChatDisplay);

    $(document).on('keydown', function (event) {
        if (event.key === 'Enter') {
            postQuestion();
        }
    });

    const screen = getQueryParam('screen');

    toggleDisplay(screen);

    // Add event listeners to navigation links
    $('#nav-container nav ul li a').on('click', function (event) {
        event.preventDefault();
        const screen = new URL(this.href).searchParams.get('screen');
        toggleDisplay(screen);
        history.pushState(null, '', this.href);
    });

    document.getElementById('datasource-all').addEventListener('change', toggleAllCheckboxes);

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
        const documentRows = document.querySelectorAll('#document-list .document-row:not(.header)');
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
        if (settingsDialog.style.display === 'none' || settingsDialog.style.display === '') {
            settingsDialog.style.display = 'block';
        } else {
            settingsDialog.style.display = 'none';
        }

        // Handle settings click
        console.log('Settings clicked');


    });

    document.getElementById('toggle-icons').addEventListener('change', function () {
        const iconElements = document.getElementsByClassName('iconify');
        const iconColorElements = document.getElementsByClassName('iconify-color');

        iconStyle = iconStyle === 'monotone' ? 'color' : 'monotone';
        const toggleDisplay = (elements) => {
            for (let i = 0; i < elements.length; i++) {
                const element = elements[i];
                const currentDisplay = window.getComputedStyle(element).display;
                element.style.display = currentDisplay === 'none' ? 'inline' : 'none';
            }
        };

        toggleDisplay(iconElements);
        toggleDisplay(iconColorElements);
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
    });

    document.getElementById('datasources-header').addEventListener('click', function () {
        const content = document.getElementById('datasources-content');
        const arrow = document.querySelector('.accordion-arrow');
        if (content.style.display === 'none' || content.style.display === '') {
            content.style.display = 'block';
            arrow.innerHTML = '&#9650;'; // Up arrow
        } else {
            content.style.display = 'none';
            arrow.innerHTML = '&#9660;'; // Down arrow
        }
    });
});

function toggleAllCheckboxes() {

    const allCheckbox = document.getElementById('datasource-all');
    const datasourceCheckboxes = document.querySelectorAll('input[type="checkbox"][id^="datasource-"]:not(#datasource-all)');

    datasourceCheckboxes.forEach(checkbox => {
        checkbox.checked = allCheckbox.checked;
    });
}

// Function to clear the chat display
function clearChatDisplay() {
    const chatDisplay = document.getElementById('chat-display');
    chatDisplay.innerHTML = ''; // Clear all content
}

function setChatDisplayHeight() {
    const chatDisplayContainer = document.getElementById('chat-display-container');
    const chatInfoTextCopy = document.getElementById('chat-info-text-copy');

    const windowHeight = window.innerHeight - (chatInfoTextCopy.offsetHeight + 200);

    // Calculate the desired height (e.g., 80% of the window height)
    const desiredHeight = windowHeight * 0.7;

    // Set the height of the chat-display-container
    chatDisplayContainer.style.height = `${desiredHeight}px`;
}

async function postQuestion() {

    const config = await fetchConfig();
    let chatInput = document.getElementById('chat-input').value;
    const chatDisplay = document.getElementById('chat-display');
    const dateTimestamp = new Date().toLocaleString();

    // Check if chatInput ends with a question mark, if not, add one
    if (!chatInput.trim().endsWith('?')) {
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

    // Append the chat bubble to the chat-info div
    chatDisplay.appendChild(questionBubble);

    // Scroll to the position right above the newest questionBubble
    const questionBubbleTop = questionBubble.offsetTop;
    chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

    showResponse();
}

async function showResponse() {

    const config = await fetchConfig();
    const chatInput = document.getElementById('chat-input').value.trim();
    const chatDisplay = document.getElementById('chat-display');

    // Retrieve the text from the input field

    if (chatInput) {

        //const response = await getAnswers(chatInput);
        const response = await getAnswers(chatInput);

        // Create a new chat bubble element
        const chatBubble = document.createElement('div');
        chatBubble.setAttribute('class', 'chat-bubble user slide-up'); // Add slide-up class

        // Create tabs
        const tabs = document.createElement('div');
        tabs.className = 'tabs';

        // Loop through CHAT_TABS to create tabs dynamically
        Object.entries(config.CHAT_TABS).forEach(([key, value], index) => {
            const tab = document.createElement('div');
            tab.className = `tab ${index === 0 ? 'active' : ''}`;
            tab.innerHTML = `${value.SVG} ${value.TEXT}`;
            tabs.appendChild(tab);
        });

        // Create tab contents
        const answerContent = document.createElement('div');
        answerContent.className = 'tab-content active';
        answerContent.textContent = response.choices[0].message.content;

        const thoughtProcessContent = document.createElement('div');
        thoughtProcessContent.className = 'tab-content';
        thoughtProcessContent.textContent = 'Thought process content goes here.';

        const supportingContentContent = document.createElement('div');
        supportingContentContent.className = 'tab-content';
        supportingContentContent.textContent = 'Supporting content goes here.';

        // Append tabs and contents to chat bubble
        chatBubble.appendChild(tabs);
        chatBubble.appendChild(answerContent);
        chatBubble.appendChild(thoughtProcessContent);
        chatBubble.appendChild(supportingContentContent);

        // Append the chat bubble to the chat-display div
        chatDisplay.appendChild(chatBubble);

        // Clear the input field
        chatInput.value = '';

        // Scroll to the position right above the newest questionBubble
        const questionBubbleTop = chatBubble.offsetTop;
        chatDisplay.scrollTop = questionBubbleTop - chatDisplay.offsetTop;

        // Add event listeners to tabs
        const tabElements = tabs.querySelectorAll('.tab');
        const tabContents = chatBubble.querySelectorAll('.tab-content');

        tabElements.forEach((tab, index) => {
            tab.addEventListener('click', () => {
                tabElements.forEach(t => t.classList.remove('active'));
                tabContents.forEach(tc => tc.classList.remove('active'));

                tab.classList.add('active');
                tabContents[index].classList.add('active');
            });
        });

        // Scroll to the top of the chat display
        //chatDisplay.scrollTop = 0;
    }
}

// Function to convert bytes to KB/MB
function formatBytes(bytes) {
    if (bytes < 1024) return bytes + ' B';
    else if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    else return (bytes / 1048576).toFixed(2) + ' MB';
}

//code to send chat message to Azure Copilot
async function getAnswers(userInput) {

    if (!userInput) return;

    //$('#user-input').val('');

    const config = await fetchConfig();

    const apiKey = config.OPEN_AI_KEY;
    const apiVersion = config.API_VERSION;
    const deploymentId = config.DEPLOYMENT_ID;
    const region = config.REGION;
    const endpoint = `https://${region}.api.cognitive.microsoft.com/openai/deployments/${deploymentId}/chat/completions?api-version=${apiVersion}`;

    const userMessageContent = config.OPEN_AI_REQUEST_BODY.messages.find(message => message.role === 'user').content[0];
    userMessageContent.text = userInput;

    const jsonString = JSON.stringify(config.OPEN_AI_REQUEST_BODY);

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': `${apiKey}`
            },
            body: jsonString
        });

        const data = await response.json();

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

//code to send message to Azure Search via Azure Function
async function getAnswersFromAzureSearch(userInput) {
    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_SEARCH_API_KEY;
    const searchFunctionName = config.AZURE_SEARCH_FUNCTION_APP_NAME;
    const indexName = config.AZURE_SEARCH_INDEX;
    //const endpoint = `https://${searchFunctionName}.azurewebsites.net/api/${searchFunctionName}?code=${apiKey}`;
    //const endpoint = "https://func-copilot-demo-003.azurewebsites.net/api/SearchTest?code=TewiFybiLLEUIYTRgsht_ZQDNBd6ZLuS7E5mExZtlVHpAzFuElxX5Q%3D%3D";
    const endpoint = "https://func-copilot-demo-003.azurewebsites.net/api/HttpTriggerTest?code=uHA6ljrTv8xx-cBdBGhBKFQE3bNN0Ufx-fEm31UykdYiAzFu9Ndw9g%3D%3D";

    /*
    const searchQuery = {
        search: userInput,
        top: 5 // Number of results to return
    };
    */

    const searchQuery = {
        "name": "Azure"
    }

    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'api-key': `${apiKey}`
        },
        body: JSON.stringify(searchQuery)
    });

    const data = await response.json();

    return data;
}

//function to create side navigation links
async function createSidenavLinks() {
    try {
        const config = await fetchConfig();

        const sidenav = document.getElementById('nav-container').querySelector('nav ul');
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

//code to get documents from Azure Storage
async function getDocuments() {
    const config = await fetchConfig();

    const accountName = config.AZURE_STORAGE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_STORAGE_CONTAINER_NAME;
    const sasTokenConfig = config.AZURE_STORAGE_SAS_TOKEN;
    const fileTypes = config.FILE_TYPES;

    // Construct the SAS token from the individual components
    //const sasToken = `sv=${sasTokenConfig.SV}&comp=${sasTokenConfig.COMP}&include=${sasTokenConfig.INCLUDE}&restype=${sasTokenConfig.RESTYPE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&st=${sasTokenConfig.ST}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    //const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;
    const storageUrl = config.AZURE_SEARCH_FULL_URL;
    
    fetch(`${storageUrl}`, {
        method: 'GET',
        headers: {
            'Content-Type': 'text/xml',
            'Cache-Control': 'no-cache'
        }
    })
        .then(response => response.text())
        .then(data => {
            // Parse the XML response
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(data, "text/xml");
            const blobs = xmlDoc.getElementsByTagName("Blob");

            // Get the document list and sample rows
            const docList = document.getElementById('document-list');
            const sampleRows = document.querySelectorAll('.document-row.sample');

            const testUrl = "https://stcopilotdemo003.blob.core.windows.net/content/AI Builder governance whitepaper.pdf?sv=2022-11-02&include=metadata&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-10-16T04:00:00Z&st=2024-10-15T04:00:00Z&spr=https&sig=1R8tRUu0Tloc8nW33zc548rA9fSXXGRMAukfJOOncVc%3D";

            // Clear existing document rows except the header
            const existingRows = docList.querySelectorAll('.document-row:not(.header)');
            existingRows.forEach(row => row.style.display = 'none');

            if (blobs.length === 0) {
                // Show sample rows if no results
                sampleRows.forEach(row => row.style.display = '');
            } else {
                // Hide sample rows if there are results
                sampleRows.forEach(row => row.style.display = 'none');

                // Iterate over the blobs and process them
                Array.from(blobs).forEach(blob => {
                    const blobName = blob.getElementsByTagName("Name")[0].textContent;
                    const lastModified = blob.getElementsByTagName("Last-Modified")[0].textContent;
                    const contentType = blob.getElementsByTagName("Content-Type")[0].textContent.replace('vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx').replace('vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
                    let blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;
                    blobUrl = blobUrl.replace("&comp=list", "").replace("&restype=container", "");
                    const blobSize = formatBytes(parseInt(blob.getElementsByTagName("Content-Length")[0].textContent));

                    // Create the document row
                    const documentRow = document.createElement('div');
                    documentRow.className = 'document-row';

                    // Create the document cells
                    const previewCell = document.createElement('div');
                    previewCell.className = 'document-cell preview';

                    previewCell.innerHTML = `<a href="${blobUrl}" target="_blank">${config.ICONS.MAGNIFYING_GLASS.COLOR}${config.ICONS.MAGNIFYING_GLASS.MONOTONE}</a>`;


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
                            contentTypeCell.innerHTML = `${value.SVG}${value.SVG_COLOR} ${contentType}`;
                            fileTypeFound = true;
                            break;
                        }
                    }

                    if (!fileTypeFound) {
                        const svgStyle = iconStyle === 'color' ? `${fileTypes.TXT.SVG_COLOR}` : `${fileTypes.TXT.SVG}`;
                        contentTypeCell.innerHTML = `${fileTypes.TXT.SVG}${fileTypes.TXT.SVG_COLOR} ${contentType}`;
                        //contentTypeCell.textContent = contentType;
                    }

                    const fileSizeCell = document.createElement('div');
                    fileSizeCell.className = 'document-cell file-size';
                    fileSizeCell.textContent = blobSize;

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
        });
}

//code to toggle between chat and document screens
function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
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
        $homeContainer.hide();
    }
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
    const fileTypes = config.FILE_TYPES;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&include=${sasTokenConfig.INCLUDE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&st=${sasTokenConfig.ST}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;

    for (const file of files) {
        const uploadUrl = `${storageUrl}/${file.name}?&${sasToken}`;
        const date = new Date().toUTCString();

        try {
            const response = await fetch(uploadUrl, {
                method: 'PUT',
                headers: {
                    'x-ms-blob-type': 'BlockBlob',
                    'Content-Type': file.type,
                    'Content-Length': file.size.toString(),
                    'x-ms-date': date,
                    'x-ms-version': '2020-10-02',
                    'x-ms-blob-content-type': file.type,
                    'x-ms-blob-type': 'BlockBlob'
                },
                body: file
            });

            if (response.ok) {
                console.log(`Upload successful for ${file.name}.`);
            } else {
                const errorText = await response.text();
                console.error(`Error uploading file ${file.name} to Azure Storage:`, errorText);
            }
        } catch (error) {
            console.error(`Error uploading file ${file.name} to Azure Storage:`, error.message);
        }
    }
    // Clear the file input after successful upload
    clearFileInput();
}

//code to clear file input
function clearFileInput() {
    const fileInput = document.getElementById('file-input');
    fileInput.value = ''; // Clear the file input

    const selectedFilesDiv = document.getElementById('file-list');
    selectedFilesDiv.innerHTML = ''; // Clear the list of selected files
    updatePlaceholder(); // Update the placeholder text
}

//code to upload files to Azure Storage using Azure Storage JavaScript library
async function getSasToken() {
    const sasFunctionAppUrl = config.AZURE_FUNCTION_APP_URL;
    const response = await fetch(`${sasFunctionAppUrl}`); // Assuming the Azure Function App endpoint is /api/getSasToken
    if (!response.ok) {
        throw new Error('Failed to fetch SAS token');
    }
    const data = await response.json();
    return data.sasToken;
}