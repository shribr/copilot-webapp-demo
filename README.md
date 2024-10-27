# Azure AI Demo

## Overview

This project is a web application that allows users to chat with Azure Copilot. It includes a simple HTML interface and a PowerShell script for deployment.

## Prerequisites

- [Node.js](https://nodejs.org/) (version 14 or higher recommended)
- [npm](https://www.npmjs.com/) or [Yarn](https://yarnpkg.com/) (package managers)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (for deploying to Azure)
- [PowerShell Core](https://github.com/PowerShell/PowerShell) (for running the deployment script)
- [azps-tools.azps-tools](https://marketplace.visualstudio.com/items?itemName=azps-tools.azps-tools)
- [azurite.azurite](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite)
- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [github.codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces)
- [github.github-vscode-theme](https://marketplace.visualstudio.com/items?itemName=GitHub.github-vscode-theme)
- [github.remotehub](https://marketplace.visualstudio.com/items?itemName=GitHub.remotehub)
- [github.vscode-github-actions](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-github-actions)
- [github.vscode-pull-request-github](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
- [ms-azure-devops.azure-pipelines](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines)
- [ms-azuretools.azure-dev](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.azure-dev)
- [ms-azuretools.vscode-apimanagement](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-apimanagement)
- [ms-azuretools.vscode-azure-functions-web](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-functions-web)
- [ms-azuretools.vscode-azureappservice](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureappservice)
- [ms-azuretools.vscode-azurecontainerapps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurecontainerapps)
- [ms-azuretools.vscode-azurefunctions](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)
- [ms-azuretools.vscode-azureresourcegroups](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups)
- [ms-azuretools.vscode-azurestaticwebapps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestaticwebapps)
- [ms-azuretools.vscode-azurestorage](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurestorage)
- [ms-azuretools.vscode-azurevirtualmachines](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurevirtualmachines)
- [ms-azuretools.vscode-bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- [ms-azuretools.vscode-cosmosdb](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-cosmosdb)
- [ms-azuretools.vscode-docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
- [ms-azuretools.vscode-logicapps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-logicapps)
- [ms-dotnettools.csharp](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp)
- [ms-dotnettools.dotnet-interactive-vscode](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.dotnet-interactive-vscode)
- [ms-dotnettools.vscode-dotnet-pack](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-pack)
- [ms-dotnettools.vscode-dotnet-runtime](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-runtime)
- [ms-dotnettools.vscode-dotnet-sdk](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-sdk)
- [ms-edgedevtools.vscode-edge-devtools](https://marketplace.visualstudio.com/items?itemName=ms-edgedevtools.vscode-edge-devtools)
- [ms-toolsai.jupyter](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- [ms-toolsai.jupyter-keymap](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter-keymap)
- [ms-toolsai.jupyter-renderers](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter-renderers)
- [ms-toolsai.vscode-ai](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai)
- [ms-toolsai.vscode-ai-inference](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-inference)
- [ms-toolsai.vscode-ai-remote](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-remote)
- [ms-toolsai.vscode-ai-remote-web](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai-remote-web)
- [ms-toolsai.vscode-jupyter-cell-tags](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-jupyter-cell-tags)
- [ms-toolsai.vscode-jupyter-slideshow](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-jupyter-slideshow)
- [ms-vscode-remote.remote-containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [ms-vscode-remote.remote-wsl](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)
- [ms-vscode.azure-account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)
- [ms-vscode.azure-repos](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-repos)
- [ms-vscode.azurecli](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azurecli)
- [ms-vscode.live-server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)
- [ms-vscode.powershell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.powershell)
- [ms-vscode.remote-explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer)
- [ms-vscode.remote-repositories](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-repositories)
- [ms-vscode.remote-server](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-server)
- [ms-vscode.vscode-github-issue-notebooks](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-github-issue-notebooks)
- [ms-vscode.vscode-node-azure-pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)
- [ms-vscode.vscode-speech](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-speech)
- [ms-vsliveshare.vsliveshare](https://marketplace.visualstudio.com/items?itemName=ms-vsliveshare.vsliveshare)
- [msazurermtools.azurerm-vscode-tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools)
- [redhat.vscode-yaml](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

## Getting Started

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/your-username/azure-ai-demo.git
   cd azure-ai-demo

   ```

2. Install the dependencies:

   ```
   npm install

   or

   yarn install

   ```

### Development

To start the development server, run:

```
npm start

or

yarn start

```

### Building for Production

To build the project for production, run:

```
npm run build

or

yarn build

```

This will create a dist directory with the bundled files.

### Deployment

### Overview

This PowerShell script automates the deployment of various Azure resources for an Azure AI demo. It is divided into several sections, each responsible for different aspects of the deployment process.

### Sections Breakdown

#### 1. **Initialization and Configuration**
- **Script Metadata**: Provides metadata about the script, including prerequisites and usage instructions.
- **Parameter Initialization**: Sets default parameters and reads parameters from a JSON file.
- **Global Variables**: Defines global variables for resource types, KeyVault secrets, and paths.

#### 2. **Helper Functions**
- **ConvertTo-ProperCase**: Converts a string to proper case.
- **Find-AppRoot**: Finds the root directory of the application.
- **Format-ErrorInfo**: Formats error information from a message.
- **Get-CognitiveServicesApiKey**: Retrieves the API key for Cognitive Services.
- **Get-LatestApiVersion**: Gets the latest API version for a resource type.
- **Get-LatestDotNetRuntime**: Gets the latest .NET runtime version.
- **Get-RandomInt**: Generates a random integer.
- **Get-Parameters-Sorted**: Alphabetizes the parameters object.
- **Get-SearchIndexes**: Checks if a search index exists.
- **Get-UniqueSuffix**: Finds a unique suffix for resource names.
- **Get-ValidServiceName**: Ensures the service name is valid.
- **Invoke-AzureRestMethod**: Invokes an Azure REST API method.
- **Split-Guid**: Splits a GUID and returns the first 8 characters.
- **Test-DirectoryExists**: Checks if a directory exists and creates it if not.
- **Test-ResourceGroupExists**: Checks if a resource group exists.
- **Test-ResourceExists**: Checks if a resource exists.

#### 3. **Resource Creation Functions**
- **New-AIHubAndModel**: Creates AI Hub and AI Model.
- **New-ApiManagementService**: Creates and deploys API Management service.
- **New-AppService**: Creates and deploys app services (web app or function app).
- **New-KeyVault**: Creates a Key Vault.
- **New-ManagedIdentity**: Creates a new managed identity.
- **New-PrivateEndPoint**: Creates a new private endpoint.
- **New-RandomPassword**: Generates a random password.
- **New-ResourceGroup**: Creates a new resource group.
- **New-Resources**: Creates various Azure resources.
- **New-SearchDataSource**: Creates a new search datasource.
- **New-SearchIndex**: Creates a new search index.
- **New-SearchIndexer**: Creates a new search indexer.
- **New-SubNet**: Creates a new subnet.
- **New-VirtualNetwork**: Creates a new virtual network.
- **Remove-AzureResourceGroup**: Deletes Azure resource groups.
- **Restore-SoftDeletedResource**: Restores soft-deleted resources.
- **Set-DirectoryPath**: Sets the directory location.
- **Set-KeyVaultAccessPolicies**: Sets Key Vault access policies.
- **Set-KeyVaultRoles**: Creates Key Vault roles.
- **Set-KeyVaultSecrets**: Creates secrets in Key Vault.
- **Set-RBACRoles**: Assigns RBAC roles to a managed identity.

#### 4. **Update Functions**
- **Update-ContainerRegistryFile**: Updates the container registry file.
- **Update-MLWorkspaceFile**: Updates the ML workspace connection file.
- **Update-AIConnectionFile**: Updates the AI connection file.
- **Update-ConfigFile**: Updates the configuration file.

#### 5. **Logging Functions**
- **Write-Log**: Writes messages to a log file.

#### 6. **Main Script Execution**
- **Initialize Parameters**: Calls the [`Initialize-Parameters`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2FAzure%20AI%20Demo%20Deployment.ps1%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A535%2C%22character%22%3A9%7D%7D%5D%2C%226c3e5ad1-bfff-42bb-b65b-373e7ed359b5%22%5D "Go to definition") function to set up parameters.
- **Alphabetize Parameters**: Calls the [`Get-Parameters-Sorted`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2FAzure%20AI%20Demo%20Deployment.ps1%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A356%2C%22character%22%3A9%7D%7D%5D%2C%226c3e5ad1-bfff-42bb-b65b-373e7ed359b5%22%5D "Go to definition") function to sort parameters.
- **Set Directory Path**: Sets the directory path for deployment.
- **Start Deployment**: Calls the [`Start-Deployment`](command:_github.copilot.openSymbolFromReferences?%5B%22%22%2C%5B%7B%22uri%22%3A%7B%22scheme%22%3A%22file%22%2C%22authority%22%3A%22%22%2C%22path%22%3A%22%2FUsers%2Famischreiber%2Fsource%2Frepos%2Fazure-ai-demo%2Fsrc%2Fdeployment%2FAzure%20AI%20Demo%20Deployment.ps1%22%2C%22query%22%3A%22%22%2C%22fragment%22%3A%22%22%7D%2C%22pos%22%3A%7B%22line%22%3A2155%2C%22character%22%3A9%7D%7D%5D%2C%226c3e5ad1-bfff-42bb-b65b-373e7ed359b5%22%5D "Go to definition") function to begin the deployment process.

### Summary

This script is a comprehensive tool for deploying a variety of Azure resources required for an Azure AI demo. It includes initialization, helper functions, resource creation, update functions, and logging to ensure a smooth and automated deployment process.

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
      - **css from chat.md**: CSS file from chat.
      - **css2 from chat.md**: Another CSS file from chat.
      - **styles.css**: Main stylesheet.
      - **styles_alphabetized.css**: Alphabetized stylesheet.
    - **favicon.ico**: Favicon for the frontend.
    - **images/**: Directory for image files.
      - **Screenshot 2024-10-09 at 11.41.55 AM.png**: Screenshot image.
      - **favicon.png**: Favicon image.
      - **technology-background-with-a-ai-concept-vector.jpg**: Background image.
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
      - **bin/**: Directory for compiled binaries.
        - **Debug/**: Debug build directory.
          - **net6.0/**: .NET 6.0 build directory.
      - **host.json**: Host configuration file for Azure Functions.
      - **obj/**: Directory for build artifacts.
        - **ChatCompletion.csproj.nuget.dgspec.json**: NuGet specification file.
        - **ChatCompletion.csproj.nuget.g.props**: NuGet properties file.
        - **ChatCompletion.csproj.nuget.g.targets**: NuGet targets file.
        - **Debug/**: Debug build directory.
          - **net6.0/**: .NET 6.0 build directory.
            - **ChatCompletion.AssemblyInfo.cs**: Assembly info file.
            - **ChatCompletion.AssemblyInfoInputs.cache**: Assembly info inputs cache.
            - **ChatCompletion.GeneratedMSBuildEditorConfig.editorconfig**: MSBuild editor config.
            - **ChatCompletion.assets.cache**: Assets cache.
            - **ChatCompletion.csproj.AssemblyReference.cache**: Assembly reference cache.
            - **ref/**: Reference directory.
            - **refint/**: Reference intermediate directory.
        - **project.assets.json**: Project assets file.
        - **project.nuget.cache**: NuGet cache file.
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
- **server.js**: Server-side JavaScript file.
- **settings.json**: Settings file.
.
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
│   │   │   ├── css from chat.md
│   │   │   ├── css2 from chat.md
│   │   │   ├── styles.css
│   │   │   └── styles_alphabetized.css
│   │   ├── favicon.ico
│   │   ├── images
│   │   │   ├── Screenshot 2024-10-09 at 11.41.55 AM.png
│   │   │   ├── favicon.png
│   │   │   └── technology-background-with-a-ai-concept-vector.jpg
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
│   │       ├── Properties
│   │       │   └── launchSettings.json
│   │       ├── bin
│   │       │   └── Debug
│   │       │       └── net6.0
│   │       ├── host.json
│   │       └── obj
│   │           ├── ChatCompletion.csproj.nuget.dgspec.json
│   │           ├── ChatCompletion.csproj.nuget.g.props
│   │           ├── ChatCompletion.csproj.nuget.g.targets
│   │           ├── Debug
│   │           │   └── net6.0
│   │           │       ├── ChatCompletion.AssemblyInfo.cs
│   │           │       ├── ChatCompletion.AssemblyInfoInputs.cache
│   │           │       ├── ChatCompletion.GeneratedMSBuildEditorConfig.editorconfig
│   │           │       ├── ChatCompletion.assets.cache
│   │           │       ├── ChatCompletion.csproj.AssemblyReference.cache
│   │           │       ├── ref
│   │           │       └── refint
│   │           ├── project.assets.json
│   │           └── project.nuget.cache
│   ├── ml.workspace.yaml
│   ├── package-lock.json
│   ├── package.json
│   └── temp
├── deployment.log
├── directory_structure.txt
├── launch.json
├── parameters backup.json
├── parameters.json
├── search-index-schema.json
├── search-indexer-schema.json
├── server.js
└── settings.json

18 directories, 49 files
```


### Scripts

```
npm start / yarn start - Start the development server
npm run build / yarn build - Build the project for production
```

### HTML Structure

The index.html file includes the following screens:


<img width="1894" alt="Screenshot 2024-10-27 at 2 33 57 PM" src="https://github.com/user-attachments/assets/5df4d85e-6408-414d-9ab8-2dfbac96a9bd">

<img width="1892" alt="Screenshot 2024-10-27 at 2 36 14 PM" src="https://github.com/user-attachments/assets/106b3cc5-8a20-44a1-9ea3-264390a55739">
<img width="1620" alt="Screenshot 2024-10-27 at 2 37 05 PM" src="https://github.com/user-attachments/assets/63a8f5df-79f0-4f0f-8dd6-695872394000">

<img width="1889" alt="Screenshot 2024-10-27 at 2 35 21 PM" src="https://github.com/user-attachments/assets/ea438baf-13d8-4807-8024-3662dea4080c">


### Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### License

This project is licensed under the MIT License. See the LICENSE file for details.
