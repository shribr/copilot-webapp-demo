#**********************************************************************************************************************
# Script: Azure AI Demo Deployment.ps1
#
# Before executing this script, ensure that you have installed the Azure CLI and PowerShell Core.
# make sure you have an active Azure subscription and have logged in using the 'az login' command.
# To execute this script, run the following command:
# .\Azure AI Demo Deployment.ps1
# TEST
#**********************************************************************************************************************
<#
.SYNOPSIS
    This script automates the deployment of various Azure resources.

.DESCRIPTION˚¡
    This script reads parameters from a JSON file and uses them to create and configure the following list of Azure resources:
    # 1. storage accounts
    # 2. app service plans
    # 3. search services
    # 4. log analytics workspaces
    # 5. cognitive services accounts
    # 6. key vaults
    # 7. application insights components
    # 8. portal dashboards
    # 9. managed environments
    # 10. user assigned identities
    # 11. web apps
    # 12. function apps
    # 13. Azure OpenAI accounts
    # 14. Document Intelligence accounts

.PARAMETER parametersFile
    The path to the JSON file containing the parameters for the deployment. Default is "parameters.json".
    The list of variables in the parameters file includes:
    # 1. location
    # 2. resourceGroupName
    # 3. resourceSuffix
    # 4. storageAccountName
    # 5. appServicePlanName
    # 6. searchServiceName
    # 7. logAnalyticsWorkspaceName
    # 8. cognitiveServiceName
    # 9. keyVaultName
    # 10. appInsightsName
    # 11. portalDashboardName
    # 12. managedEnvironmentName
    # 13. userAssignedIdentityName
    # 14. webAppName
    # 15. functionAppName
    # 16. openAIName
    # 17. documentIntelligenceName
    # 18. virtualNetworkName
    # 19. subnetName
    # 20. networkSecurityGroupName
    # 21. publicIpAddressName
    # 22. networkInterfaceName
    # 23. virtualMachineName
    # 24. virtualMachineSize
    # 25. adminUsername
    # 26. adminPassword
    # 27. osDiskName
    # 28. osDiskSize
    # 29. dataDiskName
    # 30. dataDiskSize
    # 31. availabilitySetName
    # 32. loadBalancerName
    # 33. backendPoolName
    # 34. healthProbeName
    # 35. loadBalancingRuleName
    # 36. inboundNatRuleName
    # 37. applicationGatewayName
    # 38. gatewayIpConfigName
    # 39. frontendIpConfigName
    # 40. frontendPortName
    # 41. backendAddressPoolName
    # 42. httpSettingsName
    # 43. requestRoutingRuleName
    # 44. sslCertificateName
    # 45. autoscaleSettingName
    # 46. scaleRuleName
    # 47. actionGroupName

.EXAMPLE
    .\Azure\ AI\ Demo\ Deployment.ps1 -parametersFile "myParameters.json"
    This example runs the script using the parameters specified in "myParameters.json".
    .NOTES
        Author: Amis Schreiber
        Date: 2024-09-28
        Version: 1.0
        Additional information: Example script for deploying Azure resources.
        Prerequisites: Azure CLI, PowerShell Core, Azure subscription.
#>

# Set the default parameters file
param (
    [string]$parametersFile = "parameters.json",
    [string]$deploymentType = "Existing",
    [string]$resourceBaseName = "copilot-demo"
)

$global:parametersFile = "parameters.json"

# Mapping of global resource types
$global:ResourceTypes = @(
    "Microsoft.ApiManagement",
    "Microsoft.CognitiveServices/accounts",
    "Microsoft.ContainerRegistry",
    "Microsoft.ContainerRegistry/registries",
    "Microsoft.DataFactory/factories",
    "Microsoft.DocumentDB/databaseAccounts",
    "Microsoft.KeyVault/vaults",
    "Microsoft.Network/virtualNetworks",
    "Microsoft.Network/virtualNetworks/subnets",
    "Microsoft.Search/searchServices",
    "Microsoft.Sql/servers",
    "Microsoft.Storage/storageAccounts",
    "Microsoft.Web/hostingEnvironments",
    "Microsoft.Web/serverFarms",
    "Microsoft.Web/sites",
    "microsoft.alertsmanagement/alerts",
    "microsoft.insights/actiongroups"
)

# List of all resources pending creation
$global:ResourceList = @()

# Mapping of global AI Hub connected resources
$global:AIHubConnectedResources = @()

# List of all KeyVault secret keys
$global:KeyVaultSecrets = [PSCustomObject]@{
    StorageServiceApiKey = ""
    SearchServiceApiKey  = ""
    OpenAIServiceApiKey  = ""
}

# Function to check if user is logged in to Azure
function Check-Azure-Login {
    try {
        $account = az account show --output json

        if ($account) {
            Write-Host "User is already logged in to Azure"
            return $true
        }
        else {
            Write-Host "User is not logged in to Azure"
            return $false
        }
    }
    catch {
        Write-Host "User is not logged in to Azure"
        return $false
    }
}

# Function to convert string to proper case
function ConvertTo-ProperCase {
    param (
        [string]$inputString
    )

    # Split the input string into words
    $words = $inputString -split "\s+"

    # Convert each word to proper case
    $properCaseWords = $words | ForEach-Object {
        if ($_ -ne "") {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }
    }

    # Join the words back into a single string
    $properCaseString = $properCaseWords -join " "
    return $properCaseString
}

# Function to deploy an app service
function Deploy-AppService {
    param (
        [array]$appService,
        [string]$resourceGroupName,
        [string]$storageServiceName,
        [bool]$deployZipResources,
        [array]$existingResources
    )

    $appExists = @()

    $ErrorActionPreference = 'Stop'

    # Making sure we are in the correct folder depending on the app type
    #Set-DirectoryPath -targetDirectory $appService.Path

    $currentLocation = Reset-DeploymentPath

    $appServiceType = $appService.Type
    $appServiceName = $appService.Name
    $deployZipPackage = $appService.DeployZipPackage

    $appExists = az webapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

    if ($appExists) {
        if ($deployZipResources -eq $true -and $deployZipPackage -eq $true) {
            try {

                #$appRoot = Find-AppRoot -currentDirectory $currentLocation

                $appRoot = Join-Path -Path $currentLocation -ChildPath "app"
                $tempPath = Join-Path -Path $appRoot -ChildPath "temp"

                if (-not (Test-Path $tempPath)) {
                    New-Item -Path $tempPath -ItemType Directory
                }

                # Compress the function app code
                $zipFilePath = "$tempPath/$appServiceType-$appServiceName.zip"

                if (Test-Path $zipFilePath) {
                    Remove-Item $zipFilePath
                }

                $appPath = Join-Path -Path $currentLocation -ChildPath $appService.Path
                Set-Location $appPath

                # compress the app code
                zip -r $zipFilePath * .env

                if ($appService.Type -eq "Web") {
                    # Deploy the web app
                    #az webapp deployment source config-zip --name $appServiceName --resource-group $resourceGroupName --src $zipFilePath
                    az webapp deploy --src-path $zipFilePath --name $appServiceName --resource-group $resourceGroupName --type zip
                }
                else {
                    # Deploy the function app
                    az functionapp deployment source config-zip --name $appServiceName --resource-group $resourceGroupName --src $zipFilePath

                    $searchServiceKeys = az search admin-key show --resource-group $resourceGroupName --service-name $global:searchServiceName --query "primaryKey" --output tsv
                    $searchServiceApiKey = $searchServiceKeys

                    $envVariables = @(
                        @{ name = "AZURE_SEARCH_API_KEY"; value = $searchServiceApiKey },
                        @{ name = "AZURE_SEARCH_SERVICE_NAME"; value = $searchServiceName },
                        @{ name = "AZURE_SEARCH_INDEX"; value = $searchIndexerName }
                    )

                    foreach ($envVar in $envVariables) {
                        az functionapp config appsettings set --name $appServiceName --resource-group $resourceGroupName --settings "$($envVar.name)=$($envVar.value)"
                    }
                }

                Write-Host "$appServiceType app '$appServiceName' deployed successfully."
                Write-Log -message "$appServiceType app '$appServiceName' deployed successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to deploy $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to deploy $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
            }
        }
        else {
            Write-Host "Skipping deployment for $appServiceType app '$appServiceName'. If you would like to deploy and overwrite the existing app open the parameters.json file and change the 'deployZipResources' parameter to 'true' and rerun this script."
            Write-Log -message "Skipping deployment for $appServiceType app '$appServiceName'. If you would like to deploy and overwrite the existing app open the parameters.json file and change the 'deployZipResources' parameter to 'true' and rerun this script." -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "App '$appServiceName' does not exist. Please create the app before deploying."
        Write-Log -message "App '$appServiceName' does not exist. Please create the app before deploying." -logFilePath $global:LogFilePath
    }
}

# Function to deploy an Azure AI model
function Deploy-OpenAIModels {
    param (
        [string]$aiProjectName,
        [string]$aiServiceName,
        [array]$aiModels,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    foreach ($aiModel in $aiModels) {
        $aiModelDeploymentName = $aiModel.DeploymentName
        $aiModelType = $aiModel.Type
        $aiModelVersion = $aiModel.ModelVersion
        $aiModelFormat = $aiModel.Format
        $aiModelSkuName = $aiModel.Sku.Name
        $aiModelSkuCapacity = $aiModel.Sku.Capacity
   
        try {
            # Check if the deployment already exists
            $deploymentExists = az cognitiveservices account deployment list --resource-group $resourceGroupName --name $aiServiceName --query "[?name=='$aiModelDeploymentName']" --output tsv

            if ($deploymentExists) {
                Write-Host "Model deployment '$aiModelDeploymentName' for '$aiServiceName' already exists."
                Write-Log -message "Model deployment '$aiModelDeploymentName' for '$aiServiceName' already exists."
            }
            else {
                # Create the deployment if it does not exist
                $jsonOutput = az cognitiveservices account deployment create --resource-group $resourceGroupName --name $aiServiceName --deployment-name $aiModelDeploymentName --model-name $aiModelType --model-format $aiModelFormat --model-version $aiModelVersion --sku-name $aiModelSkuName --sku-capacity $aiModelSkuCapacity 2>&1

                # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

                if ($jsonOutput -match "error") {

                    $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                    $errorName = $errorInfo["Error"]
                    $errorCode = $errorInfo["Code"]
                    $errorDetails = $errorInfo["Message"]

                    $errorMessage = "Failed to deploy Model '$aiModelDeploymentName' for '$aiServiceName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
                else {
                    Write-Host "Mdel '$aiModelDeploymentName' for '$aiServiceName' deployed successfully."
                    Write-Log -message "Model '$aiModelDeploymentName' for '$aiServiceName' deployed successfully." -logFilePath $global:LogFilePath
                }


            }
        }
        catch {
            Write-Error "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            #Remove-MachineLearningWorkspace -resourceGroupName $resourceGroupName -aiProjectName $aiProjectName
        }
    }
}

# function to get the app root directory
function Find-AppRoot {
    param (
        [string]$currentDirectory
    )

    # Get the directory info
    $directoryInfo = Get-Item -Path $currentDirectory

    # Check if the current directory is "app"
    if ($directoryInfo.Name -eq "app") {
        return $directoryInfo.FullName
    }

    # If the parent directory is null, we have reached the root of the filesystem
    if ($null -eq $directoryInfo.Parent) {
        return $null
    }

    # Move one level up and call the function recursively
    return Find-AppRoot -currentDirectory $directoryInfo.Parent.FullName
}

# function to format error information from a message
function Format-ErrorInfo {
    param (
        [string]$message,
        [string]$objectType
    )

    # Split the message into lines
    $lines = $message -split "`n"

    # Initialize the hashtable with keys: Error, SKU, and Code
    $errorInfo = @{
        Error = $null
        SKU   = $null
        Code  = $null
    }

    # Check if there are at least three lines
    if ($lines.Length -ge 3) {
        $errorInfo.Code = $lines[0].Trim()
        $errorInfo.Error = $lines[1].Trim()
        $errorInfo.SKU = $lines[2].Trim()
    }
    else {
        Write-Host "Error: The message does not contain enough lines to extract Error, SKU, and Code."
    }

    # Output the error information
    Write-Host "Error Information:"
    $errorInfo | Format-List -Property *
}

# function to generate custom error information from a message
function Format-CustomErrorInfo {
    param([array]$jsonOutput
    )

    $properties = @{}

    # Process each line
    foreach ($item in $jsonOutput) {
        # Split the line at the first colon
        $parts = $item -split ": "

        # Check if the line contains a colon
        if ($parts.Length -eq 2) {
            $propertyName = ConvertTo-ProperCase $parts[0]
            $propertyValue = $parts[1].Trim()

            # Add the property to the hashtable
            $properties[$propertyName] = $propertyValue
        }
    }

    Write-Host "Error Information: $properties"

    return $properties
}

# Function to get a list of Azure tenants
function Get-Azure-Tenants() {
    $tenantId = ""
    $optionSelected = 0

    az config set extension.dynamic_install_allow_preview=true

    $tenants = az account tenant list | ConvertFrom-Json

    $optionValue = 1
    foreach ($tenant in $tenants) {
        $tenant | Add-Member -MemberType NoteProperty -Name "option" -Value $optionValue
        $optionValue++
    }
    
    Write-Host "Available Azure tenants:"
    Write-Host $tenants

    if ($tenants.Count -eq 1) {
        $tenantId = $tenants[0].tenantId
        az account set --tenant $tenantId
    }
    else {
        $optionSelected = Read-Host "Select the Azure tenant ID:"

        $tenantId = $tenants[$optionSelected - 1].tenantId
    }
    $setAsDefaultTenant = Read-Host "Set the selected tenant as the default tenant? (Y/N)"

    if ($setAsDefaultTenant -eq "Y") {
        az account set --tenant $tenantId
    }

    # Prompt user to select a subscription
    $subscriptions = az account list --query "[].{Name:name, Id:id}" | ConvertFrom-Json
    $subscriptionOptions = @()
    $optionValue = 1
    foreach ($subscription in $subscriptions) {
        $subscriptionOptions += "$optionValue. $($subscription.Name) ($($subscription.Id))"
        $subscription | Add-Member -MemberType NoteProperty -Name "option" -Value $optionValue
        $optionValue++
    }

    Write-Host "Available subscriptions:"
    $subscriptionOptions | ForEach-Object { Write-Host $_ }

    $subscriptionSelected = Read-Host "Select the Azure subscription ID (enter the number)..."
    $selectedSubscription = $subscriptions[$subscriptionSelected - 1].Id

    az account set --subscription $selectedSubscription

    return $tenantId
}

# Function to get Cognitive Services API key
function Get-CognitiveServicesApiKey {
    param (
        [string]$resourceGroupName,
        [string]$cognitiveServiceName
    )

    try {
        # Run the Azure CLI command and capture the output
        $apiKeysJson = az cognitiveservices account keys list --resource-group $resourceGroupName --name $cognitiveServiceName

        # Parse the JSON output into a PowerShell object
        $apiKeys = $apiKeysJson | ConvertFrom-Json

        # Access the keys
        $key1 = $apiKeys.key1
        $key2 = $apiKeys.key2

        # Output the keys to verify
        Write-Host "Key 1: $key1"
        Write-Host "Key 2: $key2"
        return $key1
    }
    catch {
        Write-Error "Failed to retrieve API key for Cognitive Services resource: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        return $null
    }
}

# Function to test if datasource exists
function Get-DataSources {
    param(
        [string]$dataSourceName,
        [string]$resourceGroupName,
        [string]$searchServiceName
    )

    # Get the admin key for the search service
    #
    $apiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv

    $uri = "https://$searchServiceName.search.windows.net/datasources?api-version=2024-07-01"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "api-key" = "$apiKey" }
        $datasources = $response.value | Select-Object -ExpandProperty name
        return $datasources
    }
    catch {
        Write-Error "Failed to query search datasources: $_"
        return $false
    }

}

# Function to check if a Key Vault secret exists
function Get-KeyVaultSecret {
    param(
        [string]$keyVaultName,
        [string]$secretName
    )

    try {
        $secret = az keyvault secret show --vault-name $keyVaultName --name $secretName --query "value" --output tsv
        Write-Host "Secret: '$secretName' already exista."
        Write-Log -message "Secret: '$SecretName' already exists." -logFilePath $global:LogFilePath
        return $secret
    }
    catch {
        Write-Host "Secret: '$secretName' does not exist."
        Write-Log -message "Secret: '$SecretName' does not exist." -logFilePath $global:LogFilePath
        return $null
    }
}

# Function to get the latest API version for a resource type
function Get-LatestApiVersion {
    param (
        [string]$resourceProviderNamespace,
        [string]$resourceType
    )

    $apiVersions = az provider show --namespace $resourceProviderNamespace --query "resourceTypes[?resourceType=='$resourceType'].apiVersions[]" --output json | ConvertFrom-Json
    $latestApiVersion = ($apiVersions | Sort-Object -Descending)[0]
    return $latestApiVersion
}

# Function to get the latest .NET runtime version
function Get-LatestDotNetRuntime {
    param(
        [string]$resourceType,
        [string]$os,
        [string]$version
    )

    if ($resourceType -eq "functionapp") {
        $functionRuntimes = az functionapp list-runtimes --output json | ConvertFrom-Json

        if ($os -eq "linux") {
            #$runtimes = $functionRuntimes.linux | Where-Object { $_.runtime -eq 'dotnet' -and $_.version -eq $version } | Select-Object -ExpandProperty version
            $runtimes = $functionRuntimes.linux | Where-Object { $_.runtime -eq 'dotnet' } | Select-Object -ExpandProperty version
        }
        else {
            $runtimes = $functionRuntimes.windows | Where-Object { $_.runtime -eq 'dotnet' } | Select-Object -ExpandProperty version
        }
    }
    elseif ($resourceType -eq "webapp") {
        $webpAppRuntimes = az webapp list-runtimes --output json | ConvertFrom-Json

        if ($os -eq "linux") {
            $runtimes = $webpAppRuntimes.linux | Where-Object { $_.runtime -eq 'dotnet' } | Select-Object -ExpandProperty version
        }
        else {
            $runtimes = $webpAppRuntimes.windows | Where-Object { $_.runtime -eq 'dotnet' } | Select-Object -ExpandProperty version
        }
    }
    else {
        throw "Unsupported resource type: $resourceType"
    }

    $latestRuntime = ($runtimes | Sort-Object -Descending)[0]

    return $latestRuntime
}

# Function to detect the operating system
function Get-OperatingSystem {
    $os = $PSVersionTable.OS
    if ($os -match "Windows") {
        return "Windows"
    }
    elseif ($os -match "Linux") {
        return "Linux"
    }
    elseif ($os -match "Darwin") {
        return "macOS"
    }
    else {
        return "Unknown"
    }
}

# Function to alphabetize the parameters object
function Get-Parameters-Sorted {
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Parameters
    )

    # Convert properties to an array and sort them by name
    $sortedProperties = $Parameters.PSObject.Properties | Sort-Object Name

    # Create a new sorted parameters object
    $sortedParametersObject = New-Object PSObject
    foreach ($property in $sortedProperties) {
        $sortedParametersObject | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
    }

    return $sortedParametersObject
}

# Helper function to get a random integer
function Get-RandomInt {
    param (
        [int]$max
    )

    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 4
    $random.GetBytes($bytes)
    [math]::Abs([BitConverter]::ToInt32($bytes, 0)) % $max

    return [math]::Abs([BitConverter]::ToInt32($bytes, 0)) % $max
}

# Function to check if a search index exists
function Get-SearchIndexes {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$subscriptionId
    )

    $subscriptionId = $global:subscriptionId
    $resourceGroupName = $global:resourceGroupName

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv

    $uri = "https://$searchServiceName.search.windows.net/indexes?api-version=2024-07-01"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "api-key" = "$accessToken" }
        $indexes = $response.value | Select-Object -ExpandProperty name
        return $indexes
    }
    catch {
        Write-Error "Failed to query search indexes: $_"
        return $false
    }
}

# Function to check if a search indexer exists
function Get-SearchIndexers {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$subscriptionId
    )

    $subscriptionId = $global:subscriptionId
    $resourceGroupName = $global:resourceGroupName

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv

    $uri = "https://$searchServiceName.search.windows.net/indexers?api-version=2024-07-01"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "api-key" = "$accessToken" }
        $indexers = $response.value | Select-Object -ExpandProperty name
        return $indexers
    }
    catch {
        Write-Error "Failed to query search indexes: $_"
        return $false
    }
}

