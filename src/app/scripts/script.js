
$(document).ready(function () {

    getDocuments();
    //updateFileCount();

    $('#send-button').on('click', sendMessage);

    const screen = getQueryParam('screen');
    toggleDisplay(screen);

    // Add event listeners to navigation links
    $('#nav-container nav ul li a').on('click', function (event) {
        event.preventDefault();
        const screen = new URL(this.href).searchParams.get('screen');
        toggleDisplay(screen);
        history.pushState(null, '', this.href);
    });

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

        documentRows.forEach(row => {
            const nameCell = row.querySelector('.document-cell:nth-child(3)');
            if (nameCell.textContent.toLowerCase().includes(filterValue)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });

    // Event listener for upload button
    document.getElementById('upload-button').addEventListener('click', function () {
        const files = document.getElementById('file-input').files;
        if (files.length > 0) {
            uploadFilesToAzure(files);
        } else {
            console.log('No files selected for upload.');
        }
    });
});

// Function to update the file count
function updateFileCount() {
    const fileCount = document.getElementById('file-input').files.length;
    document.getElementById('file-count').textContent = `Files selected: ${fileCount}`;
}

//code to get documents from Azure Storage
function getDocuments() {

    const accountName = "stdcdaiprodpoc001";
    const azureStorageUrl = "blob.core.windows.net";

    //const sasToken = "sWuQtbX2LVibdgi%2BCNcEkvfKP9BiskHO2I5OiAc3%2B%2BE%3D";
    const containerName = "content";

    const sv = "2022-11-02";
    const ss = "bfqt";
    const srt = "sco";
    const sp = "rwdlacupiytfx";
    const se = "2024-10-07T11:27:12Z";
    const st = "2024-10-07T03:27:12Z";
    const spr = "https";
    const sig = "1%2B4xVbGWQ%2FFeK4Ypg3xq4CMDuSTkTAI2SF%2Bq0a%2FlSsI%3D";
    const comp = "list";
    const include = "metadata";
    const restype = "container";

    // Construct the SAS token from the individual components
    const sasToken = `comp=${comp}&include=${include}&restype=${restype}&sv=${sv}&ss=${ss}&srt=${srt}&sp=${sp}&se=${se}&st=${st}&spr=${spr}&sig=${sig}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;

    //const blobServiceClient = new azure.StoragBlob.BlobServiceClient(`${storageUrl}?${sasToken}`);
    //const containerClient = blobServiceClient.getContainerClient(containerName);

    fetch(`${storageUrl}`, {
        method: 'GET'
    })
        .then(response => response.text())
        .then(data => {
            // Parse the XML response
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(data, "application/xml");
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
                    const contentType = blob.getElementsByTagName("Content-Type")[0].textContent;

                    // Create the document row
                    const documentRow = document.createElement('div');
                    documentRow.className = 'document-row';

                    // Create the document cells
                    const previewCell = document.createElement('div');
                    previewCell.className = 'document-cell';
                    const previewButton = document.createElement('button');
                    previewButton.textContent = 'Preview';
                    previewCell.appendChild(previewButton);

                    const statusCell = document.createElement('div');
                    statusCell.className = 'document-cell';
                    statusCell.textContent = 'Active';

                    const nameCell = document.createElement('div');
                    nameCell.className = 'document-cell';
                    nameCell.textContent = blobName;

                    const typeCell = document.createElement('div');
                    typeCell.className = 'document-cell';
                    typeCell.textContent = contentType;

                    const dateCell = document.createElement('div');
                    dateCell.className = 'document-cell';
                    const formattedDate = new Date(lastModified).toLocaleString('en-US', {
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                        hour12: true
                    }).replace(',', '');
                    dateCell.textContent = formattedDate;

                    //test

                    // Append the cells to the document row
                    documentRow.appendChild(previewCell);
                    documentRow.appendChild(statusCell);
                    documentRow.appendChild(nameCell);
                    documentRow.appendChild(typeCell);
                    documentRow.appendChild(dateCell);

                    // Append the document row to the document list
                    docList.appendChild(documentRow);
                });
            }
        })
        .catch(error => console.error('Error:', error));
}

//code to send chat message to Azure Copilot
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

//code to display chat messages
function displayMessage(sender, message) {
    const chatDisplay = $('#chat-display');
    const messageElement = $('<div>').text(`${sender}: ${message}`);
    chatDisplay.append(messageElement);
    chatDisplay.scrollTop(chatDisplay[0].scrollHeight);
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
    //const accountName = config.AZURE_ACCOUNT_NAME;
    //const sasToken = config.AZURE_SAS_TOKEN;
    //const containerName = config.AZURE_CONTAINER_NAME;

    const accountName = "stdcdaiprodpoc001";
    const azureStorageUrl = "blob.core.windows.net";
    //const sasToken = "sWuQtbX2LVibdgi%2BCNcEkvfKP9BiskHO2I5OiAc3%2B%2BE%3D";
    const containerName = "content";
    const sv = "2022-11-02";
    const ss = "bfqt";
    const srt = "sco";
    const sp = "rwdlacupiytfx";
    const se = "2024-10-07T11:27:12Z";
    const st = "2024-10-07T03:27:12Z";
    const spr = "https";
    const sig = "1%2B4xVbGWQ%2FFeK4Ypg3xq4CMDuSTkTAI2SF%2Bq0a%2FlSsI%3D";
    const comp = "list";
    const include = "metadata";
    const restype = "container";

    // Construct the SAS token from the individual components
    const sasToken = `comp=${comp}&include=${include}&restype=${container}&sv=${sv}&ss=${ss}&srt=${srt}&sp=${sp}&se=${se}&st=${st}&spr=${spr}&sig=${sig}`;

    const storageUrl = `https://${accountName}.${azureStorageUrl}/${containerName}?${sasToken}`;

    const blobServiceClient = new azure.StoragBlob.BlobServiceClient(`${storageUrl}?${sasToken}`);
    const containerClient = blobServiceClient.getContainerClient(containerName);

    for (const file of files) {
        const blockBlobClient = containerClient.getBlockBlobClient(file.name);
        try {
            const uploadBlobResponse = await blockBlobClient.uploadBrowserData(file);
            console.log(`Upload successful for ${file.name}. requestId: ${uploadBlobResponse.requestId}`);
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
}

async function getSasToken() {
    const sasFunctionAppUrl = config.AZURE_FUNCTION_APP_URL;
    const response = await fetch(`${sasFunctionAppUrl}`); // Assuming the Azure Function App endpoint is /api/getSasToken
    if (!response.ok) {
        throw new Error('Failed to fetch SAS token');
    }
    const data = await response.json();
    return data.sasToken;
}
