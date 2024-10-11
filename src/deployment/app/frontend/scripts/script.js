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
            uploadFilesToAzureUsingLibrary(files);
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
    questionBubble.setAttribute('class', 'question-bubble');

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

        //const response = await getAnswer(chatInput);
        const response = await getAnswersFromAzureSearch(chatInput);

        // Create a new chat bubble element
        const chatBubble = document.createElement('div');
        chatBubble.className = 'chat-bubble user';

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

    const userMessageContent = config.AI_REQUEST_BODY.messages.find(message => message.role === 'user').content[0];
    userMessageContent.text = userInput;

    const jsonString = JSON.stringify(config.AI_REQUEST_BODY);

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
    //displayMessage('Azure Copilot', data.reply);
}

//code to send message to Azure Search via Azure Function
async function getAnswersFromAzureSearch(userInput) {
    if (!userInput) return;

    const config = await fetchConfig();

    const apiKey = config.AZURE_SEARCH_API_KEY;
    const searchFunctionName = config.AZURE_SEARCH_FUNCTION_NAME;
    const indexName = config.AZURE_SEARCH_INDEX;
    const endpoint = `https://${searchFunctionName}.azurewebsites.net/api/${searchFunctionName}?code=${apiKey}`;

    const searchQuery = {
        search: userInput,
        top: 5 // Number of results to return
    };

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

    const accountName = config.AZURE_ACCOUNT_NAME;
    const azureStorageUrl = config.AZURE_STORAGE_URL;
    const containerName = config.AZURE_CONTAINER_NAME;
    const sasTokenConfig = config.SAS_TOKEN;
    const fileTypes = config.FILE_TYPES;

    // Construct the SAS token from the individual components
    const sasToken = `sv=${sasTokenConfig.SV}&comp=${sasTokenConfig.COMP}&include=${sasTokenConfig.INCLUDE}&restype=${sasTokenConfig.RESTYPE}&ss=${sasTokenConfig.SS}&srt=${sasTokenConfig.SRT}&sp=${sasTokenConfig.SP}&se=${sasTokenConfig.SE}&st=${sasTokenConfig.ST}&spr=${sasTokenConfig.SPR}&sig=${sasTokenConfig.SIG}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;

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
                    const blobUrl = `https://${accountName}.${azureStorageUrl}/${containerName}/${blobName}?${sasToken}`;

                    // Create the document row
                    const documentRow = document.createElement('div');
                    documentRow.className = 'document-row';

                    // Create the document cells
                    const previewCell = document.createElement('div');
                    previewCell.className = 'document-cell preview';
                    //const previewButton = document.createElement('button');
                    //previewButton.textContent = 'Preview';
                    //previewCell.appendChild(previewButton);
                    //const magStyle = iconStyle === 'color' ? `${config.MAGNIFYING_GLASS.COLOR}` : `${config.MAGNIFYING_GLASS.MONOTONE}`;
                    previewCell.innerHTML = `<a href="${blobUrl}" target="_blank">${config.MAGNIFYING_GLASS.COLOR}${config.MAGNIFYING_GLASS.MONOTONE}</a>`;

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

                    const lastModifiedCell = document.createElement('div');
                    lastModifiedCell.className = 'document-cell';
                    lastModifiedCell.textContent = lastModified;

                    // Append cells to the document row
                    documentRow.appendChild(previewCell);
                    documentRow.appendChild(statusCell);
                    documentRow.appendChild(nameCell);
                    documentRow.appendChild(contentTypeCell);
                    documentRow.appendChild(lastModifiedCell);

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
    const accountName = "stdcdaiprodpoc001";
    const azureStorageUrl = "blob.core.windows.net";
    const containerName = "content";
    const accessKey = "7";

    const sv = "2022-11-02";
    const ss = "bfqt";
    const srt = "sco";
    const sp = "rwdlacupiytfx";
    const se = "2025-10-08T04:00:00Z";
    const st = "2024-10-08T04:00:00Z";
    const spr = "https";
    const sig = "sfSvKnCMycPfgT4y%2FpcMSsW3nXsVr8sLCrR7rAgDgZk%3D";
    const comp = "list";
    const include = "metadata";
    const restype = "container";

    //https://stdcdaiprodpoc001.blob.core.windows.net/?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2025-10-08T04:00:00Z&st=2024-10-08T04:00:00Z&spr=https&sig=sfSvKnCMycPfgT4y%2FpcMSsW3nXsVr8sLCrR7rAgDgZk%3D
    // Construct the SAS token from the individual components
    const sasToken = `sv=${sv}&comp=${comp}&include=${include}&restype=${restype}&ss=${ss}&srt=${srt}&sp=${sp}&se=${se}&st=${st}&spr=${spr}&sig=${sig}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}`;

    async function uploadFiles(files) {
        for (const file of files) {
            const uploadUrl = `${storageUrl}/${file.name}`;
            const date = new Date().toUTCString();
            const stringToSign = `PUT\n\n${file.size}\n\n${file.type}\n\n\n\n\n\n\n\nx-ms-blob-type:BlockBlob\nx-ms-date:${date}\nx-ms-version:2020-10-02\n/${accountName}/${containerName}/${file.name}`;
            const signature = CryptoJS.HmacSHA256(stringToSign, CryptoJS.enc.Base64.parse(accessKey));
            const authorizationHeader = `SharedKey ${accountName}:${CryptoJS.enc.Base64.stringify(signature)}`;

            console.write(`Upload URL: ${uploadUrl}`);

            //const uploadUrl = `${storageUrl}/${file.name}?${sasToken}`;

            try {
                const response = await fetch(uploadUrl, {
                    method: 'PUT',
                    headers: {
                        'x-ms-blob-type': 'BlockBlob',
                        'Content-Type': file.type,
                        'Content-Length': file.size.toString(),
                        'x-ms-date': date,
                        'x-ms-version': '2020-10-02',
                        'Authorization': authorizationHeader
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