# Function to check if a search skillset exists
function Get-SearchSkillSets {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$subscriptionId
    )

    $subscriptionId = $global:subscriptionId
    $resourceGroupName = $global:resourceGroupName

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv

    $uri = "https://$searchServiceName.search.windows.net/skillsets?api-version=2024-07-01"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "api-key" = "$accessToken" }
        $skillsets = $response.value | Select-Object -ExpandProperty name
        return $skillsets
    }
    catch {
        Write-Error "Failed to query search skillsets: $_"
        return $false
    }
}

# Function to find a unique suffix and create resources
function Get-UniqueSuffix {
    params
    (
        [string]$resourceGroupName
    )

    $appResourceExists = $true

    do {
        $global:storageService.Name = "$($parameters.storageService.tName)$resourceGuid$resourceSuffix"
        $global:appServicePlan.Name = "$($parameters.appServicePlan.Name)-$resourceGuid-$resourceSuffix"
        $global:searchService.Name = "$($parameters.searchServic.eName)-$resourceGuid-$resourceSuffix"
        $global:logAnalyticsWorkspace.Name = "$($parameters.logAnalyticsWorkspace.Name)-$resourceGuid-$resourceSuffix"
        $global:cognitiveService.Name = "$($parameters.cognitiveService.Name)-$resourceGuid-$resourceSuffix"
        $global:containerRegistry.Name = "$($parameters.containerRegistry.Name)-$resourceGuid-$resourceSuffix"
        $global:keyVault.Name = "$($parameters.keyVault.Name)-$resourceGuid-$resourceSuffix"
        $global:appInsights.Name = "$($parameters.appInsights.Name)-$resourceGuid-$resourceSuffix"
        $global:userAssignedIdentity.Name = "$($parameters.userAssignedIdentity.Name)-$resourceGuid-$resourceSuffix"
        $global:documentIntelligenceService.Name = "$($parameters.documentIntelligenceService.Name)-$resourceGuid-$resourceSuffix"
        $global:aiHub.Name = "$($aiHub.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:aiService.Name = "$($aiService.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:computerVisionService.Name = "$($computerVisioService.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:openAIService.Name = "$($openAIService.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:virtualNetwork.Name = "$($virtualNetwork.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:subnet.Name = "$($subnet.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:apiManagementService.Name = "$($apiManagementService.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:aiProject.Name = "$($aiProject.Name)-$($resourceGuid)-$($resourceSuffix)"
        $global:virtualNetwork.Name = "$($virtualNetwork.Name)-$($resourceGuid)-$($resourceSuffix)"

        foreach ($appService in $global:appServices) {
            $appService.Name = "$($appService.Name)-$($resourceGuid)-$($resourceSuffix)"
        }

        foreach ($aiModel in $global:aiModels) {
            $aiModel.DeploymentName = "$($aiModel.DeploymentName)-$($resourceGuid)-$($resourceSuffix)"
        }

        $resourceExists = Test-ResourceExists -resourceName $storageService.Name -resourceType "Microsoft.Storage/storageAccounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $appServicePlan.Name -resourceType "Microsoft.Web/serverFarms" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $searchService.Name -resourceType "Microsoft.Search/searchServices" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $logAnalyticsWorkspace.Name -resourceType "Microsoft.OperationalInsights/workspaces" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $cognitiveService.Name -resourceType "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $keyVault.Name -resourceType "Microsoft.KeyVault/vaults" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $appInsights.Name -resourceType "Microsoft.Insights/components" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $apiManagementService.Name -resourceType "Microsoft.Portal/ApiManagement/service" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $openAIService.Name -resourceType "Microsoft.App/CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $aiService.Name -resourceType "Microsoft.App/CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $computerVisionService.Name -resourceType "Microsoft.App/CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $userAssignedIdentity.Name -resourceType "Microsoft.ManagedIdentity/userAssignedIdentities" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $openAIService.Name -resourceType "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $virtualNetwork.Name -resourceType "Microsoft.Network/virtualNetworks" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $documentIntelligenceService.Name -resourceType "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $aiHub.Name -resourceType "Microsoft.App/CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $aiProject.Name -resourceType "Microsoft.App/MachineLearningServices/workspaces" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists -resourceName $containerRegistry.Name -resourceType "Microsoft.App/MachineLearningServices/registries" -resourceGroupName $resourceGroupName

        foreach ($appService in $global:appServices) {
            $appResourceExists = Test-ResourceExists resourceName $appService.Name -resourceType "Microsoft.Web/sites" -resourceGroupName $resourceGroupName -or $resourceExists
            if ($appResourceExists) {
                $resourceExists = $true
                break
            }
        }

        foreach ($aiModel in $global:aiModels) {
            $aiModelResourceExists = Test-ResourceExists -resourceName $aiModel.DeploymentName -resourceType "Microsoft.CognitiveServices/accounts/deployments" -resourceGroupName $resourceGroupName -or $resourceExists
            if ($aiModelResourceExists) {
                $resourceExists = $true
                break
            }
        }

        if ($resourceExists) {
            $global:resourceSuffix++
        }
    } while ($resourceExists)

}

# Ensure the service name is valid
function Get-ValidServiceName {
    param (
        [string]$serviceName
    )
    # Convert to lowercase
    $serviceName = $serviceName.ToLower()

    # Remove invalid characters
    $serviceName = $serviceName -replace '[^a-z0-9-]', ''

    # Remove leading and trailing dashes
    $serviceName = $serviceName.Trim('-')

    # Remove consecutive dashes
    $serviceName = $serviceName -replace '--+', '-'

    return $serviceName
}

# Function to increment a formatted number
function Increment-FormattedNumber {
    param (
        [string]$formattedNumber,
        [int]$width = 3
    )
    # Convert the formatted number to an integer
    $number = [int]$formattedNumber

    # Increment the number
    $number++

    # Convert the number back to the formatted string with leading zeros
    return $number.ToString("D$width")
}

# Function to install Azure CLI
function Install-AzureCLI {
    Write-Host "Verifying Azure CLI installation..."

    # Check if the Azure CLI is already installed
    $isInstalled = az --version --output none 2>&1

    if ($isInstalled) {
        Write-Host "Azure CLI is already installed."
        return
    }
    else {
        try {
            $ProgressPreference = 'SilentlyContinue'
            $os = Get-OperatingSystem
            if ($os -eq "Windows") {
                Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi
                Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
                Remove-Item .\AzureCLI.msi
            }
            elseif ($os -eq "macOS") {
                brew update; brew install azure-cli
            }
            elseif ($os -eq "Linux") {
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            }
            else {
                Write-Error "Unsupported operating system: $os"
                return
            }

            Write-Host "Azure CLI installed successfully."
        }
        catch {
            Write-Error "Failed to install Azure CLI: $_"
        }
    }
}

# Function to install Visual Studio Code extensions
function Install-Extensions {
    # Define the path to the extensions.json file
    $filePath = "extensions.json"

    Write-Host "Installing Visual Studio Code extensions..."

    # Load parameters from the JSON file
    $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Read all lines from the file
    $extensions = Get-Content -Path $filePath | ConvertFrom-Json

    if ($parametersObject.installRequiredExtensionsOnly -eq $true) {
        $extensions = $extensions | Where-Object { $_.required -eq $true }
    }

    # Loop through each extension and install it using the `code` command
    foreach ($extension in $extensions) {
        
        $extensionName = $extension.name
        # check if the extension is already installed
        $isInstalled = code --list-extensions | Where-Object { $_ -eq $extensionName }

        if ($isInstalled) {
            Write-Host "Extension '$extensionName' is already installed."
            continue
        }
        else {

            try {
                code --install-extension $extensionName
                Write-Host "Installed extension '$extensionName' successfully."
            }
            catch {
                Write-Error "Failed to install extension '$extensionName': $_"
            }
        }
    }

    # Check for Azure Machine Learning Extension
    $azMLExists = az extension list --query "[?name=='azure-cli-ml']" | ConvertFrom-Json

    if ($azMLExists) {
        Write-Host "Uninstalling legacy 'azure=cli-ml' Azure Machine Learning extension."

        az extension remove -n azure-cli-ml
    }
    else {
        try {
            az extension add --name ml
            Write-Host "Azure Machine Learning extension installed successfully."
        }
        catch {
            Write-Error "Failed to install Azure Machine Learning extension: $_"
        }
    }
}

# Initialize the parameters
function Initialize-Parameters {
    param (
        [string]$parametersFile = "parameters.json"
    )

    # Navigate to the project directory
    Set-DirectoryPath -targetDirectory $global:deploymentPath

    # Load parameters from the JSON file
    $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    $global:deploymentType = $parametersObject.deploymentType

    $global:keyVaultSecrets = $parametersObject.KeyVaultSecrets
    $global:resourceTypes = $parametersObject.resourceTypes

    $global:newResourceBaseName = $parametersObject.newResourceBaseName
    $global:previousFullResourceBaseName = $parametersObject.previousFullResourceBaseName

    if ($global:deploymentType -eq "New") {
        Update-ResourceBaseName -newResourceBaseName $global:newResourceBaseName
        $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json
    }
    else {
        # Use fullResourceBaseName from the new schema
        $global:newFullResourceBaseName = $parametersObject.fullResourceBaseName
    }

    # Initialize globals by mapping to nested objects when applicable
    $global:aiHub = $parametersObject.aiHub            
    $global:aiModels = $parametersObject.aiModels
    $global:aiProject = $parametersObject.aiProject          
    $global:aiService = $parametersObject.aiService
    $global:apiManagementService = $parametersObject.apiManagementService
    $global:appInsightsService = $parametersObject.appInsightsService   
    $global:appServiceEnvironmentName = $parametersObject.appServiceEnvironmentName
    $global:appServicePlan = $parametersObject.AppServicePlan
    $global:cognitiveService = $parametersObject.cognitiveService       
    $global:computerVisionService = $parametersObject.computerVisionService  
    $global:containerRegistry = $parametersObject.containerRegistry      
    $global:documentIntelligenceService = $parametersObject.documentIntelligenceService  
    $global:keyVault = $parametersObject.keyVault               
    $global:logAnalyticsWorkspaceName = $parametersObject.logAnalyticsWorkspaceName
    $global:openAIService = $parametersObject.openAIService          
    $global:resourceGroup.Name = $parametersObject.resourceGroupName
    $global:searchService = $parametersObject.searchService          
    $global:storageService = $parametersObject.storageService
    $global:userAssignedIdentity = $parametersObject.userAssignedIdentity         
    $global:virtualNetwork = $parametersObject.virtualNetwork         

    if ($global:keyVault.PermissionModel -eq "RoleBased") {
        $global:useRBAC = $true
    }
    else {
        $global:useRBAC = $false
    }

    # Make sure the previousFullResourceBaseName is different than the current one.
    if ($parametersObject.previousFullResourceBaseName -eq $parametersObject.newFullResourceBaseName -and $parametersObject.redeployResources -eq $false) {
        Write-Host "The previousFullResourceBaseName parameter is the same as the newFullResourceBaseName parameter. Please change the previousFullResourceBaseName parameter to a different value."
        exit
    }

    # Retrieve subscription, tenant, object and user details
    $global:subscriptionId = az account show --query "id" --output tsv
    $global:tenantId = az account show --query "tenantId" --output tsv
    $global:objectId = az ad signed-in-user show --query "objectId" --output tsv
    $global:userPrincipalName = az ad signed-in-user show --query userPrincipalName --output tsv
    $global:resourceGuid = Split-Guid

    if ($parametersObject.PSObject.Properties.Name.Contains("objectId")) {
        $global:objectId = $parametersObject.objectId
    }
    else {
        $global:objectId = az ad signed-in-user show --query "objectId" --output tsv
        $parametersObject | Add-Member -MemberType NoteProperty -Name "objectId" -Value $global:objectId
    }

    # Add new authentication and resource properties to parameters object
    #$parametersObject | Add-Member -MemberType NoteProperty -Name "subscriptionId" -Value $global:subscriptionId
    $parametersObject | Add-Member -MemberType NoteProperty -Name "tenantId" -Value $global:tenantId
    $parametersObject | Add-Member -MemberType NoteProperty -Name "userPrincipalName" -Value $global:userPrincipalName
    $parametersObject | Add-Member -MemberType NoteProperty -Name "resourceGuid" -Value $global:resourceGuid

    # Build the list of resources using the new schema
    $resources = @(
        @{ Name = $global:aiService.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $global:apiManagementService.Name; Type = "API Management"; Status = "Pending" }
        @{ Name = $global:appInsightsService.Name; Type = "Application Insights"; Status = "Pending" }
        @{ Name = $global:appServiceEnvironmentName; Type = "App Service Environment"; Status = "Pending" }
        @{ Name = $global:appServicePlan.Name; Type = "App Service Plan"; Status = "Pending" }
        @{ Name = $global:cognitiveService.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $global:computerVisionService.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $global:containerRegistry.Name; Type = "Container Registry"; Status = "Pending" }
        @{ Name = $global:documentIntelligenceService.Name; Type = "Document Intelligence"; Status = "Pending" }
        @{ Name = $global:aiHub.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $global:userAssignedIdentityName; Type = "User Assigned Identity"; Status = "Pending" }
        @{ Name = $global:keyVault.Name; Type = "Key Vault"; Status = "Pending" }
        @{ Name = $global:logAnalyticsWorkspaceName; Type = "Log Analytics Workspace"; Status = "Pending" }
        @{ Name = $global:openAIService.Name; Type = "OpenAI"; Status = "Pending" }
        @{ Name = $global:aiProject.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $resourceGroup.Name; Type = "Resource Group"; Status = "Pending" }
        @{ Name = $global:searchService.Name; Type = "Search Service"; Status = "Pending" }
        @{ Name = $global:storageService.Name; Type = "Storage Account"; Status = "Pending" }
        @{ Name = $global:userAssignedIdentity.Name; Type = "User Assigned Identity"; Status = "Pending" }
        @{ Name = $global:virtualNetwork.Name; Type = "Virtual Network"; Status = "Pending" }
    )

    $jsonOutput = $resources | ConvertTo-Json
    $resourceTable = $jsonOutput | ConvertFrom-Json

    foreach ($resource in $resources) {
        $global:ResourceList += [PSCustomObject]@{ Name = $resource.Name; Type = $resource.Type; Status = $resource.Status }
    }
    
    Write-Host "Parameters initialized.`n"
    $resourceTable | Format-Table -AutoSize

    return @{
        aiHub                        = $global:aiHub
        aiModels                     = $global:aiModels
        aiProject                    = $global:aiProject
        aiService                    = $global:aiService
        apiManagementService         = $global:apiManagementService
        appInsightsService           = $global:appInsightsService
        appRegistrationClientId      = $parametersObject.appRegistrationClientId
        appRegRequiredResourceAccess = $parametersObject.appRegRequiredResourceAccess
        appDeploymentOnly            = $parametersObject.appDeploymentOnly
        appendUniqueSuffix           = $parametersObject.appendUniqueSuffix
        appServiceEnvironmentName    = $global:appServiceEnvironmentName
        appServicePlan               = $global:appServicePlan
        azureManagement              = $parametersObject.azureManagement
        cognitiveService             = $global:cognitiveService
        computerVisionService        = $global:computerVisionService
        configFilePath               = $parametersObject.configFilePath
        containerRegistry            = $global:containerRegistry
        createResourceGroup          = $parametersObject.createResourceGroup
        currentFullResourceBaseName  = $parametersObject.currentFullResourceBaseName
        deleteResourceGroup          = $parametersObject.deleteResourceGroup
        deployApiManagementService   = $parametersObject.deployApiManagementService
        deploymentType               = $global:deploymentType
        deployZipResources           = $parametersObject.deployZipResources
        documentIntelligenceService  = $global:documentIntelligenceService
        exposeApiScopes              = $parametersObject.exposeApiScopes
        keyVault                     = $global:keyVault
        keyVaultSecrets              = $global:KeyVaultSecrets
        location                     = $parametersObject.location
        logAnalyticsWorkspaceName    = $global:logAnalyticsWorkspaceName
        machineLearningService       = $parametersObject.machineLearningService
        managedIdentityName          = $parametersObject.managedIdentityName
        newResourceBaseName          = $global:newResourceBaseName
        newFullResourceBaseName      = $global:newFullResourceBaseName
        objectId                     = $global:objectId
        openAIService                = $global:openAIService
        previousFullResourceBaseName = $global:previousFullResourceBaseName
        previousResourceBaseName     = $parametersObject.previousResourceBaseName
        redeployResources            = $parametersObject.redeployResources
        redisCacheName               = $parametersObject.redisCacheName
        resourceBaseName             = $parametersObject.resourceBaseName
        resourceGroupName            = $resourceGroup.Name
        resourceGuid                 = $global:resourceGuid
        resourceSuffix               = $parametersObject.resourceSuffix
        resourceSuffixCounter        = $parametersObject.resourceSuffixCounter
        resourceTypes                = $global:resourceTypes
        restoreSoftDeletedResource   = $parametersObject.restoreSoftDeletedResources
        result                       = $result
        searchDataSources            = $parametersObject.searchDataSources
        searchIndexFieldNames        = $parametersObject.searchIndexFieldNames
        searchIndexes                = $parametersObject.searchIndexes
        searchIndexers               = $parametersObject.searchIndexers
        searchPublicInternetResults  = $parametersObject.searchPublicInternetResults
        searchService                = $global:searchService
        searchSkillSets              = $parametersObject.searchSkillSets
        siteLogo                     = $parametersObject.siteLogo
        storageService               = $global:storageService
        subNet                       = $parametersObject.subNet
        subscriptionId               = $global:subscriptionId
        tenantId                     = $global:tenantId
        userAssignedIdentity         = $global:userAssignedIdentity
        useRBAC                      = $global:useRBAC
        userPrincipalName            = $global:userPrincipalName
        virtualNetwork               = $global:virtualNetwork
    }
}

# Function to login to Azure account
function Initialize-Azure-Login {
    param(
        [string]$tenantId
    )

    $isLoggedIn = Check-Azure-Login

    if (!$isLoggedIn) {
        Write-Host "Logging in to Azure..."

        $ErrorActionPreference = 'Stop'

        try {
            az login --use-device-code
        }
        catch {
            Write-Error "Failed to login to Azure: $_"
        }
    }
}

# Function to invoke an Azure REST API method
function Invoke-AzureRestMethod {
    param (
        [string]$method,
        [string]$url,
        [string]$jsonBody = $null
    )

    # Get the access token
    $token = az account get-access-token --query accessToken --output tsv

    $body = $jsonBody | ConvertFrom-Json

    $token = az account get-access-token --query accessToken --output tsv
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Host "Error: $_"
        throw $_
    }
}

# Function to create a new AI Hub
function New-AIHub {
    param (
        [string]$aiHubName,
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    Set-DirectoryPath -targetDirectory $global:deploymentPath

    # Create AI Hub
    if ($existingResources -notcontains $aiHubName) {
        try {
            $ErrorActionPreference = 'Stop'
            $storageServiceId = az storage account show --resource-group $resourceGroupName --name $storageServiceName --query 'id' --output tsv
            $keyVaultId = az keyvault show --resource-group $resourceGroupName --name $keyVaultName --query 'id' --output tsv

            az ml workspace create --kind hub --resource-group $resourceGroupName --name $aiHubName --storage-account $storageServiceId --key-vault $keyVaultId

            $global:resourceCounter += 1
            Write-Host "AI Hub: '$aiHubName' created successfully. ($global:resourceCounter)"
            Write-Log -message "AI Hub: '$aiHubName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                try {
                    Restore-SoftDeletedResource -resourceGroupName $resourceGroupName -resourceName $aiHubName -location $location -resourceType "AIHub"
                }
                catch {
                    Write-Error "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
                }
            }
            else {
                Write-Error "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
            }
        }
    }
    else {
        Write-Host "AI Hub '$aiHubName' already exists."
        Write-Log -message "AI Hub '$aiHubName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI Hub connection
function New-AIHubConnection {
    param (
        [string]$aiHubName,
        [string]$aiProjectName,
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$serviceName,
        [string]$serviceProperties,
        [array]$existingResources
    )

    #https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-blob?view=azureml-api-2

    $existingConnections = az ml connection list --workspace-name $aiProjectName --resource-group $resourceGroupName --query "[?name=='$serviceName'].name" --output tsv

    if ($existingConnections -notcontains $serviceName) {
        try {
            $ErrorActionPreference = 'Stop'

            $aiConnectionFile = Update-AIConnectionFile -resourceGroupName $resourceGroupName -serviceName $serviceName -serviceProperties $serviceProperties -resourceType $resourceType

            az ml connection create --file $aiConnectionFile --resource-group $resourceGroupName --workspace-name $aiProjectName

            Write-Host "Azure $resourceType '$serviceName' connection for '$aiHubName' created successfully."
            Write-Log -message  "Azure $resourceType '$serviceName' connection for '$aiHubName' created successfully." -logFilePath $global:LogFilePath
        }
        catch {

            Write-Error "Failed to create Azure $resourceType '$serviceName' connection for '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Azure $resourceType '$serviceName' connection for '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "Azure $resourceType '$serviceName' connection for '$aiHubName' already exists."
        Write-Log -message "Azure $resourceType '$serviceName' connection for '$aiHubName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI project
function New-AIProject {
    param (
        [string]$resourceGroupName,
        [string]$subscriptionId,
        [string]$aiHubName,
        [string]$aiProjectName,
        [string]$appInsightsName,
        [string]$userAssignedIdentityName,
        [string]$location,
        [string]$keyVaultName
    )

    $ErrorActionPreference = 'Stop'

    try {

        $ErrorActionPreference = 'Stop'

        #$storageServiceResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName"
        #$containerRegistryResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName"
        #$keyVaultResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
        $appInsightsResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName"
        $userAssignedIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
        $aiHubResoureceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName"

        <#
 # {        $aiProjectFile = Update-AIProjectFile `
            -aiProjectName $aiProjectName `
            -resourceGroupName $resourceGroupName `
            -appInsightsName $appInsightsResourceId `
            -location $location `
            -subscriptionId $subscriptionId `
            -storageAccountName $storageServiceResourceId `
            -containerRegistryName $containerRegistryResourceId `
            -keyVaultName $keyVaultResourceId `
            -userAssignedIdentityName $userAssignedIdentityResourceId:Enter a comment or description}
#>

        #az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName 2>&1
        #$jsonOutput = az ml workspace create --file $aiProjectFile --resource-group $resourceGroupName --name $aiProjectName --location $location --storage-account $storageServiceResourceId --key-vault $keyVaultResourceId --container-registry $containerRegistryResourceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId 2>&1

        #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

        #https://azuremlschemas.azureedge.net/latest/workspace.schema.json

        #$jsonOutput = az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName 2>&1
        #$jsonOutput = az ml workspace create --file $aiProjectFile -g $resourceGroupName --primary-user-assigned-identity $userAssignedIdentityResourceId --kind project --hub-id $aiHubResoureceId

        az ml workspace create --kind project --resource-group $resourceGroupName --name $aiProjectName --hub-id $aiHubResoureceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId --location $location
        #az ml workspace create --kind project --resource-group $resourceGroupName --name $aiProjectName --hub-id $$aiHubResoureceId --storage-account $storageServiceResourceId --key-vault $keyVaultResourceId --container-registry $containerRegistryResourceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId --location $location

        $global:resourceCounter += 1
        Write-Host "AI Project: '$aiProjectName' created successfully. [$global:resourceCounter]"
        Write-Log -message "AI Project: '$aiProjectName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
    }
    catch {
        Write-Error "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI Service
function New-AIService {
    param (
        [string]$aiServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    # Create AI Service
    if ($existingResources -notcontains $aiServiceName) {
        try {
            $ErrorActionPreference = 'Stop'

            #$aiServicesUrl = "$aiServiceName.openai.azure.com"

            #az resource show --resource-group "$resourceGroupName" --name "$aiServiceName" --resource-type accounts --namespace Microsoft.CognitiveServices

            $jsonOutput = az cognitiveservices account create --name $aiServiceName --resource-group $resourceGroupName --location $location --kind AIServices --sku S0 --output none 2>&1

            $global:aiServiceProperties.ApiKey = az cognitiveservices account keys list --name $aiServiceName --resource-group $resourceGroupName --query key1 --output tsv

            $global:KeyVaultSecrets.OpenAIServiceApiKey = $global:aiServiceProperties.ApiKey

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create AI Services account '$aiServiceName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                    try {
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Restore-SoftDeletedResource -resourceName $aiServiceName -resourceType "AIServices" -location $location -resourceGroupName $resourceGroupName
                    }
                    catch {
                        Write-Error "Failed to restore AI Services account '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to restore AI Services account '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    }
                }
                else {
                    Write-Error "Failed to create AI Service account '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create AI Service account '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                $global:resourceCounter += 1
                Write-Host "AI Service account '$aiServiceName' created successfully. [$global:resourceCounter]"
                Write-Log -message "AI Service account '$aiServiceName' created successfully. [$global:resourceCounter]"
            }

            #Write-Host "AI Service: '$aiServiceName' created successfully."
            #Write-Log -message "AI Service: '$aiServiceName' created successfully."
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                try {
                    Restore-SoftDeletedResource -resourceGroupName $resourceGroupName -resourceName $aiServiceName -location $location -resourceType "AIService"
                }
                catch {
                    Write-Error "Failed to restore soft-deleted AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore soft-deleted AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
                }
            }
            else {
                Write-Error "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
            }
        }
    }
    else {

        $global:aiServiceProperties.ApiKey = az cognitiveservices account keys list --name $aiServiceName --resource-group $resourceGroupName --query key1 --output tsv

        $global:KeyVaultSecrets.OpenAIServiceApiKey = $global:aiServiceProperties.ApiKey

        Write-Host "AI Service '$aiServiceName' already exists."
        Write-Log -message "AI Service '$aiServiceName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI Service connection
function New-ApiManagementApi {
    param (
        [string]$resourceGroupName,
        [string]$apiManagementServiceName
    )

    # Check if the API already exists
    $apiExists = az apim api show --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy
    if (-not $apiExists) {
        try {
            # Create the API
            az apim api create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --display-name "KeyVault Proxy" --path keyvault --service-url "https://$global:KeyVaultName.vault.azure.net/" --protocols https
 
        }
        catch {
            Write-Error "Failed to create API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath               
        }

        try {
            # Add operations
            az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --display-name "Get OpenAI Service Api Key" --method GET --url-template "/secrets/OpenAIServiceApiKey"
            az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --display-name "Get Search Service Api Key" --method GET --url-template "/secrets/SearchServiceApiKey"
    
        }
        catch {
            Write-Error "Failed to create operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
                
        try {
            # Add CORS policy to operations [THIS DOES NOT WORK]
            #az apim api operation policy set --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
            #az apim api operation policy set --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
    
        }
        catch {
            Write-Error "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }

        Write-Host "API 'KeyVaultProxy' and its operations created successfully."
        Write-Log -message "API 'KeyVaultProxy' and its operations created successfully." -logFilePath $global:LogFilePath
    }
    else {
        Write-Host "API 'KeyVaultProxy' already exists."
        Write-Log -message "API 'KeyVaultProxy' already exists." -logFilePath $global:LogFilePath

        try {
            # Add operations
            az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --display-name "Get OpenAI Service Api Key" --method GET --url-template "/secrets/OpenAIServiceApiKey"
            az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --display-name "Get Search Service Api Key" --method GET --url-template "/secrets/SearchServiceApiKey"
    
        }
        catch {
            Write-Error "Failed to create operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
                
        try {
            # Add CORS policy to operations [THIS DOES NOT WORK]
            #az apim api operation policy set --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
            #az apim api operation policy set --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
    
        }
        catch {
            Write-Error "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
}

# Function to create and deploy Api Management service
function New-ApiManagementService {
    param (
        [string]$resourceGroupName,
        [psobject]$apiManagementService,
        [array]$existingResources
    )

    #https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/rest-api/read.png

    $apiManagementServiceName = $apiManagementService.Name

    if ($global:DeployApiManagementService -eq $false) {
        return
    }

    if ($existingResources -notcontains $apiManagementServiceName) {
        try {
            $ErrorActionPreference = 'Stop'
            $jsonOutput = az apim create -n $apiManagementServiceName --publisher-name $apiManagementService.PublisherName --publisher-email $apiManagementService.PublisherEmail --resource-group $resourceGroupName --no-wait --output none 2>&1

            Write-Host $jsonOutput

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create API Management Service '$apiManagementServiceName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if (($errorCode -match "FlagMustBeSetForRestore" -or $errorCode -match "ServiceAlreadyExistsInSoftDeletedState" ) -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $apiManagementServiceName -resourceType "ApiManagementService" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error "Failed to create API Management Service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create API Management Service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {

                $global:resourceCounter += 1
                Write-Host "API Management service '$apiManagementServiceName' created successfully. [$global:resourceCounter]"
                Write-Log -message "API Management service '$apiManagementServiceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }

            New-ApiManagementApi -resourceGroupName $resourceGroupName -apiManagementServiceName $apiManagementServiceName

        }
        catch {
            Write-Error "Failed to create Api Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Api Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "Api Management service '$apiManagementServiceName' already exists."
        Write-Log -message "Api Management service '$apiManagementServiceName' already exists." -logFilePath $global:LogFilePath

        $status = az apim show --resource-group $resourceGroupName --name $apiManagementServiceName --query "provisioningState" -o tsv

        if ($status -eq "Activating") {
            Write-Host "Api Management service '$apiManagementServiceName' is activating."
            Write-Log -message "Api Management service '$apiManagementServiceName' is activating." -logFilePath $global:LogFilePath
            return
        }

        New-ApiManagementApi -resourceGroupName $resourceGroupName -apiManagementServiceName $apiManagementServiceName
    }
}

# Function to register an app, set API permissions, expose the API, and set Key Vault access policies
function New-App-Registration {
    param (
        [string]$appServiceName,
        [string]$appServiceUrl,
        [string]$resourceGroupName,
        [string]$keyVaultName,
        [string]$parametersFile
    )

    try {
        $ErrorActionPreference = 'Stop'

        $appRegRequiredResourceAccessJson = $appRegRequiredResourceAccess | ConvertTo-Json -Depth 4

        # Check if the app is already registered
        $existingApp = az ad app list --filter "displayName eq '$appServiceName'" --query "[].appId" --output tsv

        if ($existingApp) {
            Write-Host "App '$appServiceName' is already registered with App ID: $existingApp."
            Write-Log -message "App '$appServiceName' is already registered with App ID: $existingApp."

            $appId = $existingApp
            $objectId = az ad app show --id $appId --query "objectId" --output tsv
        }
        else {
            # Register the app
            $appRegistration = az ad app create --display-name $appServiceName --sign-in-audience AzureADandPersonalMicrosoftAccount | ConvertFrom-Json

            $appId = $appRegistration.appId
            $objectId = $appRegistration.objectId

            Write-Host "App '$appServiceName' registered successfully with App ID: $appId and Object ID: $objectId."
            Write-Log -message "App '$appServiceName' registered successfully with App ID: $appId and Object ID: $objectId."
        }

        # Update the parameters file with the new app registration details
        Update-ParametersFile-AppRegistration -parametersFile $parametersFile -appId $appId -appUri $appUri

        $permissions = "User.Read.All"
        $apiPermissions = ""
        
        $dataSources = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

        foreach ($searchDataSource in $global:searchDataSources) {
            $searchDataSourceName = $searchDataSource.Name
            $dataSourceExists = $dataSources -contains $searchDataSourceName

            if ($dataSourceExists -eq $false) {
                New-SearchDataSource -searchServiceName $global:searchServiceName -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageAccountName $global:storageAccountName -appId $appId
            }
            else {
                Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
            }
        }

        # Check and set API permissions
        foreach ($permission in $appRegRequiredResourceAccess) {
            $existingPermission = az ad app permission list --id $appId
            if (-not $existingPermission) {

                try {

                    $permissionResourceAppId = $permission.resourceAppId

                    foreach ($access in $permission.resourceAccess) {
                        $apiPermissions += "$($access.id)=$($access.type) "
                        az ad app permission add --id $appId --api $permissionResourceAppId --api-permissions "$($access.id)=$($access.type)"
                    }

                    Write-Host "API Permissions: $apiPermissions"

                    #For some reason using the variables is not working with the command below
                    #az ad app permission add --id $appId --api $permissionResourceAppId --api-permissions 
                    #az ad app permission add --id $appId --api $permission.resourceAppId --api-permissions $permissions=Scope

                    Write-Host "Permission '$permissions' for '$appServiceName' with App ID: $appId added successfully."
                    Write-Log -message "Permission '$permissions' for '$appServiceName' with App ID: $appId added successfully." -logFilePath $global:LogFilePath
                }
                catch {
                    Write-Error "Failed to add permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to add permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }

                try {
                    az ad app permission grant --id $appId --api $permissionResourceAppId --scope $permissions

                    Write-Host "Permission '$permissions' for '$appServiceName' with App ID: $appId granted successfully."
                    Write-Log -message "Permission '$permissions' for '$appServiceName' with App ID: $appId granted successfully." -logFilePath $global:LogFilePath
                }
                catch {
                    Write-Error "Failed to grant permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed grant add permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }

        #az ad app permission grant --id $appId --api $permission.resourceAppId --scope $permissions

        Write-Host "Api permissions set for app '$appServiceName'."
        Write-Log -message "Api permissions set for app '$appServiceName'."

        try {
            # Check and expose the API
            $existingScopes = az ad app show --id $appId --query "oauth2Permissions[].value" --output tsv
            $apiScopes = @()
            foreach ($scope in $exposeApiScopes) {
                if (-not ($existingScopes -contains $scope.value)) {
                    $apiScopes += @{
                        "adminConsentDescription" = $scope.adminConsentDescription
                        "adminConsentDisplayName" = $scope.adminConsentDisplayName
                        "id"                      = [guid]::NewGuid().ToString()
                        "isEnabled"               = $true
                        "type"                    = "User"
                        "userConsentDescription"  = $scope.userConsentDescription
                        "userConsentDisplayName"  = $scope.userConsentDisplayName
                        "value"                   = $scope.value
                    }
                }
            }
    
            # Retrieve the current application manifest
            $app = az ad app show --id $appId | ConvertFrom-Json
    
            # Define the identifierUrisArray
            # $identifierUrisArray = @{"uri" = "https://app-$global:resourceBaseName.azurewebsites.net" }
            #$identifierUris = "https://app-$global:resourceBaseName.azurewebsites.net api://$global:appRegistrationClientId"
            #$identifierUris = "api://$global:appRegistrationClientId"

            # Update the identifierUris and oauth2PermissionScopes properties
            #$app.identifierUris = $identifierUris
            $app.api.oauth2PermissionScopes += $apiScopes

            # The issue with the below code is that the entries made for the API access permissions are using AD Graph and not MS Graph. The AD graph does not have "name" or "description" properties.
            # So even though the original code I had set in the parameters file was correct, the code below is not working as expected so I removed those two properties from the parameters.json file.
            # It was then that I realized that it was using the wrong Graph API because instead of the name of the permission being showm it was the GUID instead.
            # It would appear that the manifest file will not allow me to add the permissions from the MS Graph API only the AD Graph API. 
            # Even though the manifest files for the AD and MS Graph APIs are the same, unless I add the permissions using the GUI in the web portal the values will be saved as AD Graph and not MS Graph.
            # I still need to figure out how to add the permissions from the MS Graph API instead of the AD Graph API.

            $app.requiredResourceAccess = $appRegRequiredResourceAccess
            #$app.spa.redirectUris = $appServiceUrl

            # Convert the updated manifest back to JSON
            $appJson = $app | ConvertTo-Json -Depth 10
    
            # Update the application with the modified manifest
            $appJson | Out-File -FilePath "appManifest.json" -Encoding utf8
            az ad app update --id $appId --set appManifest.json
            
            az ad app update --id $appId --sign-in-audience AzureADandPersonalMicrosoftAccount
            az ad app update --id $appId --set api.oauth2PermissionScopes=$($app.api.oauth2PermissionScopes | ConvertTo-Json -Depth 10)
            az ad app update --id $appId --required-resource-accesses $appRegRequiredResourceAccessJson
            #az ad app update --id $appId --identifier-uris $identifierUris
            #az ad app update --id $appId --set displayName=app-copilot-demo-002
            #az ad app update --id $appId --set notes=test

            Write-Host "Scope for app '$appServiceName' added successfully."
            Write-Log -message "Scope for app '$appServiceName' added successfully." -logFilePath $global:LogFilePath
        }
        catch {
            Write-Error "Failed to add scopes for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to add scopes for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }

        try {
            # Set Key Vault access policies
            az keyvault set-policy --name $keyVaultName --object-id $objectId --secret-permissions get list set delete --key-permissions get list create delete --certificate-permissions get list create delete
    
            Write-Host "Key Vault access policies for app '$appServiceName' set successfully."
            Write-Log -message "Key Vault access policies for app '$appServiceName' set successfully.." -logFilePath $global:LogFilePath
        }
        catch {
            Write-Error "Failed to register app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to register app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    catch {
        Write-Error "Failed to set policies for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to set policies for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create a new Application Insights component
function New-ApplicationInsights {
    param (
        [string]$appInsightsName,
        [string]$location,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    if ($existingResources -notcontains $appInsightsName) {


        $appInsightsName = Get-ValidServiceName -serviceName $appInsightsName

        # Try to create an Application Insights component
        try {
            $ErrorActionPreference = 'Stop'
            az monitor app-insights component create --app $appInsightsName --location $location --resource-group $resourceGroupName --application-type web --output none

            $global:resourceCounter += 1
            Write-Host "Application Insights component '$appInsightsName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Application Insights component '$appInsightsName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Application Insights '$appInsightsName' already exists."
        Write-Log -message "Application Insights '$appInsightsName' already exists."
    }
}

# Function to create and deploy app service (either web app or function app)
function New-AppService {
    param (
        [PSObject]$appService,
        [string]$resourceGroupName,
        [string]$storageServiceName,
        [bool]$deployZipResources,
        [array]$existingResources
    )

    $appExists = @()

    $ErrorActionPreference = 'Stop'

    # Making sure we are in the correct folder depending on the app type
    Set-DirectoryPath -targetDirectory $appService.Path

    $appServiceType = $appService.Type
    $appServiceName = $appService.Name
    $deployZipPackage = $appService.DeployZipPackage

    try {
        try {

            if ($appServiceType -eq "Web") {

                $appExists = az webapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new web app
                    az webapp create --name $appServiceName --resource-group $resourceGroupName --plan $appService.AppServicePlan --runtime $appService.Runtime --deployment-source-url $appService.Url
                    #az webapp cors add --methods GET POST PUT --origins '*' --services b --account-name $appServiceName --account-key $storageAccessKey
                    $userAssignedIdentity = az identity show --resource-group $resourceGroupName --name $global:userAssignedIdentityName

                    az webapp identity assign --name $appServiceName --resource-group $resourceGroupName --identities $userAssignedIdentity.id --output tsv
                }
            }
            else {

                # Check if the Function App exists
                $appExists = az functionapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new function app
                    az functionapp create --name $appServiceName --resource-group $resourceGroupName --storage-account $storageServiceName --plan $appService.AppServicePlan --app-insights $appInsightsName --runtime $appService.Runtime --os-type "Windows" --functions-version 4 --output none

                    $functionAppKey = az functionapp keys list --name $appServiceName --resource-group $resourceGroupName --query "functionKeys.default" --output tsv
                    az functionapp cors add --methods GET POST PUT --origins '*' --services b --account-name $appServiceName --account-key $functionAppKey
                }
            }

            if (-not $appExists) {

                $global:resourceCounter += 1
                Write-Host "$appServiceType app '$appServiceName' created successfully. Moving on to deployment. [$global:resourceCounter]"
                Write-Log -message "$appServiceType app '$appServiceName' created successfully. Moving on to deployment. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            else {
                Write-Host "$appServiceType app '$appServiceName' already exists. Moving on to deployment."
                Write-Log -message "$appServiceType app '$appServiceName' already exists. Moving on to deployment." -logFilePath $global:LogFilePath
            }

            Deploy-AppService -appService $appService -resourceGroupName $resourceGroupName -deployZipResources $deployZipResources -deployZipPackage $deployZipPackage
        }
        catch {
            Write-Error "Failed to create $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    catch {
        Write-Error "Failed to zip $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to zip $appServiceType app '$appServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
    }

    Set-DirectoryPath -targetDirectory $global:deploymentPath
}

# Function to create a new App Service Environment (ASE)
function New-AppServiceEnvironment {
    param (
        [string]$appServiceEnvironmentName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$vnetName,
        [string]$subnetName,
        [string]$subscriptionId,
        [array]$existingResources
    )

    if ($existingResources -notcontains $appServicePlanName) {
        try {
            $ErrorActionPreference = 'Stop'

            # Create the ASE asynchronously
            <#
 # {            $job = Start-Job -ScriptBlock {
                param (
                    $appServiceEnvironmentName,
                    $resourceGroupName,
                    $location,
                    $vnetName,
                    $subnetName,
                    $subscriptionId
                )
                az appservice ase create --name $appServiceEnvironmentName --resource-group $resourceGroupName --location $location --vnet-name $vnetName --subnet $subnetName --subscription $subscriptionId --output none
            } -ArgumentList $appServiceEnvironmentName, $resourceGroupName, $location, $vnetName, $subnetName, $subscriptionId
:Enter a comment or description}
#>
            Write-Host "Waiting for App Service Environment '$appServiceEnvironmentName' to be created before creating app service plan and app services."
            Start-Sleep -Seconds 20

            #az appservice ase create --name $appServiceEnvironmentName --resource-group $resourceGroupName --location $location --vnet-name $vnetName --subnet $subnetName --subscription $subscriptionId --output none
            Write-Host "App Service Environment '$appServiceEnvironmentName' created successfully."
            Write-Log -message "App Service Environment '$appServiceEnvironmentName' created successfully."
        }
        catch {
            Write-Error "Failed to create App Service Environment '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create App Service Environment '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "App Service Environment '$appServiceEnvironmentName' already exists."
        Write-Log -message "App Service Environment '$appServiceEnvironmentName' already exists."
    }
}

# Function to create a new App Service Plan
function New-AppServicePlan {
    param (
        [string]$appServicePlanName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$sku,
        [array]$existingResources
    )

    $sku = "B1"

    if ($existingResources -notcontains $appServicePlanName) {
        try {
            $ErrorActionPreference = 'Stop'
            az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku $sku --output none

            $global:resourceCounter += 1
            Write-Host "App Service Plan '$appServicePlanName' created successfully. [$global:resourceCounter]"
            Write-Log -message "App Service Plan '$appServicePlanName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create App Service Plan '$appServicePlanName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create App Service Plan '$appServicePlanName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "App Service Plan '$appServicePlanName' already exists."
        Write-Log -message "App Service Plan '$appServicePlanName' already exists."
    }
}

# Function to create a new App Service Plan in an App Service Environment (ASE)
function New-AppServicePlanInASE {
    param (
        [string]$appServicePlanName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$appServiceEnvironmentName,
        [array]$existingResources
    )


    try {
        $ErrorActionPreference = 'Stop'
        az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --app-service-environment $appServiceEnvironmentName --sku $sku --output none

        $global:resourceCounter += 1
        Write-Host "App Service Plan '$appServicePlanName' created in ASE '$appServiceEnvironmentName'. [$global:resourceCounter]"
        Write-Log -message "App Service Plan '$appServicePlanName' created in ASE '$appServiceEnvironmentName'. [$global:resourceCounter]"
    }
    catch {
        Write-Error "Failed to create App Service Plan '$appServicePlanName' in ASE '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create App Service Plan '$appServicePlanName' in ASE '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create new Azure Cognitive Services account
function New-CognitiveServicesAccount {
    param (
        [string]$resourceGroupName,
        [string]$location,
        [string]$cognitiveServiceName,
        [array]$existingResources
    )

    if ($existingResources -notcontains $cognitiveServiceName) {
        try {
            $ErrorActionPreference = 'Stop'

            #$cognitiveServicesUrl = "https://$cognitiveServiceName.cognitiveservices.azure.com/"

            $jsonOutput = az cognitiveservices account create --name $cognitiveServiceName --resource-group $resourceGroupName --location $location --sku S0 --kind CognitiveServices --output none 2>&1

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create Cognitive Services account '$cognitiveServiceName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $cognitiveServiceName -resourceType "CognitiveService" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {

                $global:resourceCounter += 1
                Write-Host "Cognitive Services account '$cognitiveServiceName' created successfully. [$global:resourceCounter]"
                Write-Log -message "Cognitive Services account '$cognitiveServiceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath

                # Assign managed identity to the Cognitive Services account
                az cognitiveservices account identity assign --name $cognitiveServiceName --resource-group $resourceGroupName

                Write-Host "Managed identity '$userAssignedIdentityName' assigned to Cognitive Services account '$cognitiveServiceName'."
                Write-Log -message "Managed identity '$userAssignedIdentityName' assigned to Cognitive Services account '$cognitiveServiceName'."
            }
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                # Attempt to restore the soft-deleted Cognitive Services account
                Restore-SoftDeletedResource -resourceName $cognitiveServiceName -resourceType "CognitiveService" -resourceGroupName $resourceGroupName
            }
            else {
                Write-Error "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
    }
    else {
        Write-Host "Cognitive Service '$cognitiveServiceName' already exists."
        Write-Log -message "Cognitive Service '$cognitiveServiceName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create a new Computer Vision account
function New-ComputerVisionAccount {
    param (
        [string]$computerVisionName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    if ($existingResources -notcontains $computerVisionName) {
        $computerVisionName = Get-ValidServiceName -serviceName $computerVisionName

        try {
            $ErrorActionPreference = 'Stop'
            $jsonOutput = az cognitiveservices account create --name $computerVisionName --resource-group $resourceGroupName --location $location --kind ComputerVision --sku S1 --output none 2>&1

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create Computer Vision account '$computerVisionName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $computerVisionName -resourceType "ComputerVision" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error "Failed to create Cognitive Services account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Cognitive Services account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                $global:resourceCounter += 1

                Write-Host "Computer Vision account '$computerVisionName' created successfully. [$global:resourceCounter]"
                Write-Log -message "Computer Vision account '$computerVisionName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath

                try {
                    # Assign custom domain
                    az cognitiveservices account update --name $computerVisionName --resource-group $resourceGroupName --custom-domain $computerVisionName

                    Write-Host "Custom Domain created for Computer Vision account '$computerVisionName'."
                    Write-Log -message "Custom Domain created for Computer Vision account '$computerVisionName'."
                }
                catch {
                    Write-Host "Failed to create custom domain for Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create custom domain for Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                # Attempt to restore the soft-deleted Cognitive Services account
                Restore-SoftDeletedResource -resourceName $computerVisionName -resourceType "CognitiveServices" -resourceGroupName $resourceGroupName
            }
            else {
                Write-Error "Failed to create Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
    }
    else {
        Write-Host "Computer Vision Service '$computerVisionName' already exists."
        Write-Log -message "Computer Vision Service '$computerVisionName' already exists."
    }
}

# Function to create a new container registry
function New-ContainerRegistry {
    param (
        [string]$containerRegistryName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    if ($existingResources -notcontains $containerRegistryName) {
        $containerRegistryFile = Update-ContainerRegistryFile -resourceGroupName $resourceGroupName -containerRegistryName $containerRegistryName -location $location

        try {
            $jsonOutput = az ml registry create --file $containerRegistryFile --resource-group $resourceGroupName 2>&1

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create Container Registry '$containerRegistryName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $containerRegistryName -resourceType "ContainerRegistry" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                $global:resourceCounter += 1

                Write-Host "Container Registry '$containerRegistryName' created successfully. [$global:resourceCounter]"
                Write-Log -message "Container Registry '$containerRegistryName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
        }
        catch {
            Write-Error "Failed to create Container Registry '$containerRegistryName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Container Registry '$containerRegistryName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Container Registry '$containerRegistryName' already exists."
        Write-Log -message "Container Registry '$containerRegistryName' already exists."
    }
}

# Function to create a new document intelligence account
function New-DocumentIntelligenceAccount {
    param (
        [string]$documentIntelligenceName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$subscriptionId,
        [array]$existingResources
    )

    if ($existingResources -notcontains $documentIntelligenceName) {

        $availableLocations = az cognitiveservices account list-skus --kind FormRecognizer --query "[].locations" --output tsv

        # Check if the desired location is available
        if ($availableLocations -contains $($location.ToUpper() -replace '\s', '')  ) {
            # Try to create a Document Intelligence account
            try {
                $ErrorActionPreference = 'Stop'

                $jsonOutput = az cognitiveservices account create --name $documentIntelligenceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --kind FormRecognizer --sku S0 --output none 2>&1
                # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

                if ($jsonOutput -match "error") {

                    $jsonProperties = '{"restore": true}'
                    $jsonOutput = az resource create --subscription $global:subscriptionId -g $resourceGroupName -n $documentIntelligenceName --location $location --namespace Microsoft.CognitiveServices --resource-type accounts --properties $jsonProperties

                    $errorInfo = Format-ErrorInfo -jsonOutput $jsonOutput

                    $errorMessage = "Failed to create Document Intelligence Service: '$documentIntelligenceName'. `
        `Error: $($errorInfo.Code) `
        `Code: $($errorInfo.Error) `
        `Details: $($errorInfo.SKU)"

                    # Check if the error is due to soft deletion
                    if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Restore-SoftDeletedResource -resourceName $keyVaultName -resourceType "DocumentIntelligence" -location $location -resourceGroupName $resourceGroupName
                    }
                    else {
                        Write-Error $errorMessage
                        Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                    }
                }
                else {

                    $global:resourceCounter += 1

                    Write-Host "Document Intelligence account '$documentIntelligenceName' created successfully. [$global:resourceCounter]"
                    Write-Log -message "Document Intelligence account '$documentIntelligenceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
                }

            }
            catch {
                # Check if the error is due to soft deletion
                if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                    try {
                        $ErrorActionPreference = 'Stop'
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Recover-SoftDeletedResource -resourceName $documentIntelligenceName -resourceType "DocumentIntelligence" -resourceGroupName $resourceGroupName
                        Write-Host "Document Intelligence account '$documentIntelligenceName' restored."
                        Write-Log -message "Document Intelligence account '$documentIntelligenceName' restored."
                    }
                    catch {
                        Write-Error "Failed to restore Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to restore Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    }
                }
                else {
                    Write-Error "Failed to create Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }
        else {
            Write-Error "The desired location '$location' is not available for FormRecognizer."
            Write-Log -message "The desired location '$location' is not available for FormRecognizer."
        }
    }
    else {
        Write-Host "Document Intelligence Service '$documentIntelligenceName' already exists."
        Write-Log -message "Document Intelligence Service '$documentIntelligenceName' already exists."
    }
}

# Function to create a new key vault
function New-KeyVault {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$userPrincipalName,
        [string]$userAssignedIdentityName,
        [bool]$useRBAC,
        [array]$existingResources
    )

    if ($existingResources -notcontains $keyVaultName) {

        try {
            $ErrorActionPreference = 'Continue'

            $jsonOutput = az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $useRBAC --output none 2>&1

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create Key Vault: '$keyVaultName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "ConflictError" -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $keyVaultName -resourceType "KeyVault" -location $location -resourceGroupName $resourceGroupName -useRBAC $true -userAssignedIdentityName $userAssignedIdentityName
                }
                else {
                    Write-Error $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }

            }
            else {
                if ($useRBAC) {

                    $global:resourceCounter += 1

                    Write-Host "Key Vault '$keyVaultName' created with RBAC enabled. [$global:resourceCounter]"
                    Write-Log -message "Key Vault '$keyVaultName' created with RBAC enabled. [$global:resourceCounter]"

                    # Assign RBAC roles to the managed identity
                    Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                }
                else {
                    $global:resourceCounter += 1
                    Write-Host "Key Vault '$keyVaultName' created with Vault Access Policies. [$global:resourceCounter]"
                    Write-Log -message "Key Vault '$keyVaultName' created with Vault Access Policies. [$global:resourceCounter]"

                    # Set vault access policies for user
                    Set-KeyVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                }
            }
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                Restore-SoftDeletedResource -resourceName $keyVaultName -resourceType "KeyVault" -location $location -resourceGroupName $resourceGroupName -useRBAC $true -userAssignedIdentityName $userAssignedIdentityName
            }
            else {
                Write-Error "Failed to restore soft-deleted Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore soft-deleted Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }

        Set-KeyVaultRoles -keyVaultName $keyVaultName `
            -resourceGroupName $resourceGroupName `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -useRBAC $useRBAC

        #Set-KeyVaultSecrets -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName
    }
    else {
        Write-Host "Key Vault '$keyVaultName' already exists."
        Write-Log -message "Key Vault '$keyVaultName' already exists."
    }
}

# Function to create a new Log Analytics workspace
function New-LogAnalyticsWorkspace {
    param (
        [string]$logAnalyticsWorkspaceName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    $logAnalyticsWorkspaceName = Get-ValidServiceName -serviceName $logAnalyticsWorkspaceName

    if ($existingResources -notcontains $logAnalyticsWorkspaceName) {
        try {
            $ErrorActionPreference = 'Stop'
            az monitor log-analytics workspace create --workspace-name $logAnalyticsWorkspaceName --resource-group $resourceGroupName --location $location --output none

            $global:resourceCounter += 1

            Write-Host "Log Analytics Workspace '$logAnalyticsWorkspaceName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Log Analytics Workspace '$logAnalyticsWorkspaceName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Log Analytics workspace '$logAnalyticsWorkspaceName' already exists."
        Write-Log -message "Log Analytics workspace '$logAnalyticsWorkspaceName' already exists."
    }
}

# Function to create a new managed identity
function New-ManagedIdentity {
    param (
        [string]$userAssignedIdentityName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$subscriptionId,
        [array]$existingResources
    )

    try {
        $ErrorActionPreference = 'Stop'
        az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none

        $global:resourceCounter += 1

        Write-Host "User Assigned Identity '$userAssignedIdentityName' created successfully. [$global:resourceCounter]"
        Write-Log -message "User Assigned Identity '$userAssignedIdentityName' created successfully. [$global:resourceCounter]"

        Start-Sleep -Seconds 15

        $assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $userAssignedIdentityName --query 'principalId' --output tsv

        try {
            $ErrorActionPreference = 'Stop'

            # Ensure the service principal is created
            az ad sp create --id $assigneePrincipalId
            Write-Host "Service principal created for identity '$userAssignedIdentityName'."
            Write-Log -message "Service principal created for identity '$userAssignedIdentityName'."
        }
        catch {
            Write-Error "Failed to create service principal for identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create service principal for identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }

        # Construct the fully qualified resource ID for the User Assigned Identity
        try {
            $ErrorActionPreference = 'Stop'
            #$userAssignedIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
            $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
            $roles = @("Contributor", "Cognitive Services OpenAI User", "Search Index Data Reader", "Storage Blob Data Reader")  # List of roles to assign

            Start-Sleep -Seconds 15

            foreach ($role in $roles) {
                az role assignment create --assignee $assigneePrincipalId --role $role --scope $scope

                Write-Host "User '$userAssignedIdentityName' assigned to role: '$role'."
                Write-Log -message "User '$userAssignedIdentityName' assigned to role: '$role'."
            }
        }
        catch {
            Write-Error "Failed to assign role for Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to assign role for Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    catch {
        Write-Error "Failed to create User Assigned Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create User Assigned Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create a new machine learning workspace (Azure AI Project)
function New-MachineLearningWorkspace {
    param(
        [string]$aiProjectName,
        [string]$subscriptionId,
        [string]$aiHubName,
        [string]$appInsightsName,
        [string]$containerRegistryName,
        [string]$userAssignedIdentityName,
        [string]$storageServiceName,
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$workspaceName,
        [string]$location,
        [array]$existingResources
    )

    $storageServiceName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName"
    $containerRegistryName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName"
    $keyVaultName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
    $appInsightsName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName"
    $userAssignedIdentityName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$global:userAssignedIdentityName"
    $aiHubName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName"

    if ($existingResources -notcontains $aiProjectName) {

        try {
            $ErrorActionPreference = 'Stop'

            # https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-openai?view=azureml-api-2
            # "While the az ml connection commands can be used to manage both Azure Machine Learning and Azure AI Studio connections, the OpenAI connection is specific to Azure AI Studio."

            $mlWorkspaceFile = Update-MLWorkspaceFile `
                -aiProjectName $aiProjectName `
                -aiHubName $aiHubName `
                -resourceGroupName $resourceGroupName `
                -appInsightsName $appInsightsName `
                -keyVaultName $keyVaultName `
                -location $location `
                -subscriptionId $subscriptionId `
                -storageAccountName $storageServiceName `
                -containerRegistryName $containerRegistryName `
                -userAssignedIdentityName $userAssignedIdentityName 2>&1

            #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

            #https://azuremlschemas.azureedge.net/latest/workspace.schema.json

            #$jsonOutput = az ml workspace create --file $mlWorkspaceFile --resource-group $resourceGroupName --output none 2>&1
            #$jsonOutput = az ml workspace create --file $mlWorkspaceFile -g $resourceGroupName --primary-user-assigned-identity $userAssignedIdentityName --kind project --hub-id $aiHubName --output none 2>&1
            
            $jsonOutput = az ml workspace create --resource-group $resourceGroupName `
                --application-insights $appInsightsName `
                --description "This configuration specifies a workspace configuration with existing dependent resources" `
                --display-name $aiProjectName `
                --hub-id $aiHubName `
                --kind project `
                --location $location `
                --name $aiProjectName `
                --output none 2>&1
            #--key-vault $keyVaultName `
            #--storage-account $storageServiceName `
            #--tags "Purpose: Azure AI Hub Project or Machine Learning Workspace"`
            #--update-dependent-resources `
            #--output none 2>&1

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create AI Project or Machine Learning Workspace '$aiProjectName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorDetails -match "soft-deleted workspace" -and $global:restoreSoftDeletedResource) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $aiProjectName -resourceType "MachineLearningWorkspace" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    # Commenting out below code until Azure CLI is updated to support AI Hub Projects

                    #Write-Error "Failed to create Cognitive Services account '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    #Write-Log -message "Failed to create Cognitive Services account '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Error "Failed to create Machine Learning Workspace '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Machine Learning Workspace '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                # Commenting out below code until Azure CLI is updated to support AI Hub Projects

                #Write-Host "AI Project '$aiProjectName' in '$aiHubName' created successfully."
                #Write-Log -message "AI Project '$aiProjectName' in '$aiHubName' created successfully." -logFilePath $global:LogFilePath
                $global:resourceCounter += 1

                Write-Host "Machine Learning Workspace '$aiProjectName' created successfully. [$global:resourceCounter]"
                Write-Log -message "Machine Learning Workspace '$aiProjectName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath

                return $jsonOutput
            }
        }
        catch {
            # Commenting out below code until Azure CLI is updated to support AI Hub Projects
            Write-Error "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath

            Write-Error "Failed to create Machine Learning Workspace '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Machine Learning Workspace '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        # Commenting out below code until Azure CLI is updated to support AI Hub Projects

        #Write-Host "AI Project '$aiProjectName' in '$aiHubName' already exists."
        #Write-Log -message "AI Project '$aiProjectName' in '$aiHubName' already exists." -logFilePath $global:LogFilePath

        Write-Host "Machine Learning Workspace '$aiProjectName' already exists."
        Write-Log -message "Machine Learning Workspace '$aiProjectName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create new OpenAI account
function New-OpenAIAccount {
    param (
        [string]$openAIAccountName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$existingResources
    )

    if ($existingResources -notcontains $openAIAccountName) {

        try {
            $ErrorActionPreference = 'Stop'

            $jsonOutput = az cognitiveservices account create --name $openAIAccountName --resource-group $resourceGroupName --location $location --kind OpenAI --sku S0 --output none 2>&1

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create Open AI service '$openAIAccountName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                # Check if the error is due to soft deletion
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResource) {
                    try {
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Restore-SoftDeletedResource -resourceName $openAIAccountName -resourceType "OpenAI" -location $location -resourceGroupName $resourceGroupName
                    }
                    catch {
                        Write-Error "Failed to restore Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to restore Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    }
                }
                else {
                    Write-Error "Failed to create Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                $global:resourceCounter += 1

                Write-Host "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]"
                Write-Log -message "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }

            #Write-Host "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]"
            #Write-Log -message "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResource) {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Cognitive Services service
                    Restore-SoftDeletedResource -resourceName $openAIAccountName -resourceType "OpenAI" -location $location -resourceGroupName $resourceGroupName
                }
                catch {
                    Write-Error "Failed to restore Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                Write-Error "Failed to create Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Azure OpenAI service '$openAIAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
    }
    else {
        Write-Host "Azure OpenAI service '$openAIAccountName' already exists."
        Write-Log -message "Azure OpenAI service '$openAIAccountName' already exists."
    }
}

# Function to create a new private endpoint
function New-PrivateEndPoint {
    param (
        [string]$privateEndpointName,
        [string]$privateLinkServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$subnetId,
        [string]$privateLinkServiceId,
        [array]$existingResources
    )

    try {
        az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroupName --vnet-name $virtualNetworkName --subnet $subnetId --private-connection-resource-id $privateLinkServiceId --group-id "sqlServer" --connection-name $privateLinkServiceName --location $location --output none
        Write-Host "Private endpoint '$privateEndpointName' created successfully."
        Write-Log -message "Private endpoint '$privateEndpointName' created successfully."
    }
    catch {
        Write-Error "Failed to create private endpoint '$privateEndpointName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create private endpoint '$privateEndpointName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to get the latest API version
function New-RandomPassword {
    param (
        [int]$length = 16,
        [int]$nonAlphanumericCount = 2
    )

    try {
        $alphanumericChars = [char[]]"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".ToCharArray()
        $nonAlphanumericChars = [char[]]"!@#$%^&*()-_=+[]{}|;:,.<>?/~".ToCharArray()

        $passwordChars = New-Object char[] $length

        for ($i = 0; $i -lt ($length - $nonAlphanumericCount); $i++) {
            $passwordChars[$i] = $alphanumericChars[(Get-Random -Maximum $alphanumericChars.Length)]
        }

        for ($i = ($length - $nonAlphanumericCount); $i -lt $length; $i++) {
            $passwordChars[$i] = $nonAlphanumericChars[(Get-Random -Maximum $nonAlphanumericChars.Length)]
        }

        #Shuffle the characters to ensure randomness
        for ($i = 0; $i -lt $length; $i++) {
            $j = $random.GetInt32($length)
            $temp = $passwordChars[$i]
            $passwordChars[$i] = $passwordChars[$j]
            $passwordChars[$j] = $temp
        }

        return -join $passwordChars
    }
    catch {
        Write-Error "Failed to generate random password: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to generate random password: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        return $null
    }
}

# Function to create a new resource group
function New-ResourceGroup {
    param (
        [bool]$resourceGroupExists,
        [string]$resourceGroupName,
        [string]$location
    )

    do {
        $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName -location $location

        if ($resourceGroupExists -eq $true) {
            Write-Host "Resource group '$resourceGroupName' already exists. Trying a new name."
            Write-Log -message "Resource group '$resourceGroupName' already exists. Trying a new name."

            $resourceSuffix++
            $resourceGroupName = "$($resourceGroupName)-$resourceSuffix"
        }

    } while ($resourceGroupExists -eq $true)

    try {
        az group create --name $resourceGroupName --location $location --output none

        $global:resourceCounter += 1

        Write-Host "Resource group '$resourceGroupName' created successfully. [$global:resourceCounter]"
        Write-Log -message "Resource group '$resourceGroupName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        $resourceGroupExists = $false
    }
    catch {
        Write-Host "An error occurred while creating the resource group."
        Write-Log -message "An error occurred while creating the resource group '$resourceGroupName'." -logFilePath $global:LogFilePath
    }

    return $resourceGroupName
}

# Function to create resources
function New-Resources {
    param (
        [psobject]$apiManagementService,
        [string]$aiProjectName,
        [string]$appInsightsName,
        [string]$appServiceEnvironmentName,
        [string]$appServicePlanName,
        [string]$appServicePlanSku,
        [string]$blobStorageContainerName,
        [string]$cognitiveServiceName,
        [string]$computerVisionName,
        [string]$containerRegistryName,
        [string]$documentIntelligenceName,
        [array]$existingResources,
        [string]$keyVaultName,
        [string]$logAnalyticsWorkspaceName,
        [string]$managedEnvironmentName,
        [string]$openAIAccountName,
        [string]$portalDashboardName,
        [string]$searchDatasourceName,
        [string]$searchIndexerName,
        [string]$searchIndexName,
        [string]$searchServiceName,
        [array]$searchSkillSets,
        [string]$storageServiceName,
        [array]$subNet,
        [string]$userAssignedIdentityName,
        [string]$userPrincipalName,
        [array]$virtualNetwork
    )

    # Debug statements to print variable values
    #Write-Host "subscriptionId: $subscriptionId"
    #Write-Host "resourceGroupName: $resourceGroupName"
    #Write-Host "storageAccountName: $storageServiceName"
    #Write-Host "appServicePlanName: $appServicePlanName"
    #Write-Host "location: $location"
    #Write-Host "userPrincipalName: $userPrincipalName"
    #Write-Host "searchIndexName: $searchIndexName"
    #Write-Host "searchIndexerName: $searchIndexerName"
    #Write-Host "searchSkillSetName: $searchSkillSetName"

    # **********************************************************************************************************************
    # Create Storage Account

    New-StorageAccount -storageAccountName $storageServiceName -resourceGroupName $resourceGroupName -existingResources $existingResources

    #$storageAccessKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv
    #$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageServiceName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

    # **********************************************************************************************************************
    # Create Virtual Network

    New-VirtualNetwork -virtualNetwork $virtualNetwork -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Subnet

    New-SubNet -subNet $subNet -vnetName $virtualNetworkName -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create App Service Environment

    #New-AppServiceEnvironment -appServiceEnvironmentName $appServiceEnvironmentName -resourceGroupName $resourceGroupName -location $location -vnetName $virtualNetwork.Name -subnetName $subnet.Name -subscriptionId $subscriptionId -existingResources $existingResources

    # **********************************************************************************************************************
    # Create App Service Plan

    New-AppServicePlan -appServicePlanName $appServicePlanName -resourceGroupName $resourceGroupName -location $location -appServiceEnvironmentName $appServiceEnvironmentName -sku $appServicePlanSku -existingResources $existingResources

    #New-AppServicePlanInASE -appServicePlanName $appServicePlanName -resourceGroupName $resourceGroupName -location $location -appServiceEnvironmentName $appServiceEnvironmentName -sku $appServicePlanSku -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Cognitive Services account

    New-CognitiveServicesAccount -cognitiveServiceName $cognitiveServiceName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Search Service

    New-SearchService -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -location $location -searchSkillSets $searchSkillSets -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Log Analytics Workspace

    New-LogAnalyticsWorkspace -logAnalyticsWorkspaceName $logAnalyticsWorkspaceName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Application Insights component

    New-ApplicationInsights -appInsightsName $appInsightsName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create OpenAI account

    New-OpenAIAccount -openAIAccountName $openAIAccountName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Container Registry

    New-ContainerRegistry -containerRegistryName $containerRegistryName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Document Intelligence account

    New-DocumentIntelligenceAccount -documentIntelligenceName $documentIntelligenceName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Computer Vision account

    New-ComputerVisionAccount -computerVisionName $computerVisionName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    #**********************************************************************************************************************
    # Create API Management Service

    # Commenting out for now because this resource is not being used in the deployment and it takes way too long to provision
    New-ApiManagementService -apiManagementService $apiManagementService -resourceGroupName $resourceGroupName -existingResources $existingResources

}

# Function to create a new search datasource
function New-SearchDataSource {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [psobject]$searchDatasource,
        [string]$searchDatasourceContainerName = "content",
        [string]$searchDatasourceQuery = "*",
        [string]$searchDatasourceDataChangeDetectionPolicy = "HighWaterMark",
        [string]$searchDatasourceDataDeletionDetectionPolicy = "SoftDeleteColumn",
        [string]$appId = ""
    )

    # https://learn.microsoft.com/en-us/azure/search/search-howto-index-sharepoint-online

    try {
        $ErrorActionPreference = 'Continue'

        $searchDataSourceName = $searchDatasource.Name
        $searchDatasourceType = $searchDatasource.Type
        $searchDatasourceQuery = $searchDatasource.Query
        $searchDatasourceContainerName = $searchDatasource.ContainerName
        $searchDatasourceConnectionString = ""

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $storageAccessKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

        foreach ($appService in $global:appServices) {
            $appServiceName = $appService.Name

            if ($appService.Type -eq "Web") {
                #$appId = az webapp show --name $appService.Name --resource-group $resourceGroupName --query "id" --output tsv
                $appId = az ad app list --filter "displayName eq '$($appService.Name)'" --query "[].appId" --output tsv
                
                if ($appId -eq "") {
                    Write-Error "Failed to retrieve App ID for App Service."
                    Write-Log -message "Failed to retrieve App ID for App Service."

                    return
                }
                else {
                    Write-Host "App ID for $($appServiceName): $appId"
                }
            }
        }

        if ($appId -eq "") {
            Write-Error "Failed to retrieve App ID for App Service."
            Write-Log -message "Failed to retrieve App ID for App Service."

            return
        }

        switch ($searchDatasourceType) {
            "azureblob" {
                $searchDatasourceConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageServiceName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"
            }
            "azuresql" {
                $searchDatasourceConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlServerAdmin;Password=$sqlServerAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            }
            "cosmosdb" {
                $searchDatasourceConnectionString = "AccountEndpoint=https://$cosmosDBAccountName.documents.azure.com:443/;AccountKey=$cosmosDBAccountKey;"
            }
            "documentdb" {
                $searchDatasourceConnectionString = "AccountEndpoint=https://$documentDBAccountName.documents.azure.com:443/;AccountKey=$documentDBAccountKey;"
            }
            "mysql" {
                $searchDatasourceConnectionString = "Server=$mysqlServerName.mysql.database.azure.com;Database=$mysqlDatabaseName;Uid=$mysqlServerAdmin@$mysqlServerName;Pwd=$mysqlServerAdminPassword;SslMode=Preferred;"
            }
            "sharepoint" {
                $searchDataSourceUrl = $searchDataSource.Url
                $searchDatasourceConnectionString = "SharePointOnlineEndpoint=$searchDataSourceUrl;ApplicationId=$appId;TenantId=$global:tenantId"
            }
            "sql" {
                $searchDatasourceConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlServerAdmin;Password=$sqlServerAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            }
        }

        $searchDatasourceUrl = "https://$searchServiceName.search.windows.net/datasources?api-version=$global:searchServiceAPiVersion"

        Write-Host "searchDatasourceUrl: $searchDatasourceUrl"

        $body = @{
            name        = $searchDatasourceName
            type        = $searchDatasourceType
            credentials = @{
                connectionString = $searchDatasourceConnectionString
            }
            container   = @{
                name  = $searchDatasourceContainerName
                query = $searchDatasourceQuery
            }
        }

        # The code below is not supported by the Azure CLI
        # identity    = @{
        #     odata                = "#Microsoft.Azure.Search.DataUserAssignedIdentity"
        #     userAssignedIdentity = "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$global:userAssignedIdentityName"
        # }

        # Convert the body hashtable to JSON
        $jsonBody = $body | ConvertTo-Json -Depth 10

        try {
            $ErrorActionPreference = 'Continue'

            Invoke-RestMethod -Uri $searchDatasourceUrl -Method Post -Body $jsonBody -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }

            Write-Host "Datasource '$searchDatasourceName' created successfully."
            Write-Log -message "Datasource '$searchDatasourceName' created successfully."
                
            return true
        }
        catch {

            Write-Error "Failed to create datasource '$searchDatasourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create datasource '$searchDatasourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create datasource '$searchDatasourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create datasource '$searchDatasourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return false
    }
}

# Function to create a new search index
function New-SearchIndex {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexName,
        [string]$searchIndexSchema
    )

    try {

        $content = Get-Content -Path $searchIndexSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $previousFullResourceBaseName, $newFullResourceBaseName

        Set-Content -Path $searchIndexSchema -Value $updatedContent

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $jsonContent = Get-Content -Path $searchIndexSchema -Raw | ConvertFrom-Json

        $jsonContent.name = $searchIndexName

        if ($searchIndexName -notlike "*vector*" -and $searchIndexName -notlike "*embeddings*") {
            if ($jsonContent.PSObject.Properties.Match('semantic')) {
                $jsonContent.PSObject.Properties.Remove('semantic')
            }

            if ($jsonContent.PSObject.Properties.Match('vectorSearch')) {
                $jsonContent.PSObject.Properties.Remove('vectorSearch')
            }

            if ($jsonContent.PSObject.Properties.Match('normalizer')) {
                $jsonContent.PSObject.Properties.Remove('normalizer')
            }
        }

        $updatedJsonContent = $jsonContent | ConvertTo-Json -Depth 10

        $updatedJsonContent | Set-Content -Path $searchIndexSchema

        # Construct the REST API URL
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexes?api-version=$global:searchServiceAPiVersion"

        # Create the index
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Index '$searchIndexName' created successfully."
            Write-Log -message "Index '$searchIndexName' created successfully."

            return true
        }
        catch {
            # If you are getting the 'Normalizers" error, create the index via the Azure Portal and just select "Add index (JSON)" and copy the contents of the appropriate index json file into the textarea and click "save".
            Write-Error "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return false
    }
}

# Function to create a new search indexer
function New-SearchIndexer {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$searchDatasourceName,
        [string]$searchIndexerSchema,
        [string]$searchSkillSetName,
        [string]$searchIndexerSchedule = "0 0 0 * * *"
    )

    try {

        $content = Get-Content -Path $searchIndexerSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $previousFullResourceBaseName, $newFullResourceBaseName

        Set-Content -Path $searchIndexerSchema -Value $updatedContent

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$global:searchServiceAPiVersion"

        $jsonContent = Get-Content -Path $searchIndexerSchema -Raw | ConvertFrom-Json

        $jsonContent.'@odata.context' = $searchIndexerUrl
        $jsonContent.name = $searchIndexerName
        $jsonContent.dataSourceName = $searchDatasourceName
        $jsonContent.targetIndexName = $searchIndexName

        if ($jsonContent.PSObject.Properties.Match('cache')) {
            $jsonContent.PSObject.Properties.Remove('cache')
        }

        if ($jsonContent.PSObject.Properties.Match('cache')) {
            $jsonContent.PSObject.Properties.Remove('cache')
        }

        if ($jsonContent.PSObject.Properties.Name -contains "skillsetName") {
            $jsonContent.skillsetName = $searchSkillSetName
        }

        if ($jsonContent.PSObject.Properties.Match('normalizer')) {
            $jsonContent.PSObject.Properties.Remove('normalizer')
        }

        $updatedJsonContent = $jsonContent | ConvertTo-Json -Depth 10

        $updatedJsonContent | Set-Content -Path $searchIndexerSchema

        # Construct the REST API URL
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$global:searchServiceApiVersion"

        # Create the indexer
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Search Indexer '$searchIndexerName' created successfully."
            Write-Log -message "Search Indexer '$searchIndexerName' created successfully."

            return true
        }
        catch {
            Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return false
    }
}

# Function to create a new search service
function New-SearchService {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [array]$searchSkillSets,
        [array]$existingResources
    )

    az provider show --namespace Microsoft.Search --query "resourceTypes[?resourceType=='searchServices'].apiVersions"

    if ($existingResources -notcontains $searchServiceName) {
        $searchServiceName = Get-ValidServiceName -serviceName $searchServiceName
        #$searchServiceSku = "basic"

        try {
            $ErrorActionPreference = 'Stop'

            az search service create --name $searchServiceName --resource-group $resourceGroupName --location $location --sku basic --output none

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create search service: $createServiceOutput"
            }

            $global:resourceCounter += 1

            Write-Host "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]"

            $global:searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

            $global:searchServiceProperties.ApiKey = $global:searchServiceApiKey

            $global:KeyVaultSecrets.SearchServiceApiKey = $global:searchServiceApiKey

            $searchManagementUrl = "https://management.azure.com/subscriptions/$global:subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
            $searchManagementUrl += "?api-version=$global:azureManagement.ApiVersion"

            #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
            # az search service update --name $searchServiceName --resource-group $resourceGroupName --identity SystemAssigned --aad-auth-failure-mode http401WithBearerChallenge --auth-options aadOrApiKey
            #  --identity type=UserAssigned userAssignedIdentities="/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"

            try {
                $ErrorActionPreference = 'Continue'
                $body = @{
                    location   = $location.Replace(" ", "")
                    sku        = @{
                        name = "basic"
                    }
                    properties = @{
                        replicaCount   = 1
                        partitionCount = 1
                        hostingMode    = "default"
                    }
                    identity   = @{
                        type                   = "SystemAssigned, UserAssigned"
                        userAssignedIdentities = @{
                            "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
                        }
                    }
                }

                # Convert the body hashtable to JSON

                # $accessToken = (az account get-access-token --query accessToken -o tsv)

                # $headers = @{
                #    "api-key"       = $searchServiceApiKey
                #    "Authorization" = "Bearer $accessToken"  # Add the authorization header
                #}

                #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
                #Invoke-RestMethod -Uri $searchManagementUrl -Method Patch -Body $jsonBody -ContentType "application/json" -Headers $headers

            }
            catch {
                Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }

            # Example for how to obtain the sharepoint siteid for use with the REST Api: https://fedairs.sharepoint.com/sites/MicrosoftCopilotDemo/_api/site
            $dataSources = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

            foreach ($appService in $global:appServices) {
                if ($appService.Type -eq "Web") {
                    $appServiceName = $appService.Name
                    #$appId = az webapp show --name $appService.Name --resource-group $resourceGroupName --query "id" --output tsv
                    $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
                    Write-Host "App ID for $($appServiceName): $appId"
                }
            }

            foreach ($searchDataSource in $global:searchDataSources) {
                $searchDataSourceName = $searchDataSource.Name
                $dataSourceExists = $dataSources -contains $searchDataSourceName

                if ($dataSourceExists -eq $false) {
                    New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageAccountName $storageServiceName -appId $appId
                }
                else {
                    Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                    Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
                }
            }

            #$dataSourceExists = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

            foreach ($index in $global:searchIndexes) {
                $indexName = $index.Name
                $indexSchema = $index.Schema

                $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
                $searchIndexExists = $searchIndexes -contains $indexName

                if ($searchIndexExists -eq $false) {
                    New-SearchIndex -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchDatasourceName $searchDatasourceName -searchIndexSchema $indexSchema
                }
                else {
                    Write-Host "Search Index '$indexName' already exists."
                    Write-Log -message "Search Index '$indexName' already exists."
                }
            }

            foreach ($searchSkillSet in $searchSkillSets) {

                $searchSkillSetName = $searchSkillSet.Schema.Name

                $existingSearchSkillSets = Get-SearchSkillSets -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchSkillSetName $searchSkillSetName

                $searchSkillSetExists = $existingSearchSkillSets -contains $searchSkillSetName

                if ($searchSkillSetExists -eq $false) {

                    Start-Sleep -Seconds 30
                    New-SearchSkillSet -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchSkillSet $searchSkillSet -cognitiveServiceName $cognitiveServiceName
                }
                else {
                    Write-Host "Search Skill Set '$searchSkillSetName' already exists."
                    Write-Log -message "Search Skill Set '$searchSkillSetName' already exists."
                }
            }

            try {
                if ($dataSourceExists -eq "true" -and $searchIndexExists -eq $true) {

                    $filteredSearchIndexers = $global:searchIndexers | Where-Object { $_.Active -eq $true }

                    foreach ($indexer in $filteredSearchIndexers) {
                        $indexName = $indexer.IndexName
                        $indexerName = $indexer.Name
                        $indexerSchema = $indexer.Schema
                        $indexerSkillSetName = $indexer.SkillSetName

                        $searchDataSourceName = $indexer.DataSourceName

                        $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName
                        $searchIndexerExists = $searchIndexers -contains $indexerName

                        if ($searchIndexerExists -eq $false) {
                            New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchIndexerName $indexerName -searchDatasourceName $searchDatasourceName -searchSkillSetName $indexerSkillSetName -searchIndexerSchema $indexerSchema -searchIndexerSchedule $searchIndexerSchedule
                        }
                        else {
                            Write-Host "Search Indexer '$indexer' already exists."
                            Write-Log -message "Search Indexer '$indexer' already exists." -logFilePath $global:LogFilePath
                        }
                    }

                    Start-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName

                    Start-Sleep -Seconds 10
                }
            }
            catch {
                Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        catch {
            Write-Error "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {

        Write-Host "Search Service '$searchServiceName' already exists."
        Write-Log -message "Search Service '$searchServiceName' already exists."

        #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
        #az search service update --name $searchServiceName --resource-group $resourceGroupName --identity SystemAssigned --aad-auth-failure-mode http401WithBearerChallenge --auth-options aadOrApiKey
        #  --identity type=UserAssigned userAssignedIdentities="/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"

        $global:searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $global:searchServiceProperties.ApiKey = $global:searchServiceApiKey

        $global:KeyVaultSecrets.SearchServiceApiKey = $global:searchServiceApiKey

        $searchManagementUrl = "https://management.azure.com/subscriptions/$global:subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
        $searchManagementUrl += "?api-version=$global:azureManagement.ApiVersion"

        # try {
        #     $ErrorActionPreference = 'Continue'

        #     $body = @{
        #         location   = $location.Replace(" ", "")
        #         sku        = @{
        #             name = "basic"
        #         }
        #         properties = @{
        #             replicaCount   = 1
        #             partitionCount = 1
        #             hostingMode    = "default"
        #         }
        #         identity   = @{
        #             type                   = "SystemAssigned, UserAssigned"
        #             userAssignedIdentities = @{
        #                 "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
        #             }
        #         }
        #     }

        #     # Convert the body hashtable to JSON
        #     $jsonBody = $body | ConvertTo-Json -Depth 10

        #     $accessToken = (az account get-access-token --query accessToken -o tsv)

        #     $headers = @{
        #         "api-key"       = $searchServiceApiKey
        #         "Authorization" = "Bearer $accessToken"  # Add the authorization header
        #     }

        #     #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
        #     Invoke-RestMethod -Uri $searchManagementUrl -Method Patch -Body $jsonBody -ContentType "application/json" -Headers $headers

        # }
        # catch {
        #     Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        #     Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        # }
    }

    try {
        $ErrorActionPreference = 'Continue'

        $dataSources = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName
        $dataSourceExists = $dataSources -contains $searchDataSourceName

        foreach ($index in $global:searchIndexes) {
            $indexName = $index.Name
            $indexSchema = $index.Schema

            $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
            $searchIndexExists = $searchIndexes -contains $indexName

            if ($searchIndexExists -eq $false) {
                New-SearchIndex -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchDatasourceName $searchDatasourceName -searchIndexSchema $indexSchema
            }
            else {
                Write-Host "Search Index '$indexName' already exists."
                Write-Log -message "Search Index '$indexName' already exists."
            }
        }

        #Start-Sleep -Seconds 15
        
        $dataSources = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName
        #$userAssignedIdentity = az identity show --resource-group $resourceGroupName --name $global:userAssignedIdentityName

        foreach ($appService in $global:appServices) {
            $appServiceName = $appService.Name
            if ($appService.Type -eq "Web") {
                #$appId = az webapp show --name $appService.Name --resource-group $resourceGroupName --query "id" --output tsv
                $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
                Write-Host "App ID for $($appServiceName): $appId"
            }
        }

        foreach ($searchDataSource in $global:searchDataSources) {
            $searchDataSourceName = $searchDataSource.Name
            $dataSourceExists = $dataSources -contains $searchDataSourceName

            if ($dataSourceExists -eq $false) {
                New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageAccountName $storageServiceName -appId $appId
            }
            else {
                Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
            }
        }

        foreach ($searchSkillSet in $searchSkillSets) {

            $searchSkillSetName = $searchSkillSet.Schema.Name

            $existingSearchSkillSets = Get-SearchSkillSets -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchSkillSetName $searchSkillSetName

            $searchSkillSetExists = $existingSearchSkillSets -contains $searchSkillSetName

            if ($searchSkillSetExists -eq $false) {

                Start-Sleep -Seconds 30
                New-SearchSkillSet -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchSkillSet $searchSkillSet -cognitiveServiceName $cognitiveServiceName
            }
            else {
                Write-Host "Search Skill Set '$searchSkillSetName' already exists."
                Write-Log -message "Search Skill Set '$searchSkillSetName' already exists."
            }
        }

        try {

            $filteredSearchIndexers = $global:searchIndexers | Where-Object { $_.Active -eq $true }

            foreach ($indexer in $filteredSearchIndexers) {
                $indexName = $indexer.IndexName
                $indexerName = $indexer.Name
                $indexerSchema = $indexer.Schema
                $indexerSkillSetName = $indexer.SkillSetName

                $searchDataSourceName = $indexer.DataSourceName

                $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName
                $searchIndexerExists = $searchIndexers -contains $indexerName

                if ($searchIndexerExists -eq $false) {
                    New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchIndexerName $indexerName -searchDatasourceName $searchDatasourceName -searchSkillSetName $indexerSkillSetName -searchIndexerSchema $indexerSchema -searchIndexerSchedule $searchIndexerSchedule
                }
                else {
                    Write-Host "Search Indexer '$indexerName' already exists."
                    Write-Log -message "Search Indexer '$indexerName' already exists."
                }

                Start-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName

            }

        }
        catch {
            Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    catch {
        Write-Error "Failed to create Search Service Index '$searchServiceIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Service Index '$searchServiceIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create a new skillset
function New-SearchSkillSet {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [psobject]$searchSkillSet,
        [string]$cognitiveServiceName
    )

    try {
        $ErrorActionPreference = 'Stop'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        # Might need to get search service API version from the parameters.json file

        $cognitiveServiceKey = az cognitiveservices account keys list --name $cognitiveServiceName --resource-group $resourceGroupName --query "key1" --output tsv

        $skillSetUrl = "https://$searchServiceName.search.windows.net/skillsets?api-version=$global:searchServiceAPiVersion"

        # Update the skillset file with the correct resource base name
        Update-SearchSkillSetFiles

        $fileContent = Get-Content -Path $searchSkillSet.File -Raw

        $updatedContent = $fileContent -replace $previousResourceBaseName, $resourceBaseName
        Set-Content -Path $searchSkillSet.File -Value $updatedContent

        # Convert the body hashtable to JSON
        $jsonBody = $searchSkillSet.Schema | ConvertTo-Json -Depth 10
        $jsonObject = $jsonBody | ConvertFrom-Json

        # Add the cognitive services key to the skillset
        $jsonObject.cognitiveServices = @{
            "@odata.type" = "#Microsoft.Azure.Search.CognitiveServicesByKey"
            "key"         = $cognitiveServiceKey
        }

        $jsonBody = $jsonObject | ConvertTo-Json -Depth 10

        Set-Content -Path $searchSkillSet.File -Value $jsonBody

        try {
            $ErrorActionPreference = 'Continue'

            Invoke-RestMethod -Uri $skillSetUrl -Method Post -Body $jsonBody -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }

            Write-Host "Skillset '$searchSkillSetName' created successfully."
            Write-Log -message "Skillset '$searchSkillSetName' created successfully."

            return true
        }
        catch {
            Write-Error "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return false
    }
}

# Function to create new Azure storage account
function New-StorageAccount {
    param (
        [string]$resourceGroupName,
        [string]$storageServiceName,
        [string]$location,
        [array]$existingResources
    )

    if ($existingResources -notcontains $storageServiceName) {

        try {
            az storage account create --name $storageServiceName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --output none

            $global:resourceCounter += 1

            Write-Host "Storage account '$storageServiceName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Storage account '$storageServiceName' created successfully. [$global:resourceCounter]"

            # Retrieve the storage account key
            $global:storageServiceAccountKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

            $global:storageServiceProperties.Credentials.AccountKey = $global:storageServiceAccountKey

            $global:KeyVaultSecrets.StorageServiceApiKey = $global:storageServiceAccountKey

            # Enable CORS
            az storage cors clear --account-name $storageServiceName --services bfqt
            az storage cors add --methods GET POST PUT --origins '*' --allowed-headers '*' --exposed-headers '*' --max-age 200 --services b --account-name $storageServiceName --account-key $storageAccessKey

            az storage container create --name $blobStorageContainerName --account-name $storageServiceName --account-key $global:storageServiceAccountKey --output none

        }
        catch {
            Write-Error "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {

        # Retrieve the storage account key
        $global:storageServiceAccountKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

        $global:storageServiceProperties.Credentials.AccountKey = $global:storageServiceAccountKey

        $global:KeyVaultSecrets.StorageServiceApiKey = $global:storageServiceAccountKey

        Write-Host "Storage account '$storageServiceName' already exists."
        Write-Log -message "Storage account '$storageServiceName' already exists."
    }
}

# Function to create a new subnet
function New-SubNet {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [psobject]$subnet,
        [array]$existingResources
    )

    $subnetName = $subnet.Name
    $subnetAddressPrefix = $subnet.AddressPrefix

    $subnetExists = Test-SubnetExists -resourceGroupName $resourceGroupName -vnetName $vnetName -subnetName $subnetName

    if ($subnetExists -eq $false) {
        try {
            az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName --address-prefixes $subnetAddressPrefix --delegations Microsoft.Web/hostingEnvironments --output none
            Write-Host "Subnet '$subnetName' created successfully."
            Write-Log -message "Subnet '$subnetName' created successfully."
        }
        catch {
            Write-Error "Failed to create Subnet '$subnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Subnet '$subnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Subnet '$subnetName' already exists."
        Write-Log -message "Subnet '$subnetName' already exists."
    }
}

# Function to create a new virtual network
function New-VirtualNetwork {
    param (
        [psobject]$virtualNetwork,
        [array]$existingResources
    )

    $vnetName = $virtualNetwork.Name

    if ($existingResources -notcontains $vnetName) {
        try {
            az network vnet create --resource-group $virtualNetwork.ResourceGroup --name $vnetName --output none

            $global:resourceCounter += 1

            Write-Host "Virtual Network '$vnetName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Virtual Network '$vnetName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
}

# Function to delete Azure resource groups
function Remove-AzureResourceGroup {

    param (
        [string]$resourceGroupName
    )

    $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName -location $location

    if ($resourceGroupExists -eq "true") {
        try {
            az group delete --name $resourceGroupName --yes --output none
            Write-Host "Resource group '$resourceGroupName' deleted."
            Write-Log -message "Resource group '$resourceGroupName' deleted."
        }
        catch {
            Write-Error "Failed to delete resource group '$resourceGroupName'."
            Write-Log -message "Failed to delete resource group '$resourceGroupName'."
        }
    }
    else {
        Write-Host "Resource group '$resourceGroupName' does not exist."
        Write-Log -message "Resource group '$resourceGroupName' does not exist."
    }
}

# Function to delete Machine Learning Workspace
function Remove-MachineLearningWorkspace {
    param (
        [string]$resourceGroupName,
        [string]$aiProjectName
    )

    try {
        az ml workspace delete --name $aiProjectName --resource-group $resourceGroupName --yes --output none
        Write-Host "Machine Learning Workspace '$aiProjectName' deleted."
        Write-Log -message "Machine Learning Workspace '$aiProjectName' deleted."
    }
    catch {
        Write-Error "Failed to delete Machine Learning Workspace '$aiProjectName'."
        Write-Log -message "Failed to delete Machine Learning Workspace '$aiProjectName'." -logFilePath
    }
}

# Function to reset deployment path
function Reset-DeploymentPath {

    $currentLocation = Get-Location
    $currentDirectory = Split-Path $currentLocation.Path -Leaf

    if ($currentDirectory -eq "deployment") {
        return $currentLocation.Path
    }

    do {
        Set-Location ../
        $currentLocation = Get-Location
        $currentDirectory = Split-Path $currentLocation.Path -Leaf

        Write-Host "Current location is: $currentLocation"
    } while (
        $currentDirectory -ne "deployment"
    )

    Write-Host "Deployment path reset to: $currentLocation"

    return $currentLocation.Path

}

# Function to reset search indexer
function Reset-SearchIndexer {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexerName
    )

    try {
        $ErrorActionPreference = 'Stop'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers/$searchIndexerName/reset?api-version=$global:searchServiceAPiVersion"

        Invoke-RestMethod -Uri $searchIndexerUrl -Method Post -Headers @{ "api-key" = $searchServiceApiKey }
        Write-Host "Indexer '$searchIndexerName' reset successfully."
        Write-Log -message "Indexer '$searchIndexerName' reset successfully."
    }
    catch {
        Write-Error "Failed to reset indexer '$searchIndexerName': $_"
        Write-Log -message "Failed to reset indexer '$searchIndexerName': $_"
    }
}

# Function to restore soft-deleted resources
function Restore-SoftDeletedResource {
    param(
        [string]$resourceName,
        [string]$resourceType,
        [string]$resourceGroupName,
        [string]$location,
        [string]$useRBAC,
        [string]$userAssignedIdentityName
    )

    switch ($resourceType) {
        "KeyVault" {
            # Code to restore Key Vault
            Write-Output "Restoring Key Vault: $resourceName"
            if ($useRBAC) {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Key Vault
                    az keyvault recover --name $resourceName --resource-group $resourceGroupName --location $location --output none

                    $global:resourceCounter += 1
                    Write-Host "Key Vault: '$resourceName' restored with Vault Access Policies. [$global:resourceCounter]"
                    Write-Log -message "Key Vault: '$resourceName' restored with Vault Access Policies. [$global:resourceCounter]"

                    # Assign RBAC roles to the managed identity
                    Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName -userPrincipalName $userPrincipalName -resourceGroupName $resourceGroupName -resourceName $resourceName
                }
                catch {
                    Write-Error "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Key Vault
                    az keyvault recover --name $resourceName --resource-group $resourceGroupName --location $location --output none

                    $global:resourceCounter += 1
                    Write-Host "Key Vault: '$resourceName' restored with Vault Access Policies. [$global:resourceCounter]"
                    Write-Log -message "Key Vault: '$resourceName' restored with Vault Access Policies. [$global:resourceCounter]"

                    Set-KeyVaultAccessPolicies -keyVaultName $resourceName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                }
                catch {
                    Write-Error "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }
        "StorageAccount" {
            # Code to restore Storage Account
            Write-Output "Restoring Storage Account: $resourceName"

        }
        "ApiManagementService" {
            # Code to restore Cognitive Service
            try {
                Write-Output "Restoring API Management Service: $resourceName"
                az resource update --ids $(az apim show --name $resourceName --resource-group $resourceGroupName --query 'id' --output tsv) --set properties.deletionRecoveryLevel="Recoverable"

                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "API Management Service '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "API Management Service '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore API Management Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore  API Management Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "AppService" {
            # Code to restore App Service
            Write-Output "Restoring App Service: $resourceName"

        }
        "CognitiveService" {
            # Code to restore Cognitive Service
            try {
                Write-Output "Restoring Cognitive Service: $resourceName"
                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "Cognitive Service '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Cognitive Service '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Cognitive Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Cognitive Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "ComputerVision" {
            # Code to restore Computer Vision Service
            try {
                Write-Output "Restoring Computer Vision Service: $resourceName"
                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "Computer Vision '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Computer Vision '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Computer Vision Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Computer Vision Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "AIHub" {
            # Code to restore Cognitive Service
            try {
                Write-Output "Restoring AI Hub: $resourceName"
                az cognitiveservices account recover --name $aiHubName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --kind AIHub --output none

                $global:resourceCounter += 1
                Write-Host "AI Hub '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "AI Hub '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore AI Hub '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore AI Hub '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "OpenAI" {
            # Code to restore OpenAI
            try {
                Write-Output "Restoring OpenAI: $resourceName"
                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "Azure OpenAI service '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Azure OpenAI service '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Azure OpenAI service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Azure OpenAI service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "ContainerRegistry" {
            # Code to restore Container Registry
            try {
                Write-Output "Restoring Container Registry: $resourceName"
                az ml registry recover --name $resourceName --resource-group $resourceGroupName --output none

                $global:resourceCounter += 1
                Write-Host "Container Registry '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Container Registry '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Container Registry '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Container Registry '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "AIServices" {
            # Code to restore AI Services
            try {
                Write-Output "Restoring AI Service: $resourceName"
                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName  --location $($location.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "AI Service '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "AI Service '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore AI Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore AI Service '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "DocumentIntelligence" {
            # Code to restore Document Intelligence
            try {
                Write-Output "Restoring Document Intelligence: $resourceName"
                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --kind FormRecognizer --output none

                $global:resourceCounter += 1
                Write-Host "Document Intelligence account '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Document Intelligence account '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Document Intelligence '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Document Intelligence '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "MachineLearningWorkspace" {
            # Code to restore Machine Learning Workspace
            try {
                Write-Output "Restoring Machine Learning Workspace: $resourceName"
                az ml workspace recover --name $resourceName --resource-group $resourceGroupName --output none

                $global:resourceCounter += 1
                Write-Host "Machine Learning Workspace '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "Machine Learning Workspace '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore Machine Learning Workspace '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Machine Learning Workspace '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        default {
            Write-Output "Resource type $resourceType is not supported for restoration."
        }
    }
}

# Function to set the directory location
function Set-DirectoryPath {
    param (
        [string]$targetDirectory
    )

    # Get the current directory
    $currentDirectory = Get-Location

    # Debug output to check the current directory
    #Write-Host "Current Directory: $currentDirectory"

    # Check if the current path is already equal to the root directory
    if ($currentDirectory.Path -notlike $targetDirectory) {
        # Check if the root directory exists
        if (Test-Path -Path $targetDirectory) {
            # Set location to the root directory
            Set-Location -Path $targetDirectory
            #Write-Host "Changed directory to root: $targetDirectory"
        }
        else {
            throw "Root directory '$targetDirectory' does not exist."
        }
    }
    else {
        #Write-Host "Already in the root directory: $targetDirectory"
        return
    }
}

# Function to set Key Vault access policies
function Set-KeyVaultAccessPolicies {
    param(
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$userPrincipalName)

    try {
        $ErrorActionPreference = 'Stop'
        # Set policy for the user
        az keyvault set-policy --name $keyVaultName --resource-group $resourceGroupName --upn $userPrincipalName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        Write-Host "Key Vault '$keyVaultName' policy permissions set for user: '$userPrincipalName'."
        Write-Log -message "Key Vault '$keyVaultName' policy permissions set for user: '$userPrincipalName'."
    }
    catch {
        Write-Error "Failed to set Key Vault '$keyVaultName' policy permissions for user '$userPrincipalName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to set Key Vault '$keyVaultName' policy permissions for user '$userPrincipalName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

#Create Key Vault Roles
function Set-KeyVaultRoles {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$userAssignedIdentityName,
        [string]$userPrincipalName,
        [bool]$useRBAC,
        [string]$location
    )

    # Set policy for the application
    try {
        $ErrorActionPreference = 'Stop'
        az keyvault set-policy --name $keyVaultName --resource-group $resourceGroupName --spn $userAssignedIdentityName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        Write-Host "Key Vault '$keyVaultName' policy permissions set for application: '$userAssignedIdentityName'."
        Write-Log -message "Key Vault '$keyVaultName' policy permissions set for application: '$userAssignedIdentityName'."
    }
    catch {
        Write-Error "Failed to set Key Vault '$keyVaultName' policy permissions for application: '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to set Key Vault '$keyVaultName' policy permissions for application: '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create secrets in Key Vault
function Set-KeyVaultSecrets {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName
    )
    # Loop through the array of secrets and store each one in the Key Vault
    foreach ($property in $global:KeyVaultSecrets.PSObject.Properties) {
        # Generate a random value for the secret
        #$secretValue = New-RandomPassword
        #$secretValue = "TESTSECRET"
        $secretName = $property.Name
        $secretValue = $property.Value

        try {
            $ErrorActionPreference = 'Stop'
            az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue --output none
            Write-Host "Secret: '$secretName' stored in Key Vault: '$keyVaultName'."
            Write-Log -message "Secret: '$secretName' stored in Key Vault: '$keyVaultName'."
        }
        catch {
            Write-Error "Failed to store secret '$secretName' in Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to store secret '$secretName' in Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
}

# Function to assign RBAC roles to a managed identity
function Set-RBACRoles {
    param (
        [string]$userAssignedIdentityName,
        [string]$resourceGroupName,
        [string]$userPrincipalName,
        [bool]$useRBAC
    )
    try {
        $ErrorActionPreference = 'Stop'
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

        # Retrieve the Object ID of the user-assigned managed identity
        $userAssignedIdentityObjectId = az identity show --name $userAssignedIdentityName --resource-group $resourceGroupName --query 'principalId' --output tsv

        az role assignment create --role "Key Vault Administrator" --assignee $userAssignedIdentityObjectId --scope $scope
        az role assignment create --role "Key Vault Secrets User" --assignee $userAssignedIdentityObjectId --scope $scope
        az role assignment create --role "Key Vault Certificate User" --assignee $userAssignedIdentityObjectId --scope $scope
        az role assignment create --role "Key Vault Crypto User" --assignee $userAssignedIdentityObjectId --scope $scope

        Write-Host "RBAC roles assigned to managed identity: '$userAssignedIdentityName'."
        Write-Log -message "RBAC roles assigned to managed identity: '$userAssignedIdentityName'."
    }
    catch {
        Write-Error "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to show existing resource deployment status
function Show-ExistingResourceProvisioningStatus {

    $jsonOutput = az resource list --resource-group $resourceGroupName  --output json

    $existingResources = $jsonOutput | ConvertFrom-Json

    foreach ($resource in $existingResources) {

        $resourceName = $resource.Name
        $resourceProvisioningState = $resource.provisioningState

        try {
            if ($resourceProvisioningState -eq "Succeeded") {
                Write-Host "Resource '$resourceName' provisioned successfully."
                Write-Log -message "Resource '$resourceName' provisioned successfully."
            }
            else {
                Write-Host "Resource '$resourceName' is in state: $resourceProvisioningState"
                Write-Log -message "Resource '$resourceName' is in state: $resourceProvisioningState"
            }
        }
        catch {
            Write-Error "Failed to get status for resource '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to get status for resource '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
}

# Function to split a GUID and return the first 8 characters
function Split-Guid {

    $newGuid = [guid]::NewGuid().ToString()
    $newGuid = $newGuid -replace "-", ""

    $newGuid = $newGuid.Substring(0, 5)

    return $newGuid
}

# Function to start the deployment
function Start-Deployment {

    $ErrorActionPreference = 'Stop'

    # Initialize the deployment path
    $global:deploymentPath = Reset-DeploymentPath

    $global:LogFilePath = "$global:deploymentPath/deployment.log"

    Set-Location -Path $global:deploymentPath

    # Initialize the existing resources array
    $global:existingResources = @()

    $global:resourceCounter = 0
    $global:resourceSuffix = 1

    # Initialize parameters
    $initParams = Initialize-Parameters -parametersFile $parametersFile

    if ($global:appDeploymentOnly -eq $false) {
    
        # Need to install VS Code extensions before executing main deployment script
        Install-Extensions

        # Install Azure CLI
        Install-AzureCLI

        # Login to Azure
        Initialize-Azure-Login

    }
    
    # Alphabetize the parameters object
    $parameters = Get-Parameters-Sorted -Parameters $initParams.parameters

    # Set the user-assigned identity name
    $global:userPrincipalName = $parameters.userPrincipalName

    Set-DirectoryPath -targetDirectory $global:deploymentPath
    az config set extension.use_dynamic_install=yes_without_prompt

    $logFilePath = "deployment.log"

    # Initialize the sequence number
    $sequenceNumber = 1

    # Check if the log file exists
    if (Test-Path $logFilePath) {
        # Read all lines from the log file
        $logLines = Get-Content $logFilePath
        # Initialize an array to hold all sequence numbers
        $sequenceNumbers = @()

        # Iterate through each line to find matching sequence numbers
        foreach ($line in $logLines) {
            if ($line -match "\*\*\* LOG SEQUENCE: (\d+) \*\*\*") {
                $sequenceNumbers += [int]$matches[1]
            }
        }

        # If we found any sequence numbers, get the highest one and increment it
        if ($sequenceNumbers.Count -gt 0) {
            $sequenceNumber = ($sequenceNumbers | Measure-Object -Maximum).Maximum + 1
        }
    }

    # Log the current sequence number
    $logMessage = "*** LOG SEQUENCE: $sequenceNumber ***"

    Write-Host $logMessage
    Add-Content -Path $logFilePath -Value $logMessage

    # Start the timer
    $startTime = Get-Date

    $startTimeMessage = "*** SCRIPT START TIME: $startTime ***"
    Add-Content -Path $logFilePath -Value $startTimeMessage

    $resourceGroupName = $global:resourceGroupName

    if ($appendUniqueSuffix -eq $true) {

        # Find a unique suffix
        Get-UniqueSuffix -resourceGroupName $resourceGroupName

        $global:resourceSuffix = 1

        $resourceGroupName = "$resourceGroupName-$global:resourceGuid-$global:resourceSuffix"
    }

    $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName -location $location

    if ($deleteResourceGroup -eq $true) {
        # Delete existing resource groups with the same name
        Remove-AzureResourceGroup -resourceGroupName $resourceGroupName

        $resourceGroupExists = $false
    }

    if ($resourceGroupExists -eq $true) {
        Write-Host "Resource Group '$resourceGroupName' already exists."
        Write-Log -message "Resource Group '$resourceGroupName' already exists." -logFilePath $logFilePath
    }
    else {
        New-ResourceGroup -resourceGroupName $resourceGroupName -location $location -resourceGroupExists $false
    }

    #return

    $existingResources = az resource list --resource-group $resourceGroupName --query "[].name" --output tsv | Sort-Object

    # Show-ExistingResourceProvisioningStatus
    
    if ($global:appDeploymentOnly -eq $true) {

        # Update configuration file for web frontend
        Update-ConfigFile - configFilePath "app/frontend/config.json" `
            -resourceBaseName $global:resourceBaseName `
            -resourceGroupName $resourceGroupName `
            -storageServiceName $storageServiceName `
            -searchServiceName $searchServiceName `
            -openAIAccountName $openAIAccountName `
            -aiServiceName $aiServiceName `
            -functionAppName $functionAppServiceName `
            -searchIndexers $global:searchIndexers `
            -searchIndexes $global:searchIndexes `
            -siteLogo $global:siteLogo
        
        # Deploy web app and function app services
        foreach ($appService in $appServices) {
            Deploy-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $global:storageAccountName -deployZipResources $true

            #New-App-Registration -appServiceName $appService.Name -resourceGroupName $resourceGroupName -keyVaultName $global:keyVaultName -appServiceUrl $appService.Url -appRegRequiredResourceAccess $global:appRegRequiredResourceAccess -exposeApiScopes $global:exposeApiScopes -parametersFile $global:parametersFile
        }

        return
    }

    Reset-DeploymentPath

    $userPrincipalName = "$($parameters.userPrincipalName)"

    #**********************************************************************************************************************
    # Create User Assigned Identity

    if ($existingResources -notcontains $userAssignedIdentityName) {
        New-ManagedIdentity -userAssignedIdentityName $userAssignedIdentityName -resourceGroupName $resourceGroupName -location $location -subscriptionId $subscriptionId
    }
    else {
        Write-Host "Identity '$userAssignedIdentityName' already exists."
        Write-Log -message "Identity '$userAssignedIdentityName' already exists."
    }
   
    New-Resources -aiProjectName $aiProjectName `
        -apiManagementService $apiManagementService `
        -appInsightsName $appInsightsName `
        -appServiceEnvironmentName $appServiceEnvironmentName `
        -appServicePlanName $appServicePlanName `
        -appServicePlanSku $appServicePlanSku `
        -blobStorageContainerName $blobStorageContainerName `
        -cognitiveServiceName $cognitiveServiceName `
        -computerVisionName $computerVisionName `
        -containerRegistryName $containerRegistryName `
        -documentIntelligenceName $documentIntelligenceName `
        -existingResources $existingResources `
        -keyVaultName $keyVaultName `
        -logAnalyticsWorkspaceName $logAnalyticsWorkspaceName `
        -managedEnvironmentName $managedEnvironmentName `
        -openAIAccountName $openAIAccountName `
        -portalDashboardName $portalDashboardName `
        -searchDatasourceName $searchDatasourceName `
        `searchIndexName $searchIndexName `
        `searchIndexerName $searchIndexerName `
        -searchServiceName $searchServiceName `
        -searchSkillSets $searchSkillSets `
        -storageAccountName $storageServiceName `
        -subNet $subNet `
        -userAssignedIdentityName $userAssignedIdentityName `
        -userPrincipalName $userPrincipalName `
        -virtualNetwork $virtualNetwork

    # Create new web app and function app services
    foreach ($appService in $appServices) {
        $appServiceName = $appService.Name
        if ($existingResources -notcontains $appService.Name) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageServiceName -deployZipResources $false

            $appId = az webapp show --name $appServiceName --resource-group $resourceGroupName --query "id" --output tsv
            Write-Host "App ID for $($appServiceName): $appId"
        }
    }

    if ($global:keyVaultPermissionModel -eq "RoleBased") {
        $useRBAC = $true
    }
    else {
        $useRBAC = $false
    }

    #**********************************************************************************************************************
    # Create Key Vault

    if ($existingResources -notcontains $keyVaultName) {
        New-KeyVault -keyVaultName $keyVaultName -resourceGroupName $global:resourceGroupName -location $location -useRBAC $useRBAC -userAssignedIdentityName $userAssignedIdentityName -userPrincipalName $userPrincipalName -existingResources $existingResources
    }
    else {
        Write-Host "Key Vault '$keyVaultName' already exists."
        Write-Log -message "Key Vault '$keyVaultName' already exists."
    }

    Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName -resourceGroupName $global:resourceGroupName -userPrincipalName $userPrincipalName -useRBAC $useRBAC

    # Filter appService nodes with type equal to 'function'
    $functionAppServices = $appServices | Where-Object { $_.type -eq 'Function' }

    # Return the first instance of the filtered appService nodes
    $functionAppService = $functionAppServices | Select-Object -First 1

    $functionAppServiceName = $functionAppService.Name

    $userAssignedIdentityName = $global:userAssignedIdentityName

    # Create a new AI Hub and Model
    New-AIHub -aiHubName $aiHubName -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources -userAssignedIdentityName $userAssignedIdentityName -containerRegistryName $containerRegistryName

    # Create a new AI Service
    New-AIService -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    Set-KeyVaultSecrets -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName

    # The CLI needs to be updated to allow Azure AI Studio projects to be created correctly.
    # This code will create a new workspace in ML Studio but not in AI Studio.
    # I am still having this code execute so that the rest of the script doesn't error out.
    # Once the enture script completes the code will delete the ML workspace.
    # This is admittedly a hack but it is the only way to get the script to work for now.

    # 2025-02-09 ADS: THE ABOVE COMMENT IS NO LONGER VALID. THE CLI HAS BEEN UPDATED TO ALLOW FOR AI STUDIO PROJECTS TO BE CREATED CORRECTLY.
    # I AM KEEPING THE COMMENT ABOVE FOR POSTERITY.

    # Create AI Studio AI Project / ML Studio Workspace

    New-MachineLearningWorkspace -resourceGroupName $resourceGroupName `
        -subscriptionId $global:subscriptionId `
        -aiHubName $aiHubName `
        -storageAccountName $storageServiceName `
        -containerRegistryName $global:containerRegistryName `
        -keyVaultName $keyVaultName `
        -appInsightsName $appInsightsName `
        -aiProjectName $aiProjectName `
        -userAssignedIdentityName $userAssignedIdentityName `
        -location $location `
        -existingResources $existingResources

    Start-Sleep -Seconds 10

    # Deploy AI Models
    Deploy-OpenAIModels -aiProjectName $aiProjectName -aiModels $aiModels -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -existingResources $existingResources

    # Add AI Service connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -aiProjectName $aiProjectName -resourceGroupName $resourceGroupName -resourceType "AIService" -serviceName $global:aiServiceName -serviceProperties $global:aiServiceProperties

    # Add OpenAI Service connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -aiProjectName $aiProjectName -resourceGroupName $resourceGroupName -resourceType "OpenAIService" -serviceName $global:openAIAccountName -serviceProperties $global:openAIServiceProperties

    # Add storage account connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -aiProjectName $aiProjectName -resourceGroupName $resourceGroupName -resourceType "StorageAccount" -serviceName $global:storageAccountName -serviceProperties $global:storageServiceProperties

    # Add search service connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -aiProjectName $aiProjectName -resourceGroupName $resourceGroupName -resourceType "SearchService" -serviceName $global:searchServiceName -serviceProperties $global:searchServiceProperties

    # Remove the Machine Learning Workspace
    #Remove-MachineLearningWorkspace -resourceGroupName $resourceGroupName -aiProjectName $aiProjectName

    # Update configuration file for web frontend
    Update-ConfigFile - configFilePath "app/frontend/config.json" `
        -resourceBaseName $resourceBaseName `
        -resourceGroupName $resourceGroupName `
        -storageAccountName $storageServiceName `
        -searchServiceName $searchServiceName `
        -openAIAccountName $openAIAccountName `
        -aiServiceName $aiServiceName `
        -functionAppName $functionAppServiceName `
        -searchIndexers $global:searchIndexers `
        -searchIndexes $global:searchIndexes `
        -siteLogo $global:siteLogo

    # Deploy web app and function app services
    foreach ($appService in $appServices) {
        if ($existingResources -notcontains $appService.Name) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageServiceName -deployZipResources $true
        }
            
        if ($appService.Name -ne $functionAppServiceName) {
            New-App-Registration -appServiceName $appService.Name -resourceGroupName $resourceGroupName -keyVaultName $global:keyVaultName -appServiceUrl $appService.Url -parametersFile $global:parametersFile
            
            $appServiceName = $appService.Name

            #$appId = az webapp show --name $appService.Name --resource-group $resourceGroupName --query "id" --output tsv
            $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
            
            Write-Host "App ID for $($appServiceName): $appId"

            $dataSources = Get-DataSources -resourceGroupName $resourceGroupName -searchServiceName $searchServiceName

            foreach ($searchDataSource in $global:searchDataSources) {
                $searchDataSourceName = $searchDataSource.Name
                $dataSourceExists = $dataSources -contains $searchDataSourceName

                if ($dataSourceExists -eq $false) {
                    New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageAccountName $storageServiceName -appId $appId
                }
                else {
                    Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                    Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
                }
            }
        }
    }

    # Set $previousFullResourceBaseName to the $currentResourceBaseName
    $previousFullResourceBaseName = $global:currentFullResourceBaseName

    $parametersFileContent = Get-Content -Path $parametersFile -Raw | ConvertFrom-Json

    $parametersFileContent.previousFullResourceBaseName = $previousFullResourceBaseName

    # Save the updated parameters back to the parameters.json file
    $parametersFileContent | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

    # End the timer
    $endTime = Get-Date
    $executionTime = $endTime - $startTime

    # Format the execution time
    $executionTimeFormatted = "{0:D2} HRS : {1:D2} MIN : {2:D2} SEC : {3:D3} MS" -f $executionTime.Hours, $executionTime.Minutes, $executionTime.Seconds, $executionTime.Milliseconds

    # Log the total execution time
    $executionTimeMessage = "*** TOTAL SCRIPT EXECUTION TIME: $executionTimeFormatted ***"

    Write-Host $executionTimeMessage
    Write-Log -message $executionTimeMessage -logFilePath $logFilePath

    Write-Host "TOTAL RESOURCES SUCCESSFULLY DEPLOYED: $global:resourceCounter"

    # Add a line break
    Add-Content -Path $logFilePath -Value ""
}

# Function to run search indexer
# https://learn.microsoft.com/en-us/azure/search/search-howto-run-reset-indexers?tabs=reset-indexer-rest
function Start-SearchIndexer {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexerName
    )

    # try {
    #     $ErrorActionPreference = 'Stop'

    #     $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

    #     $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers/$searchIndexerName/run?api-version=$global:searchServiceAPiVersion"

    #     Invoke-RestMethod -Uri $searchIndexerUrl -Method Post -Headers @{ "api-key" = $searchServiceApiKey }

    #     Write-Host "Search Indexer '$searchIndexerName' ran successfully."
    #     Write-Log -message "Search Indexer '$searchIndexerName' ran successfully." -logFilePath $global:LogFilePath
    # }
    # catch {
    #     Write-Error "Failed to run Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    #     Write-Log -message "Failed to run Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    # }
}

# Function to check if directory exists and create it if not
function Test-DirectoryExists {
    param (
        [string]$directoryPath
    )

    if (-not (Test-Path -Path $directoryPath -PathType Container)) {
        New-Item -ItemType Directory -Path $directoryPath
    }
}

# The Test-ResourceGroupExists function checks if a specified Azure resource group exists. If it does, the function appends a suffix to the resource group name and checks again. This process continues until a unique resource group name is found.
function Test-ResourceGroupExists {
    param (
        [string]$resourceGroupName,
        [string]$location
    )

    $resourceGroupExists = az group exists --resource-group $resourceGroupName --output tsv

    if ($resourceGroupExists -eq $true) {
        #Write-Host "Resource group '$resourceGroupName' exists."
        #Write-Log -message "Resource group '$resourceGroupName' exists." -logFilePath $global:LogFilePath

        return $true
    }
    else {
        #Write-Host "Resource group '$resourceGroupName' does not exist."
        #Write-Log -message "Resource group '$resourceGroupName' does not exist." -logFilePath $global:LogFilePath

        return $false
    }
}

# Function to check if a resource exists
function Test-ResourceExists {
    param (
        [string]$resourceName,
        [string]$resourceType,
        [string]$resourceGroupName
    )

    if ($global:ResourceTypes -contains $resourceType) {
        switch ($resourceType) {
            "Microsoft.Storage/storageAccounts" {
                $nameAvailable = az storage account check-name --name $resourceName --query "nameAvailable" --output tsv

                if ($nameAvailable -eq "true") {
                    $result = ""
                }
                else {
                    $result = $nameAvailable
                }
            }
            "Microsoft.KeyVault/vaults" {
                $result = az keyvault list --query "[?name=='$resourceName'].name" --output tsv
                $deletedVault = az keyvault list-deleted --query "[?name=='$resourceName'].name" --output tsv

                if (-not [string]::IsNullOrEmpty($deletedVault)) {
                    $result = $true
                }
            }
            "Microsoft.Sql/servers" {
                $result = az sql server list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.DocumentDB/databaseAccounts" {
                $result = az cosmosdb list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.Web/serverFarms" {
                $result = az appservice plan list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.Web/sites" {
                $result = az webapp list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.DataFactory/factories" {
                $result = az datafactory list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.ContainerRegistry/registries" {
                $result = az acr list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.CognitiveServices/accounts" {
                $result = az cognitiveservices account list --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.ApiManagement/service" {
                $result = az apim api list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.ContainerRegistry/" {
                $result = az container list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.Networks/virtualNetwork" {
                $result = az network vnet list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
            }
        }

        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Host "A resource named '$resourceName' already exists. Incrementing counter by 1 and trying again."
            return $true
        }
        else {
            Write-Host "A resource named '$resourceName' does not exist and is available for use."
            return $false
        }
    }
    else {
        # Check within the subscription
        $result = az resource list --name $resourceName --resource-type $resourceType --query "[].name" --output tsv
        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Host "A resource named '$resourceName' already exists. Incrementing counter by 1 and trying again."
            return $true
        }
        else {
            Write-Host  "A resource named '$resourceName' does not exist and is available for use."
            return $false
        }
    }
}

# Function to check if a subnet exists
function Test-SubnetExists {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [string]$subnetName
    )

    try {
        $subnet = az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName --query "name" --output tsv
        if ($subnet) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

# Function to update AI connection file
function Update-AIConnectionFile {
    param (
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$serviceName ,
        [string]$serviceProperties
    )

    $rootPath = Get-Item -Path (Get-Location).Path

    # Convert the serviceProperties string to a hashtable
    $serviceProperties = $serviceProperties.Trim('@{}')
    $servicePropertiesArray = $serviceProperties -split ';'
    $servicePropertiesHashtable = @{}

    foreach ($property in $servicePropertiesArray) {
        if ($property -match '^\s*(\w+)\s*=\s*(.*)\s*$') {
            $key = $matches[1]
            $value = $matches[2]
            $servicePropertiesHashtable[$key] = $value
        }
    }

    # Access the YamlFileName property
    $yamlFileName = $servicePropertiesHashtable['YamlFileName']

    $filePath = "$rootPath/$yamlFileName"

    switch ($resourceType) {
        "AIService" {
            $endpoint = "https://$serviceName.cognitiveservices.azure.com"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"
            $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiServiceName

            $content = @"
name: $serviceName
type: "azure_ai_services"
endpoint: $endpoint
api_key: $apiKey
ai_services_resource_id: $resourceId
"@
        }
        "OpenAIService" {
            $endpoint = "https://$serviceName.openai.azure.com"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"
            $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:openAIAccountName

            $content = @"
name: $serviceName
type: azure_open_ai
azure_endpoint: https://eastus.api.cognitive.microsoft.com/
api_key: $apiKey
"@
        }
        "SearchService" {
            $endpoint = "https://$serviceName.search.windows.net"
            #$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"

            $content = @"
name: $serviceName
type: "azure_ai_search"

endpoint: $endpoint
api_key: $apiKey
"@
        }
        "StorageAccount" {
            $containerName = $servicePropertiesHashtable["ContainerName"]
            $endpoint = "https://$storageServiceName.blob.core.windows.net/$containerName"
            #$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName"

            <#
 # {            $storageServiceKey = az storage account keys list `
                --resource-group $resourceGroupName `
                --account-name $storageServiceName `
                --query "[0].value" `
                --output tsv:Enter a comment or description}
#>

            $content = @"
name: $serviceName
type: azure_blob
url: $endpoint
container_name: $containerName
account_name: $storageServiceName
"@
        }
    }

    try {
        $content | Out-File -FilePath $yamlFileName -Encoding utf8 -Force
        Write-Host "File '$yamlFileName' created and populated."
        Write-Log -message "File '$yamlFileName' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to '$yamlFileName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to '$yamlFileName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    return $filePath
}

# Function to update the AI project file
function Update-AIProjectFile {
    param (
        [string]$resourceGroupName,
        [string]$aiProjectName,
        [string]$appInsightsName,
        [string]$userAssignedIdentityName,
        [string]$location,
        [string]$storageServiceName
    )

    $rootPath = Get-Item -Path (Get-Location).Path

    $filePath = "$rootPath/ai.project.yaml"

    $assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $global:userAssignedIdentityName --query 'principalId' --output tsv

    $content = @"
`$schema: https://azuremlschemas.azureedge.net/latest/workspace.schema.json`
name: $aiProjectName
description: This configuration specifies a workspace configuration with existing dependent resources
display_name: $aiProjectName
location: $location
application_insights: $appInsightsName
identity:
  type: user_assigned
  tenant_id: $global:tenantId
  principal_id: $assigneePrincipalId
  user_assigned_identities:
    ${userAssignedIdentityName}: {}
#tags:
#  purpose: Azure AI Hub Project
"@

    try {
        $content | Out-File -FilePath $filePath -Encoding utf8 -Force
        Write-Host "File 'ai.project.yaml' created and populated."
        Write-Log -message "File 'ai.project.yaml' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to 'ai.project.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to 'ai.project.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
    return $filePath

}

# Function to update Azure service properties
function Update-AzureServiceProperties {
    params(
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$serviceName,
        [string]$serviceProperties
    )

}

# Function to update the config file
function Update-ConfigFile {
    param (
        [string]$configFilePath,
        [string]$resourceGroupName,
        [string]$storageServiceName,
        [string]$searchServiceName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$searchVectorIndexName,
        [string]$searchVectorIndexerName,
        [string]$openAIAccountName,
        [string]$aiServiceName,
        [psobject]$apiManagementService,
        [string]$functionAppName,
        [string]$siteLogo
    )

    try {

        $fullResourceBaseName = $global:newFullResourceBaseName

        $appServiceName = "app-$fullResourceBaseName"
        $functionAppName = "func-$fullResourceBaseName"

        $storageKey = az storage account keys list --resource-group  $global:resourceGroupName --account-name $global:storageAccountName --query "[0].value" --output tsv
        $startDate = (Get-Date).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $expirationDate = (Get-Date).AddYears(1).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $searchApiKey = az search admin-key show --resource-group $global:resourceGroupName --service-name $global:searchServiceName --query "primaryKey" --output tsv
        $openAIApiKey = az cognitiveservices account keys list --resource-group  $global:resourceGroupName --name $global:openAIAccountName --query "key1" --output tsv
        $aiServiceKey = az cognitiveservices account keys list --resource-group  $global:resourceGroupName --name $aiServiceName --query "key1" --output tsv
        $functionApiKey = az functionapp keys list --resource-group  $global:resourceGroupName --name $functionAppName --query "functionKeys.default" --output tsv
        $functionAppUrl = az functionapp show -g  $global:resourceGroupName -n $functionAppName --query "defaultHostName" --output tsv
        
        #$apimSubscriptionKey = az apim api list --resource-group $resourceGroupName --service-name $global:apiManagementService.Name --query "SubscriptionKey" --output tsv
        #$global:applicationManagementService.SubscriptionKey = $apimSubscriptionKey

        $appRegistrationClientId = az ad app list --filter "displayName eq '$appServiceName'" --query "[].appId" --output tsv

        # https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli
        $storageSAS = az storage account generate-sas --account-name $storageServiceName --account-key $storageKey --resource-types co --services btfq --permissions rwdlacupiytfx --expiry $expirationDate --https-only --output tsv
        #Write-Output "Generated SAS Token: $storageSAS"

        # URL-decode the SAS token
        #$decodedSAS = [System.Web.HttpUtility]::UrlDecode($storageSAS)
        #Write-Output "Decoded SAS Token: $decodedSAS"

        # Extract and decode 'se' and 'st' parameters
        if ($storageSAS -match "se=([^&]+)") {
            $encodedSe = $matches[1]
            $decodedSe = [System.Web.HttpUtility]::UrlDecode($encodedSe)
            $storageSAS = $storageSAS -replace "se=$encodedSe", "se=$decodedSe"
        }
        if ($storageSAS -match "st=([^&]+)") {
            $encodedSt = $matches[1]
            $decodedSt = [System.Web.HttpUtility]::UrlDecode($encodedSt)
            $storageSAS = $storageSAS -replace "st=$encodedSt", "st=$decodedSt"
        }

        #Write-Output "Modified SAS Token: $storageSAS"

        $storageUrl = "https://$storageServiceName.blob.core.windows.net/content?comp=list&include=metadata&restype=container&$storageSAS"

        # Extract the 'sig' parameter value from the SAS token
        if ($storageSAS -match "sig=([^&]+)") {
            $storageSASKey = $matches[1]
        }
        else {
            Write-Error "Failed to extract 'sig' parameter from SAS token."
            return
        }

        if ($storageSAS -match "ss=([^&]+)") {
            $storageSS = $matches[1]
        }
        else {
            Write-Error "Failed to extract 'ss' parameter from SAS token."
            return
        }

        if ($storageSAS -match "sp=([^&]+)") {
            $storageSP = $matches[1]
        }
        else {
            Write-Error "Failed to extract 'ss' parameter from SAS token."
            return
        }

        if ($storageSAS -match "srt=([^&]+)") {
            $storageSRT = $matches[1]
        }
        else {
            Write-Error "Failed to extract 'ss' parameter from SAS token."
            return
        }

        $configFilePath = "app/frontend/config.json"

        # Read the config file
        $config = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

        # Update the config with the new key-value pair
        # Update the config with the new key-value pair
        $config.AZURE_OPENAI_SERVICE_API_KEY = $aiServiceKey
        $config.AZURE_FUNCTION_API_KEY = $functionApiKey
        $config.AZURE_FUNCTION_APP_NAME = $functionAppName
        $config.AZURE_FUNCTION_APP_URL = "https://$functionAppUrl"
        $config.AZURE_APIM_SERVICE_NAME = $global:apiManagementService.Name

        if ($global:apiManagementService.SubscriptionKey) {
            $config.AZURE_APIM_SUBSCRIPTION_KEY = $global:apiManagementService.SubscriptionKey
        }

        $config.AZURE_APP_REG_CLIENT_APP_ID = $appRegistrationClientId
        $config.AZURE_APP_SERVICE_NAME = $appServiceName
        $config.AZURE_KEY_VAULT_NAME = $global:keyVaultName
        $config.AZURE_KEY_VAULT_API_VERSION = $global:keyVaultApiVersion
        $config.AZURE_RESOURCE_BASE_NAME = $global:resourceBaseName
        $config.AZURE_SEARCH_API_KEY = $searchApiKey
        $config.AZURE_SEARCH_API_VERSION = $global:searchServiceApiVersion
        $config.AZURE_SEARCH_INDEX_NAME = $searchIndexName
        $config.AZURE_SEARCH_INDEXER_NAME = $searchIndexerName
        $config.AZURE_SEARCH_SEMANTIC_CONFIG = "vector-profile-srch-index-$fullResourceBaseName-semantic-configuration" -join ""
        $config.AZURE_SEARCH_SERVICE_NAME = $global:searchServiceName
        $config.AZURE_SEARCH_VECTOR_INDEX_NAME = $searchVectorIndexName
        $config.AZURE_SEARCH_VECTOR_INDEXER_NAME = $searchVectorIndexerName
        $config.AZURE_STORAGE_ACCOUNT_NAME = $global:storageAccountName
        $config.AZURE_STORAGE_API_VERSION = $global:storageApiVersion
        $config.AZURE_STORAGE_FULL_URL = $storageUrl
        $config.AZURE_STORAGE_KEY = $storageKey
        $config.AZURE_STORAGE_SAS_TOKEN.SE = $expirationDate
        $config.AZURE_STORAGE_SAS_TOKEN.SIG = $storageSASKey
        $config.AZURE_STORAGE_SAS_TOKEN.SP = $storageSP
        $config.AZURE_STORAGE_SAS_TOKEN.SRT = $storageSRT
        $config.AZURE_STORAGE_SAS_TOKEN.SS = $storageSS
        $config.AZURE_STORAGE_SAS_TOKEN.ST = $startDate
        $config.AZURE_SUBSCRIPTION_ID = $global:subscriptionId
        $config.OPENAI_ACCOUNT_NAME = $global:openAIAccountName
        $config.OPENAI_API_KEY = $openAIApiKey
        $config.OPENAI_API_VERSION = $global:openAIApiVersion
        $config.SEARCH_AZURE_OPENAI_MODEL = $global:searchAzureOpenAIModel
        $config.SEARCH_PUBLIC_INTERNET_RESULTS = $global:searchPublicInternetResults
        $config.SITE_LOGO = $global:siteLogo

        # Clear existing values in SEARCH_INDEXES
        $config.SEARCH_INDEXES = @()

        $vectorSearchIndexName = $null

        # Loop through the search indexes collection from global:searchIndexes
        foreach ($searchIndex in $global:searchIndexes) {
            $config.SEARCH_INDEXES += $searchIndex

            if ($searchIndex.Name -match "vector") {
                $vectorSearchIndexName = $searchIndex.Name
            }
        }

        # Clear existing values in SEARCH_INDEXERS
        $config.SEARCH_INDEXERS = @()

        # Loop through the search indexes collection from global:searchIndexes
        foreach ($searchIndexer in $global:searchIndexers) {
            $config.SEARCH_INDEXERS += $searchIndexer
        }

        $config.DATA_SOURCES = @(
            @{
                "type"       = "azure_search"
                "parameters" = @{
                    "endpoint"         = "https://$global:searchServiceName.search.windows.net"
                    "index_name"       = "$vectorSearchIndexName"
                    "role_information" = ""
                    "authentication"   = @{
                        "type" = "api_key"
                        "key"  = "$searchApiKey"
                    }
                }
            }
        )
            
        # Define the AZURE_OPENAI_REQUEST_BODY
        #region AZURE_OPENAI_REQUEST_BODY
        $config.AZURE_OPENAI_REQUEST_BODY = @{
            "stop"              = $null
            "messages"          = @(
                @{
                    "role"             = "system"
                    "role_information" = "You are a helpful assistant"
                    "content"          = ""
                }
                @{
                    "role"    = "user"
                    "content" = ""
                }
            )
            "presence_penalty"  = 0
            "top_p"             = 0.95
            "temperature"       = 0.7
            "frequency_penalty" = 0
            "data_sources"      = @(
                @{
                    "type"       = "azure_search"
                    "parameters" = @{
                        "endpoint"       = "https://$global:searchServiceName.search.windows.net"
                        "index_name"     = "$vectorSearchIndexName"
                        "authentication" = @{
                            "type" = "api_key"
                            "key"  = "$searchApiKey"
                        }
                    }
                }
            )
            "stream"            = $false
            "max_tokens"        = 800
        }
        #endregion

        # Clear existing values in AI_MODELS
        $config.AI_MODELS = @()

        #$aiServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
        $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiServiceName

        # Loop through the AI models collection from global:aiModels
        foreach ($aiModel in $global:aiModels) {
            $aiModelDeploymentName = $aiModel.DeploymentName
            $aiModelType = $aiModel.Type
            $aiModelVersion = $aiModel.ModelVersion
            $aiModelApiVersion = $aiModel.ApiVersion
            $aiModelFormat = $aiModel.Format
            $aiModelSkuName = $aiModel.Sku.Name
            $aiModelSkuCapacity = $aiModel.Sku.Capacity
            $aiModelPath = $aiModel.Path
            $aiModelKeyWordTriggers = $aiModel.KeyWordTriggers

            $config.AI_MODELS += @{
                "DeploymentName"  = $aiModelDeploymentName
                "Type"            = $aiModelType
                "ModelVersion"    = $aiModelVersion
                "ApiKey"          = $apiKey
                "ApiVersion"      = $aiModelApiVersion
                "Format"          = $aiModelFormat
                "Sku"             = @{
                    "Name"     = $aiModelSkuName
                    "Capacity" = $aiModelSkuCapacity
                }
                "Path"            = $aiModelPath
                "KeyWordTriggers" = $aiModelKeyWordTriggers
            }
        }

        #$config.OPEN_AI_KEY = az cognitiveservices account keys list --resource-group $resourceGroupName --name $openAIName --query "key1" --output tsv

        # Convert the updated object back to JSON format
        $updatedConfig = $config | ConvertTo-Json -Depth 10

        # Write the updated JSON back to the file
        $updatedConfig | Set-Content -Path $configFilePath

        Write-Host "Config.json file updated successfully."
        Write-Log -message "Config.json file updated successfully."
    }
    catch {
        Write-Host "Failed to update the Config.json file: : (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to update the Config.json file: : (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to update ML workspace connection file
function Update-ContainerRegistryFile {
    param (
        [string]$resourceGroupName,
        [string]$containerRegistryName,
        [string]$location
    )

    $rootPath = Get-Item -Path (Get-Location).Path

    $filePath = "$rootPath/container.registry.yaml"

    $existingContent = Get-Content -Path $filePath

    $updatedContent = $existingContent -replace $global:previousResourceBaseName, $global:resourceBaseName

    Set-Content -Path $filePath -Value $updatedContent

    $locationNoSpaces = $location.ToLower() -replace " ", ""

    $content = @"
name: $containerRegistryName
tags:
  description: Basic registry with one primary region and to additional regions
location: $locationNoSpaces
replication_locations:
  - location: $locationNoSpaces
  - location: eastus2
  - location: westus
"@

    try {
        $content | Out-File -FilePath $filePath -Encoding utf8 -Force
        Write-Host "File 'container.registry.yaml' created and populated."
        Write-Log -message "File 'container.registry.yaml' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to 'container.registry.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to 'container.registry.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
    return $filePath
}

# Function to update ML workspace connection file
function Update-MLWorkspaceFile {
    param (
        [string]$resourceGroupName,
        [string]$containerRegistryName,
        [string]$aiProjectName,
        [string]$aiHubName,
        [string]$location,
        [string]$subscriptionId,
        [string]$storageServiceName,
        [string]$appInsightsName,
        [string]$keyVaultName,
        [string]$userAssignedIdentityName
    )

    $rootPath = Get-Item -Path (Get-Location).Path

    $filePath = "${rootPath}/ml.workspace.yaml"

    #$userAssignedIdentityName = $global:userAssignedIdentityName

    $assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $global:userAssignedIdentityName --query 'principalId' --output tsv

    #`$schema: https://azuremlschemas.azureedge.net/latest/workspace.schema.json`

    $content = @"
`$schema: https://azuremlschemas.azureedge.net/latest/workspace.schema.json`
name: $aiProjectName
resource_group: $resourceGroupName
location: $location
display_name: $aiProjectName
description: This configuration specifies a workspace configuration with existing dependent resources
storage_account: $storageServiceName
container_registry: $containerRegistryName
key_vault: $keyVaultName
application_insights: $appInsightsName
workspace_hub: $aiHubName
identity:
  type: user_assigned
  tenant_id: $global:tenantId
  principal_id: $assigneePrincipalId
  user_assigned_identities:
    ${userAssignedIdentityName}: {}
#tags:
#  purpose: Azure AI Hub Project
"@

    try {
        $content | Out-File -FilePath $filePath -Encoding utf8 -Force
        Write-Host "File 'ml.workspace.yaml' created and populated."
        Write-Log -message "File 'ml.workspace.yaml' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to 'ml.workspace.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to 'ml.workspace.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
    return $filePath
}

# Function to update parameters.json with new values from app registration
function Update-ParametersFile-AppRegistration {
    param (
        [string]$parametersFile,
        [string]$appId,
        [string]$appUri
    )

    try {
        $ErrorActionPreference = 'Stop'

        # Read the existing parameters.json file
        $parameters = Get-Content -Path $parametersFile -Raw | ConvertFrom-Json

        # Update the parameters with new values
        $parameters.appRegistrationClientId = $appId

        # Convert the updated parameters back to JSON
        $updatedParametersJson = $parameters | ConvertTo-Json -Depth 10

        # Write the updated JSON back to the parameters.json file
        Set-Content -Path $parametersFile -Value $updatedParametersJson

        Write-Host "parameters.json updated successfully."
        Write-Log -message "parameters.json updated successfully."
    }
    catch {
        Write-Error "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to update the parameters.json file with the latest API versions. NOTE: This function is not currently used.
function Update-ParameterFileApiVersions {

    # NOTE: Code below seems to get older API versions for some reason. This function will not be used until I can investigate further.

    # Load parameters from the JSON file
    $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Get the latest API versions in order to Update the parameters.json file
    $storageApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Storage" -resourceType "storageAccounts"
    $openAIApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    $searchServiceAPIVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Search" -resourceType "searchServices"
    $aiServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    $cognitiveServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"

    $parametersObject.storageApiVersion = $storageApiVersion
    $parametersObject.openAIApiVersion = $openAIApiVersion
    $parametersObject.searchServiceAPIVersion = $searchServiceAPIVersion
    $parametersObject.aiServiceApiVersion = $aiServiceApiVersion
    $parametersObject.cognitiveServiceApiVersion = $cognitiveServiceApiVersion

    # Convert the updated parameters object back to JSON and save it to the file
    $parametersObject | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

}

# Function to udpate the configuration file with new resource base name.
function Update-ResourceBaseName() {
    param (
        [string]$newResourceBaseName = "copilot-demo"
    )

    # Read the parameters.json file
    $parametersFileContent = Get-Content -Path $parametersFile -Raw | ConvertFrom-Json

    # Get the currentResourceBaseName from the parameters file
    $currentFullResourceBaseName = $parametersFileContent.currentFullResourceBaseName

    $global:currentFullResourceBaseName = $currentFullResourceBaseName

    $fullResourceBaseName = $parametersFileContent.fullResourceBaseName
    
    $resourceSuffixCounter = $parametersFileContent.resourceSuffixCounter

    $newResourceSuffixCounter = Increment-FormattedNumber -formattedNumber $resourceSuffixCounter
    $global:newFullResourceBaseName = "$newResourceBaseName-$newResourceSuffixCounter"

    $parametersFileContent.resourceSuffixCounter = $newResourceSuffixCounter
    $parametersFileContent.fullResourceBaseName = $newFullResourceBaseName

    # Update the previousResourceBaseName in the parameters file with the value stored in currentResourceBaseName
    $parametersFileContent.resourceBaseName = $newResourceBaseName

    $newFullResourceBaseNameUpperCase = $newFullResourceBaseName.ToUpper()
    $parametersFileContent.resourceGroupName = "RG-$newFullResourceBaseNameUpperCase"

    $parametersFileContent | ForEach-Object {
        $_.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [string]) {
                $_.Value = $_.Value -replace [regex]::Escape($fullResourceBaseName), $newFullResourceBaseName
            }
        }
    }

    # Save the updated parameters back to the parameters.json file
    $parametersFileContent | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

    $newFullResourceBaseNameNoHyphen = $newFullResourceBaseName -replace "-", ""
    $currentFullResourceBaseNameNoHyphen = $fullResourceBaseName -replace "-", ""

    # Replace all instances of currentResourceBaseName with the value stored in $resourceBaseName parameter
    $fileContent = Get-Content -Path $parametersFile

    $fileContent = $fileContent -replace $currentFullResourceBaseNameNoHyphen, $newFullResourceBaseNameNoHyphen
    $fileContent = $fileContent -replace $currentFullResourceBaseName, $newFullResourceBaseName

    Set-Content -Path $parametersFile -Value $fileContent
}

# Function to update search index files (not currently used)
function Update-SearchIndexFiles {

    $searchIndexFiles = @("search-index-schema-template.json,search-indexer-schema-template.json,vector-search-index-schema-template.json,vector-search-indexer-schema-template.json,embeddings-search-index-schema-template.json,embeddings-search-indexer-schema-template.json,sharepoint-search-index-schema-template.json,sharepoint-search-indexer-schema-template.json" )

    foreach ($fileName in $searchIndexFiles) {
        $searchIndexFilePath = $fileName -replace "-template", ""

        $content = Get-Content -Path $fileName

        $updatedContent = $content -replace $global:previousFullResourceBaseName, $global:fullResourceBaseName

        Set-Content -Path $searchIndexFilePath -Value $updatedContent
    }
}

# Function to update search skill set files
function Update-SearchSkillSetFiles {
    foreach ($searchSkillSet in $searchSkillSets) {

        $content = Get-Content -Path $searchSkillSet.File

        $updatedContent = $content -replace $global:previousFullResourceBaseName, $global:fullResourceBaseName

        Set-Content -Path $searchSkillSet.File -Value $updatedContent
    }
}

# Function to write messages to a log file
function Write-Log {
    param (
        [string]$message,
        [string]$logFilePath = "deployment.log"
    )

    $currentDirectory = (Get-Location).Path

    Set-DirectoryPath -targetDirectory $global:deploymentPath

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"

    Add-Content -Path $logFilePath -Value $logMessage

    Set-DirectoryPath -targetDirectory $currentDirectory
}


#**********************************************************************************************************************
# Main script
#**********************************************************************************************************************


# Start the deployment
Start-Deployment

#**********************************************************************************************************************
# End of script
