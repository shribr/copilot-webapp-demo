# Azure AI Demo

## Overview

This project is a web application that allows users to chat with Azure Copilot. It includes a simple HTML interface and a PowerShell script for deployment.

<img width="1423" alt="azure-ai-demo-home" src="https://github.com/user-attachments/assets/c7ccef22-db76-4307-8728-160ba7a9a1b1">

## Prerequisites

### Core Tools (Required)

- [Node.js](https://nodejs.org/) (version 20 or higher recommended)
- [npm](https://www.npmjs.com/) (package management)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (for deploying to Azure)
- [ms-vscode.azurecli](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azurecli) - Azure CLI tools
- [ms-vscode.powershell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.powershell) - PowerShell language support
- [PowerShell Core](https://github.com/PowerShell/PowerShell) (for running the deployment script)

### .NET Development (Required)

- [ms-dotnettools.csharp](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp) - C# language support
- [ms-dotnettools.dotnet-interactive-vscode](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.dotnet-interactive-vscode) - .NET Interactive Notebooks
- [ms-dotnettools.vscode-dotnet-pack](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-pack) - .NET Pack support
- [ms-dotnettools.vscode-dotnet-runtime](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-runtime) - .NET Runtime support
- [ms-dotnettools.vscode-dotnet-sdk](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-sdk) - .NET SDK support

### GitHub Integration (Required)

- [github.vscode-github-actions](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-github-actions) - GitHub Actions support

### Azure Development Tools (Optional)

- [azps-tools.azps-tools](https://marketplace.visualstudio.com/items?itemName=azps-tools.azps-tools) - Azure PowerShell tools
- [azurite.azurite](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite) - Azure Storage emulator
- [ms-azure-devops.azure-pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines) - Azure Pipelines support
- [ms-azuretools.azure-dev](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev) - Azure development tools
- [ms-azuretools.vscode-apimanagement](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-apimanagement) - Azure API Management tools
- [ms-azuretools.vscode-azure-functions-web](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-functions-web) - Azure Functions tools
- [ms-azuretools.vscode-azureappservice](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureappservice) - Azure App Service tools
- [ms-azuretools.vscode-azurefunctions](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions) - Azure Functions tools
- [ms-azuretools.vscode-azureresourcegroups](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups) - Azure Resource Groups tools
- [ms-azuretools.vscode-azurestaticwebapps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestaticwebapps) - Azure Static Web Apps tools
- [ms-azuretools.vscode-azurestorage](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestorage) - Azure Storage tools
- [ms-azuretools.vscode-azurevirtualmachines](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurevirtualmachines) - Azure Virtual Machines tools
- [ms-azuretools.vscode-bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) - Bicep language support

### GitHub Integration (Optional)

- [github.codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces) - GitHub Codespaces support
- [github.github-vscode-theme](https://marketplace.visualstudio.com/items?itemName=GitHub.github-vscode-theme) - GitHub theme for VS Code
- [github.remotehub](https://marketplace.visualstudio.com/items?itemName=GitHub.remotehub) - GitHub integration for remote repositories
- [github.vscode-pull-request-github](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github) - GitHub Pull Requests and Issues

### AI Tools (Optional)

- [ms-toolsai.vscode-ai](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai) - AI tools for VS Code
- [ms-toolsai.vscode-ai-inference](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-inference) - AI Inference tools
- [ms-toolsai.vscode-ai-remote](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-remote) - AI Remote tools
- [ms-toolsai.vscode-ai-remote-web](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-remote-web) - AI Remote Web tools

### Remote Development (Optional)

- [ms-vscode-remote.remote-containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - Remote Containers support
- [ms-vscode-remote.remote-wsl](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) - Remote WSL support
- [ms-vscode.remote-explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer) - Remote Explorer
- [ms-vscode.remote-repositories](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-repositories) - Remote Repositories
- [ms-vscode.remote-server](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-server) - Remote Server

### Miscellaneous Tools (Optional)

- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) - Code formatter
- [ms-vscode.azure-account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) - Azure Account management
- [ms-vscode.azure-repos](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-repos) - Azure Repos support
- [ms-vscode.live-server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) - Live Server for local development
- [ms-vscode.vscode-node-azure-pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack) - Node.js Azure Pack
- [ms-vsliveshare.vsliveshare](https://marketplace.visualstudio.com/items?itemName=ms-vsliveshare.vsliveshare) - Live Share for collaboration
- [msazurermtools.azurerm-vscode-tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools) - Azure Resource Manager tools
- [redhat.vscode-yaml](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) - YAML language support

## Getting Started

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/your-username/azure-ai-demo.git

   cd azure-ai-demo

   ```

2. Install [Node](https://nodejs.org/) and then install the required VS Code extensions ([extensions.txt](./src/deployment/extensions.txt)) using the following script (make sure you are in the `src/deployment directory`):

   ```
   function Install-Extensions {
    # Define the path to the text file
    $filePath = "extensions.txt"

    # Read all lines from the file
    $extensions = Get-Content -Path $filePath

    # Loop through each extension and install it using the `code` command
    foreach ($extension in $extensions) {
        code --install-extension $extension
    }
   }

   ```

### Deployment

The main PowerShell script [Azure AI Demo Deployment.ps1](./src/deployment/Azure%20AI%20Demo%20Deployment.ps1) automates the deployment of various Azure resources for an Azure AI demo. There is a template titled [parameters.json](./src/deployment/parameters.json) which contains configuration settings for every aspect of the deployment. It includes initialization, helper functions, resource creation, update functions, and logging to ensure a smooth and automated deployment process.

Once the deployment script completes the deployed Azure resources should look like this:

![Azure-AI-Demo-Azure-Resource-Visualizer](https://github.com/user-attachments/assets/3ef373f7-e394-4040-b805-3e0031818153)

### Workflow of the Script

1. **Initialization and Setup:**

   - The script begins by setting the default parameters file (`parameters.json`).
   - It defines global variables for resource types and KeyVault secrets.
   - It sets the deployment path based on the current location.

2. **Parameter Initialization:**

   - The `Initialize-Parameters` function reads parameters from the specified JSON file.
   - It sets global variables for various Azure resources and configurations.
   - It retrieves the subscription ID, tenant ID, object ID, and user principal name using Azure CLI commands.

3. **Resource Creation Functions:**

   - The script defines multiple functions to create various Azure resources, such as:
     - `New-ResourceGroup`: Creates a new resource group.
     - `New-Resources`: Creates multiple Azure resources like storage accounts, app service plans, search services, etc.
     - `New-AppService`: Creates and deploys app services (web apps or function apps).
     - `New-KeyVault`: Creates a Key Vault and sets access policies.
     - `New-ManagedIdentity`: Creates a new managed identity.
     - `New-PrivateEndPoint`: Creates a new private endpoint.
     - `New-SearchDataSource`, `New-SearchIndex`, `New-SearchIndexer`: Create search-related resources.
     - `New-VirtualNetwork`, `New-SubNet`: Create virtual network and subnets.
     - `New-AIHubAndModel`: Creates AI Hub and AI Model.
     - `New-ApiManagementService`: Creates and deploys API Management service.

4. **Helper Functions:**

   - The script includes several helper functions for various tasks, such as:
     - `ConvertTo-ProperCase`: Converts a string to proper case.
     - `Find-AppRoot`: Finds the app root directory.
     - `Format-ErrorInfo`, `Format-AIModelErrorInfo`: Format error information.
     - `Get-CognitiveServicesApiKey`: Retrieves the API key for Cognitive Services.
     - `Get-LatestApiVersion`: Gets the latest API version for a resource type.
     - `Get-LatestDotNetRuntime`: Gets the latest .NET runtime version.
     - `Get-RandomInt`: Generates a random integer.
     - `Get-Parameters-Sorted`: Alphabetizes the parameters object.
     - `Get-SearchIndexes`: Checks if a search index exists.
     - `Get-UniqueSuffix`: Finds a unique suffix for resource names.
     - `Get-ValidServiceName`: Ensures the service name is valid.
     - `Invoke-AzureRestMethod`: Invokes an Azure REST API method.
     - `New-RandomPassword`: Generates a random password.
     - `Remove-AzureResourceGroup`: Deletes Azure resource groups.
     - `Restore-SoftDeletedResource`: Restores soft-deleted resources.
     - `Set-DirectoryPath`: Sets the directory location.
     - `Set-KeyVaultAccessPolicies`, `Set-KeyVaultRoles`, `Set-KeyVaultSecrets`: Manage Key Vault access and secrets.
     - `Set-RBACRoles`: Assigns RBAC roles to a managed identity.
     - `Split-Guid`: Splits a GUID and returns the first 8 characters.
     - `Test-ResourceGroupExists`, `Test-ResourceExists`: Check if a resource group or resource exists.
     - `Update-ContainerRegistryFile`, `Update-MLWorkspaceFile`, `Update-AIConnectionFile`, `Update-ConfigFile`: Update configuration files to be used by front-end JavaScript code. This includes all of the service names, urls and any newly generated API keys.
     - `Write-Log`: Writes messages to a log file.

5. **Deployment Process:**

   - The `Start-Deployment` function orchestrates the deployment process:
     - It initializes the sequence number and checks if the log file exists.
     - It logs the start time and sequence number.
     - It checks if the resource group exists and creates it if necessary.
     - It creates various Azure resources by calling the respective functions.
     - It logs the total execution time and writes it to the log file.

6. **Main Script Execution:**
   - It initializes parameters by calling [`Initialize-Parameters`].
   - It sets the user-assigned identity name.
   - It sets the directory path to the deployment path.
   - It starts the deployment by calling [`Start-Deployment`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2FAzure%20AI%20Demo%20Deployment.ps1%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A2155%2C%22character%22%3A9%7D%7D%5D%2C%22842234b1-bc4e-4ae5-b33b-53fd77feca09%22%5D "Go to definition").

### Project Structure

- **Azure AI Demo Deployment.ps1**: Main deployment script.
- **CognitiveServices.json**: Configuration file for Cognitive Services.
- **app/**: Directory for application-specific files.
  - **ai.connection.yaml**: AI connection configuration file.
  - **container.registry.yaml**: Container registry configuration file.
  - **frontend/**: Contains frontend application files.
    - **config.blank.json**: Blank configuration file for the frontend.
    - **config.json**: Configuration file for the frontend.
    - **css/**: Directory for CSS files.
      - **styles.css**: Main stylesheet.
    - **favicon.ico**: Favicon for the frontend.
    - **images/**: Directory for image files.
      - **Azure-AI-Demo-Azure-Resource-Visualizer.png**: Screenshot image.
      - **favicon.png**: Favicon image.
      - **azure-ai-demo-chat.png**: Chat screenshot.
      - **azure-ai-demo-existing-docs.png**: Existing documents screenshot.
      - **azure-ai-demo-selected-docs.png**: Documents selected for upload.
      - **azure-ai-demo-upload-docs.png**: Upload documents interface.
      - **tech_ai_background.jpg**: Background image.
      - **site-logo-custom.png**: Custom site logo used for branding.
      - **site-logo-default.png**: Default site logo (generic office building).
    - **index.html**: Main HTML file for the frontend.
    - **scripts/**: Directory for JavaScript files.
      - **script.js**: Main JavaScript file.
    - **web.config**: Web configuration file.
  - **functions/**: Directory for Azure Functions.
    - **chat/**: Directory for chat-related functions.
      - **AIChatCompletion.cs**: AI chat completion function.
      - **ChatCompletion.cs**: Chat completion function.
      - **ChatCompletion.csproj**: Project file for chat completion.
      - **ChatCompletion.sln**: Solution file for chat completion.
      - **ChatContext.cs**: Chat context class.
      - **ChatHistory.cs**: Chat history class.
      - **ChatOrchestrator.cs**: Chat orchestrator class.
      - **IChatCompletion.cs**: Interface for chat completion.
      - **Properties/**: Directory for project properties.
        - **launchSettings.json**: Launch settings for the project.
  - **ml.workspace.yaml**: Machine learning workspace configuration file.
  - **package-lock.json**: NPM package lock file.
  - **package.json**: NPM package file.
  - **temp/**: Temporary files directory.
- **deployment.log**: Log file for the deployment process.
- **directory_structure.txt**: File containing the directory structure.
- **launch.json**: Launch configuration file.
- **parameters backup.json**: Backup of parameters file.
- **parameters.json**: Parameters file for the deployment.
- **search-index-schema.json**: Search index schema file.
- **search-indexer-schema.json**: Search indexer schema file.
- **server.js**: Local http server JavaScript file.
- **settings.json**: Settings file.

### Directory Structure

```plaintext

├── Azure AI Demo Deployment.ps1
├── CognitiveServices.json
├── app
│   ├── ai.connection.yaml
│   ├── container.registry.yaml
│   ├── frontend
│   │   ├── config.blank.json
│   │   ├── config.json
│   │   ├── css
│   │   │   ├── styles.css
│   │   ├── favicon.ico
│   │   ├── images
│   │   │   ├── azure-ai-demo-chat.png
│   │   │   ├── azure-ai-demo-existing-docs.png
│   │   │   ├── azure-ai-demo-selected-docs.png
│   │   │   ├── azure-ai-demo-upload-docs.png
│   │   │   ├── building.png
│   │   │   ├── favicon.png
│   │   │   ├── site-logo-custom.png
│   │   │   ├── site-logo-default.png
│   │   │   └── tech_ai_background.jpg
│   │   ├── index.html
│   │   ├── scripts
│   │   │   └── script.js
│   │   └── web.config
│   ├── functions
│   │   └── chat
│   │       ├── AIChatCompletion.cs
│   │       ├── ChatCompletion.cs
│   │       ├── ChatCompletion.csproj
│   │       ├── ChatCompletion.sln
│   │       ├── ChatContext.cs
│   │       ├── ChatHistory.cs
│   │       ├── ChatOrchestrator.cs
│   │       ├── IChatCompletion.cs
│   │       ├── host.json
│   ├── ml.workspace.yaml
│   ├── package-lock.json
│   ├── package.json
│   └── temp
├── deployment.log
├── launch.json
├── parameters.json
├── search-index-schema.json
├── search-indexer-schema.json
├── server.js
└── settings.json

```

### Development Server

To start the development server, navigate to the `src/deployment` directory and run the following command:

```

node server.js

```

This should initialize a local http instance of the solution on port 3000.

### Web Application Screens

The index.html file includes the following screens:

<img width="1423" alt="azure-ai-demo-home" src="https://github.com/user-attachments/assets/c7ccef22-db76-4307-8728-160ba7a9a1b1">

<img width="1423" alt="azure-ai-demo-upload-docs" src="https://github.com/user-attachments/assets/fdb09be6-1a4c-4e22-a0c8-c8ebd9927a35">

<img width="1153" alt="azure-ai-demo-selected-docs" src="https://github.com/user-attachments/assets/e4fc88ab-ed5e-48a4-80c2-62e21db868e0">

<img width="1164" alt="azure-ai-demo-existing-docs" src="https://github.com/user-attachments/assets/cfdcf09f-e508-49c1-8f8a-c698ac54feae">

<img width="1410" alt="azure-ai-demo-chat" src="https://github.com/user-attachments/assets/63398052-61e4-42e7-a2eb-c7bbbfb23952">

<img width="1409" alt="azure-ai-demo-response" src="https://github.com/user-attachments/assets/c85dfacd-76e4-45c7-827d-4cceaf808a9b">

### Chat Workflow

For a more in-depth understanding of the chat workflow click [here](./README_CHATWORKFLOW.md)

### Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### License

This project is licensed under the MIT License. See the LICENSE file for details.
