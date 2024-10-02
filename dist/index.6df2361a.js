$(document).ready(function() {
    getDocuments();
    $("#send-button").on("click", sendMessage);
    //code to send chat message to Azure Copilot
    async function sendMessage() {
        const userInput = $("#user-input").val();
        if (!userInput) return;
        displayMessage("User", userInput);
        $("#user-input").val("");
        const response = await fetch("https://eastus.api.cognitive.microsoft.com/", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer 835bba103fea40c9adab54ee45dc6902"
            },
            body: JSON.stringify({
                message: userInput
            })
        });
        const data = await response.json();
        displayMessage("Azure Copilot", data.reply);
    }
    function displayMessage(sender, message) {
        const chatDisplay = $("#chat-display");
        const messageElement = $("<div>").text(`${sender}: ${message}`);
        chatDisplay.append(messageElement);
        chatDisplay.scrollTop(chatDisplay[0].scrollHeight);
    }
    //code to toggle between chat and document screens
    function getQueryParam(param) {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get(param);
    }
    function toggleDisplay(screen) {
        const $chatContainer = $("#chat-container");
        const $documentContainer = $("#document-container");
        if (screen === "chat") {
            $chatContainer.show();
            $documentContainer.hide();
        } else if (screen === "documents") {
            $chatContainer.hide();
            $documentContainer.show();
        } else {
            $chatContainer.hide();
            $documentContainer.hide();
        }
    }
    const screen = getQueryParam("screen");
    toggleDisplay(screen);
    // Add event listeners to navigation links
    $("#nav-container nav ul li a").on("click", function(event) {
        event.preventDefault();
        const screen = new URL(this.href).searchParams.get("screen");
        toggleDisplay(screen);
        history.pushState(null, "", this.href);
    });
    document.getElementById("file-input").addEventListener("change", function(event) {
        const fileList = document.getElementById("file-list");
        const noFilesPlaceholder = document.getElementById("no-files-placeholder");
        const uploadButton = document.getElementById("upload-button");
        fileList.innerHTML = ""; // Clear the list
        const updatePlaceholder = ()=>{
            const fileCount = document.getElementById("file-input").files.length;
            if (fileCount === 0) {
                noFilesPlaceholder.textContent = "No files selected";
                noFilesPlaceholder.style.display = "block";
                uploadButton.disabled = true;
            } else {
                noFilesPlaceholder.textContent = `${fileCount} file(s) selected`;
                noFilesPlaceholder.style.display = "block";
                uploadButton.disabled = false;
            }
        };
        updatePlaceholder();
        Array.from(event.target.files).forEach((file, index)=>{
            const listItem = document.createElement("li");
            listItem.textContent = file.name;
            const removeButton = document.createElement("button");
            removeButton.textContent = "Remove";
            removeButton.addEventListener("click", (e)=>{
                e.stopPropagation(); // Prevent triggering the file input click event
                const filesArray = Array.from(document.getElementById("file-input").files);
                filesArray.splice(index, 1);
                const dataTransfer = new DataTransfer();
                filesArray.forEach((file)=>dataTransfer.items.add(file));
                document.getElementById("file-input").files = dataTransfer.files;
                listItem.remove();
                updatePlaceholder();
                // Clear the file input if no files are left
                if (filesArray.length === 0) document.getElementById("file-input").value = "";
            });
            listItem.appendChild(removeButton);
            fileList.appendChild(listItem);
        });
    });
    // Trigger file input click when custom button is clicked
    document.getElementById("choose-files-button").addEventListener("click", function(event) {
        event.preventDefault(); // Prevent default button behavior
        document.getElementById("file-input").click();
    });
    // Filter existing documents based on the name field
    document.getElementById("filter-input").addEventListener("input", function(event) {
        const filterValue = event.target.value.toLowerCase();
        const documentRows = document.querySelectorAll("#document-list .document-row:not(.header)");
        documentRows.forEach((row)=>{
            const nameCell = row.querySelector(".document-cell:nth-child(3)");
            if (nameCell.textContent.toLowerCase().includes(filterValue)) row.style.display = "";
            else row.style.display = "none";
        });
    });
});
function getDocuments() {
    // Fetch the list of blobs from the Azure Storage container
    fetch("https://stdcdaiprodpoc001.blob.core.windows.net/?sv=2022-11-02&ss=bfqt&sp=rwdlacupiytfx&se=2024-10-02T14:42:41Z&st=2024-10-02T06:42:41Z&spr=https&srt=sco&sig=sWuQtbX2LVibdgi%2BCNcEkvfKP9BiskHO2I5OiAc3%2B%2BE%3D&comp=list", {
        method: "GET",
        mode: "no-cors",
        headers: {
            "x-ms-version": "2020-04-08"
        }
    }).then((response)=>response.text()).then((data)=>{
        // Parse the XML response
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(data, "application/xml");
        const blobs = xmlDoc.getElementsByTagName("Blob");
        // Iterate over the blobs and process them
        const fileList = document.getElementById("file-list");
        Array.from(blobs).forEach((blob)=>{
            const blobName = blob.getElementsByTagName("Name")[0].textContent;
            const listItem = document.createElement("li");
            listItem.textContent = blobName;
            fileList.appendChild(listItem);
        });
    }).catch((error)=>console.error("Error:", error));
}

//# sourceMappingURL=index.6df2361a.js.map
