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
    # 4. storageServiceName
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
    [string]$resourceBaseName = "copilot-demo",
    [string]$subscriptionId = "bfb3a031-f26f-4783-b278-60173de9ccf4"
)

# Prompt the user for the subscriptionId if not provided
if (-not $subscriptionId) {
    $subscriptionId = Read-Host "Please enter your Azure subscription ID"
}

# Function to Generate visual map of all resources
function Build-ResourceList {
    param
    (
        [psobject]$parametersObject
    )

    Write-Host "Executing Build-ResourceList function..." -ForegroundColor Magenta

    # Build the list of resources using the new schema
    $resources = @(
        @{ Name = $global:aiService.Name; Type = "Cognitive Services"; Status = "Pending" }
        @{ Name = $global:apiManagementService.Name; Type = "API Management"; Status = "Pending" }
        @{ Name = $global:appInsightsService.Name; Type = "Application Insights"; Status = "Pending" }
        @{ Name = $global:appServiceEnvironment.Name; Type = "App Service Environment"; Status = "Pending" }
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
        @{ Name = $global:resourceGroup.Name; Type = "Resource Group"; Status = "Pending" }
        @{ Name = $global:searchService.Name; Type = "Search Service"; Status = "Pending" }
        @{ Name = $global:storageService.Name; Type = "Storage Account"; Status = "Pending" }
        @{ Name = $global:userAssignedIdentity.Name; Type = "User Assigned Identity"; Status = "Pending" }
        @{ Name = $global:virtualNetwork.Name; Type = "Virtual Network"; Status = "Pending" }
    )

    $jsonOutput = $resources | ConvertTo-Json
    $resourceTable = $jsonOutput | ConvertFrom-Json

    #foreach ($resource in $resources) {
    #    $global:ResourceList += [PSCustomObject]@{ Name = $resource.Name; Type = $resource.Type; Status = $resource.Status }
    #}
    
    Write-Host "Parameters initialized.`n"

    $resourceTable | Format-Table -AutoSize
}

# Function to check if user is logged in to Azure
function Check-Azure-Login {

    Write-Host "Executing Check-Azure-Login function..." -ForegroundColor Magenta

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

    #Write-Host "Executing ConvertTo_ProperCase function..." -ForegroundColor Magenta

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
        [psobject]$appService,
        [string]$resourceGroupName,
        [bool]$deployZipResources,
        [array]$existingResources
    )

    Write-Host "Executing Deploy-AppService function..." -ForegroundColor Magenta

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
                
                # Get the operating system
                $os = Get-OperatingSystem

                # Compress the app code

                if ($os -eq "Windows") {
                    Compress-Archive -Path * .env -DestinationPath $zipFilePath -Force
                }
                else {
                    zip -r $zipFilePath * .env
                }
                
                if ($appService.Type -eq "Web") {
                    # Deploy the web app
                    #az webapp deployment source config-zip --name $appServiceName --resource-group $resourceGroup.Name --src $zipFilePath
                    az webapp deploy --src-path $zipFilePath --name $appServiceName --resource-group $resourceGroupName --type zip
                }
                else {
                    # Deploy the function app
                    az functionapp deployment source config-zip --name $appServiceName --resource-group $resourceGroupName --src $zipFilePath

                    $searchServiceKeys = az search admin-key show --resource-group $resourceGroupName --service-name $global:searchService.Name --query "primaryKey" --output tsv
                    $searchServiceApiKey = $searchServiceKeys
                    $searchIndexName = $global:searchIndexes | Where-Object { $_ -like "vector*" }

                    $envVariables = @(
                        @{ name = "AZURE_SEARCH_API_KEY"; value = $searchServiceApiKey },
                        @{ name = "AZURE_SEARCH_SERVICE_NAME"; value = $global:searchService.Name },
                        @{ name = "AZURE_SEARCH_INDEX"; value = $searchIndexName }
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
        [psobject]$aiProject,
        [string]$aiServiceName,
        [array]$aiModels,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    Write-Host "Executing Deploy-OpenAIModels function..." -ForegroundColor Magenta

    foreach ($aiModel in $aiModels) {
        $aiModelDeploymentName = $aiModel.DeploymentName
        $aiModelType = $aiModel.Type
        $aiModelVersion = $aiModel.ModelVersion
        $aiModelFormat = $aiModel.Format
        $aiModelSkuName = $aiModel.Sku.Name
        $aiModelSkuCapacity = $aiModel.Sku.Capacity
   
        try {

            $ErrorActionPreference = 'SilentlyContinue'

            # Check if the deployment already exists
            $deploymentExists = az cognitiveservices account deployment list --resource-group $resourceGroupName --name $aiServiceName --query "[?name=='$aiModelDeploymentName']" --output tsv

            if ($deploymentExists) {
                Write-Host "Model deployment '$aiModelDeploymentName' for '$aiServiceName' already exists." -ForegroundColor Blue
                Write-Log -message "Model deployment '$aiModelDeploymentName' for '$aiServiceName' already exists."
            }
            else {
                try {
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
                        Write-Host "Model '$aiModelDeploymentName' for '$aiServiceName' deployed successfully." -ForegroundColor Green
                        Write-Log -message "Model '$aiModelDeploymentName' for '$aiServiceName' deployed successfully." -logFilePath $global:LogFilePath
                    }
                }
                catch {
                    Write-Error "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }


            }
        }
        catch {
            Write-Error "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Model deployment '$aiModelDeploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            #Remove-MachineLearningWorkspace -resourceGroupName $resourceGroup.Name -aiProjectName $aiProjectName
        }
    }
}

# function to get the app root directory
function Find-AppRoot {
    param (
        [string]$currentDirectory
    )

    Write-Host "Executing Find-AppRoot function..." -ForegroundColor Magenta

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

    #Write-Host "Executing Format-ErrorInfo function..." -ForegroundColor Magenta

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

    #Write-Host "Executing Format-CustomErrorInfo function..." -ForegroundColor Magenta

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
    
    Write-Host "Executing Get-Azure-Tenants function..." -ForegroundColor Yellow

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
        
        [string]$cognitiveServiceName
    )

    Write-Host "Executing Get-CognitiveServicesApiKey function..." -ForegroundColor Yellow

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

# Function to check if a Key Vault secret exists
function Get-KeyVaultSecret {
    param(
        [string]$keyVaultName,
        [string]$secretName
    )

    Write-Host "Executing Get-KeyVaultSecret function..." -ForegroundColor Yellow

    try {
        $secret = az keyvault secret show --vault-name $keyVaultName --name $secretName --query "value" --output tsv
        Write-Host "Secret: '$secretName' already exists." -ForegroundColor Blue
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

    Write-Host "Executing Get-LatestApiVersion function..." -ForegroundColor Magenta

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

    Write-Host "Executing Get-LatestDotNetRuntime function..." -ForegroundColor Magenta

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
function Get-ParametersSorted {
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Parameters
    )

    #Write-Host "Executing Get-Parameters-Sorted function..." -ForegroundColor Magenta

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

# Function to test if datasource exists
function Get-SearchDataSources {
    param(
        [string]$dataSourceName,
        [string]$resourceGroupName,
        [string]$searchServiceName
    )

    Write-Host "Executing Get-DataSources function..." -ForegroundColor Yellow

    # Get the admin key for the search service
    #
    $apiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv

    $searchRestApiVersion = $global:searchRestApiVersion

    $uri = "https://$searchServiceName.search.windows.net/datasources?api-version=$searchRestApiVersion"

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

# Function to check if a search index exists
function Get-SearchIndexes {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$subscriptionId
    )

    Write-Host "Executing Get-SearchIndexes function..." -ForegroundColor Yellow

    $subscriptionId = $global:subscriptionId

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv
    $searchRestApiVersion = $global:searchRestApiVersion

    $uri = "https://$searchServiceName.search.windows.net/indexes?api-version=$searchRestApiVersion"

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
        [string]$resourceGroupName
    )

    Write-Host "Executing Get-SearchIndexers function..." -ForegroundColor Yellow

    $subscriptionId = $global:subscriptionId

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv
    $searchRestApiVersion = $global:searchRestApiVersion

    $uri = "https://$searchServiceName.search.windows.net/indexers?api-version=$searchRestApiVersion"

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

    Write-Host "Executing Get-SearchSkillSets function..." -ForegroundColor Yellow

    $subscriptionId = $global:subscriptionId

    $accessToken = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query primaryKey --output tsv
    $searchRestApiVersion = $global:searchRestApiVersion

    $uri = "https://$searchServiceName.search.windows.net/skillsets?api-version=$searchRestApiVersion"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "api-key" = "$accessToken" }
        $skillsets = $response.value | Select-Object -ExpandProperty name
        return $skillsets
    }
    catch {
        Write-Error "Failed to query search skillsets: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        return $false
    }
}

# Function to find a unique suffix and create resources
function Get-UniqueSuffix {
    param
    (
        [string]$resourceGroupName,
        [bool]$useGuid = $false
    )

    Write-Host "Executing Get-UniqueSuffix function..." -ForegroundColor Yellow

    #$parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    do {
        foreach ($resource in $global:resourceList) {

            $newResourceName = $resource.Item.Name

            $resource.CurrentName = $resource.Item.Name

            if ($useGuid) {
                $newResourceName = "$($newResourceName)-$resourceGuid-$global:resourceSuffix"
            }
            else {
                $newResourceName = "$($newResourceName)-$global:resourceSuffix"
            }

            if ($resource.UseHyphen -eq $false) {
                $newResourceName = $newResourceName.Replace("-", "")
            }

            if (Test-ResourceExists -resourceName $newResourceName `
                    -resourceType $resource.ResourceType `
                    -resourceGroupName $resourceGroupName) {
                $resourceExists = $true
                break
            }
            else {
                $resource.Item.Name = $newResourceName
            }
        }

        if ($resourceExists -eq $false) {
            foreach ($appService in $global:appServices) {
                if ($useGuid) {
                    $appService.Name = "$($appService.Name)-$resourceGuid-$global:resourceSuffix"
                }
                else {
                    $appService.Name = "$($appService.Name)-$global:resourceSuffix"
                }
            }
        }
        if ($resourceExists -eq $false) {
            foreach ($appService in $global:appServices) {
                if (Test-ResourceExists -resourceName $appService.Name `
                        -resourceType "Microsoft.Web/sites" `
                        -resourceGroupName $resourceGroupName -or $resourceExists) {
                    $resourceExists = $true
                    break
                }
            }
        }

        if ($resourceExists -eq $false) {
            foreach ($aiModel in $global:aiModels) {
                $aiModelResourceExists = Test-ResourceExists -resourceName $aiModel.DeploymentName -resourceType "Microsoft.CognitiveServices/accounts/deployments" -resourceGroupName $resourceGroupName -or $resourceExists
                if ($aiModelResourceExists) {
                    $resourceExists = $true
                    break
                }
            }
        }

        if ($resourceExists) {
            $global:resourceSuffix++
        }

    } while ($resourceExists)

    if ($useGuid) {
        return "$resourceGuid-$global:resourceSuffix"
    }
    else {
        return "$global:resourceSuffix"
    }
    
}

# Ensure the service name is valid
function Get-ValidServiceName {
    param (
        [string]$serviceName
    )

    #Write-Host "Executing Get-ValidServiceName function..." -ForegroundColor Magenta

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
            Write-Host "Extension '$extensionName' is already installed." -ForegroundColor Blue
            continue
        }
        else {

            try {
                code --install-extension $extensionName
                Write-Host "Installed extension '$extensionName' successfully." -ForegroundColor Green
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
            Write-Host "Azure Machine Learning extension installed successfully." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install Azure Machine Learning extension: $_"
        }
    }
}

# Initialize the parameters
function Initialize-Parameters {
    param (
        [string]$parametersFile = "parameters.json",
        [psobject]$updatedResourceList
    )

    Write-Host "Executing Initialize-Parameters function..." -ForegroundColor Magenta

    $global:resourceList = @()

    if ($updatedResourceList) {
        $global:resourceList = $updatedResourceList
    }
    else {
        # List of all KeyVault secret keys
        $global:KeyVaultSecrets = [PSCustomObject]@{
            StorageServiceApiKey = ""
            SearchServiceApiKey  = ""
            OpenAIServiceApiKey  = ""
        }

        # Navigate to the project directory
        Set-DirectoryPath -targetDirectory $global:deploymentPath

        # Load parameters from the JSON file
        $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

        $global:deploymentType = $parametersObject.deploymentType

        #$global:keyVaultSecrets = $parametersObject.KeyVaultSecrets
        $global:resourceTypes = $parametersObject.resourceTypes
        $global:previousResourceBaseName = $parametersObject.previousResourceBaseName
        $global:newResourceBaseName = $parametersObject.newResourceBaseName
        $global:previousFullResourceBaseName = $parametersObject.previousFullResourceBaseName
        $global:currentFullResourceBaseName = $parametersObject.currentFullResourceBaseName

        $global:restoreSoftDeletedResourcess = $parametersObject.restoreSoftDeletedResourcess

        if ($global:deploymentType -eq "New") {
            Update-ResourceBaseName -newResourceBaseName $global:newResourceBaseName
            $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json
        }
        else {
            # Use fullResourceBaseName from the new schema
            $global:newFullResourceBaseName = $parametersObject.fullResourceBaseName
        }

        # Initialize globals by mapping to nested objects when applicable
        $global:aiAssistant = $parametersObject.aiAssistant
        $global:aiHub = $parametersObject.aiHub            
        $global:aiModels = $parametersObject.aiModels
        $global:aiProject = $parametersObject.aiProject          
        $global:aiService = $parametersObject.aiService
        
        $global:appDeploymentOnly = $parametersObject.appDeploymentOnly
        $global:appendUniqueSuffix = $parametersObject.appendUniqueSuffix
        $global:appInsightsService = $parametersObject.appInsightsService
        $global:appRegistrationClientId = $parametersObject.appRegistrationClientId
        $global:appRegRequiredResourceAccess = $parametersObject.appRegRequiredResourceAccess
        $global:appServiceEnvironment = $parametersObject.appServiceEnvironment
        $global:appServicePlan = $parametersObject.AppServicePlan
        $global:appServices = $parametersObject.appServices
        $global:azureManagement = $parametersObject.azureManagement
        $global:bingSearchService = $parametersObject.bingSearchService
        $global:cognitiveService = $parametersObject.cognitiveService       
        $global:computerVisionService = $parametersObject.computerVisionService  
        $global:containerRegistry = $parametersObject.containerRegistry      
        $global:documentIntelligenceService = $parametersObject.documentIntelligenceService
        $global:exposeApiScopes = $parametersObject.exposeApiScopes
        $global:functionAppService = $appServices | Where-Object { $_.Type -eq "Function" | Select-Object -First 1 }
        $global:keyVault = $parametersObject.keyVault
        $global:keyVaultProxyOperations = $parametersObject.keyVaultProxyOperations   
        $global:logAnalyticsWorkspace = $parametersObject.logAnalyticsWorkspace
        $global:openAIService = $parametersObject.openAIService
        $global:previousResourceBaseName = $parametersObject.previousResourceBaseName          
        $global:resourceGroup = $parametersObject.resourceGroup
        $global:resourceProviders = $parametersObject.resourceProviders
        $global:resourceSkills = $parametersObject.resourceSkills
        $global:searchDataSources = $parametersObject.searchDataSources
        $global:searchRestApiVersion = $parametersObject.searchRestApiVersion
        $global:searchIndexers = $parametersObject.searchIndexers
        $global:searchIndexes = $parametersObject.searchIndexes
        $global:searchService = $parametersObject.searchService
        $global:searchSkillSets = $parametersObject.searchSkillSets          
        $global:storageService = $parametersObject.storageService
        $global:storageServiceSasTemplate = $parametersObject.storageServiceSasTemplate
        $global:subNet = $parametersObject.subNet
        $global:userAssignedIdentity = $parametersObject.userAssignedIdentity
        $global:useGuid = $parametersObject.useGuid
        $global:virtualNetwork = $parametersObject.virtualNetwork

        $global:apiManagementService = $parametersObject.apiManagementService

        $global:apiManagementService.PublisherName = az ad signed-in-user show --query displayName --output tsv
        $global:apiManagementService.PublisherEmail = az ad signed-in-user show --query userPrincipalName --output tsv

        if ($global:keyVault.PermissionModel -eq "RoleBased") {
            $global:useRBAC = $true
        }
        else {
            $global:useRBAC = $false
        }

        $global:cognitiveServicesList = @(
            $global:aiService,
            $global:cognitiveService,
            $global:computerVisionService,
            $global:openAIService,
            $global:documentIntelligenceService
        )


        # Make sure the previousFullResourceBaseName is different than the current one.
        if ($parametersObject.previousFullResourceBaseName -eq $parametersObject.newFullResourceBaseName -and $parametersObject.redeployResources -eq $false) {
            Write-Host "The previousFullResourceBaseName parameter is the same as the newFullResourceBaseName parameter. Please change the previousFullResourceBaseName parameter to a different value."
            exit
        }

        # 2025-02-11 ADS: Commenting out objectId related code because it seems to be slowing the script down significantly. 
        # I can't recall what it's for but I guess I'll find out soon enough with stuff starts breaking.

        # Retrieve subscription, tenant, object and user details
        $global:subscriptionId = az account show --query "id" --output tsv
        $global:tenantId = az account show --query "tenantId" --output tsv
        #$global:objectId = az ad signed-in-user show --query "objectId" --output tsv
        $global:userPrincipalName = az ad signed-in-user show --query userPrincipalName --output tsv
        $global:resourceGuid = Split-Guid

        $parametersObject | Add-Member -MemberType NoteProperty -Name "tenantId" -Value $global:tenantId
        $parametersObject | Add-Member -MemberType NoteProperty -Name "userPrincipalName" -Value $global:userPrincipalName
        $parametersObject | Add-Member -MemberType NoteProperty -Name "resourceGuid" -Value $global:resourceGuid

        # Build-ResourceList -parametersObject $parametersObject
        $global:resourceList = @(
            @{ Item = $global:storageService; CurrentName = $global:storageService.Name; UseHyphen = $false },
            @{ Item = $global:appServicePlan; CurrentName = $global:appServicePlan.Name; UseHyphen = $true },
            @{ Item = $global:appServiceEnvironment; CurrentName = $global:appServiceEnvironment.Name; UseHyphen = $true },
            @{ Item = $global:logAnalyticsWorkspace; CurrentName = $global:logAnalyticsWorkspace.Name; UseHyphen = $true },
            @{ Item = $global:bingSearchService; CurrentName = $global:bingSearchService.Name; UseHyphen = $true },
            @{ Item = $global:searchService; CurrentName = $global:searchService.Name; UseHyphen = $true },
            @{ Item = $global:containerRegistry; CurrentName = $global:containerRegistry.Name; UseHyphen = $false },
            @{ Item = $global:apiManagementService; CurrentName = $global:apiManagementService.Name; UseHyphen = $true },
            @{ Item = $global:appInsightsService; CurrentName = $global:appInsightsService.Name; UseHyphen = $true },
            @{ Item = $global:documentIntelligenceService; CurrentName = $global:documentIntelligenceService.Name; UseHyphen = $true },
            @{ Item = $global:computerVisionService; CurrentName = $global:computerVisionService.Name; UseHyphen = $true },
            @{ Item = $global:openAIService; CurrentName = $global:openAIService.Name; UseHyphen = $true },
            @{ Item = $global:aiService; CurrentName = $global:aiService.Name; UseHyphen = $true },
            @{ Item = $global:aiHub; CurrentName = $global:aiHub.Name; UseHyphen = $true },
            @{ Item = $global:aiProject; CurrentName = $global:aiProject.Name; UseHyphen = $true },
            @{ Item = $global:virtualNetwork; CurrentName = $global:virtualNetwork.Name; UseHyphen = $true },
            @{ Item = $global:keyVault; CurrentName = $global:keyVault.Name; UseHyphen = $true },
            @{ Item = $global:userAssignedIdentity; CurrentName = $global:userAssignedIdentityName; UseHyphen = $true }
        )
    }

    return @{
        aiAssistant                  = $global:aiAssistant
        aiHub                        = $global:aiHub
        aiModels                     = $global:aiModels
        aiProject                    = $global:aiProject
        aiService                    = $global:aiService
        apiManagementService         = $global:apiManagementService
        appInsightsService           = $global:appInsightsService
        appServices                  = $global:appServices
        appRegistrationClientId      = $global:appRegistrationClientId
        appRegRequiredResourceAccess = $global:appRegRequiredResourceAccess
        appDeploymentOnly            = $global:appDeploymentOnly
        appendUniqueSuffix           = $global:appendUniqueSuffix
        appServiceEnvironment        = $global:appServiceEnvironment
        appServicePlan               = $global:appServicePlan
        azureManagement              = $global:azureManagement
        bingSearchService            = $global:bingSearchService
        cognitiveService             = $global:cognitiveService
        computerVisionService        = $global:computerVisionService
        configFilePath               = $parametersObject.configFilePath
        containerRegistry            = $global:containerRegistry
        createResourceGroup          = $parametersObject.createResourceGroup
        currentFullResourceBaseName  = $global:currentFullResourceBaseName
        deleteResourceGroup          = $parametersObject.deleteResourceGroup
        deployApiManagementService   = $parametersObject.deployApiManagementService
        deploymentType               = $global:deploymentType
        deployZipResources           = $parametersObject.deployZipResources
        documentIntelligenceService  = $global:documentIntelligenceService
        exposeApiScopes              = $global:exposeApiScopes
        functionAppService           = $global:functionAppService
        keyVault                     = $global:keyVault
        keyVaultProxyOperations      = $global:keyVaultProxyOperations
        keyVaultSecrets              = $global:KeyVaultSecrets
        location                     = $parametersObject.location
        logAnalyticsWorkspace        = $global:logAnalyticsWorkspace
        machineLearningService       = $parametersObject.machineLearningService
        managedIdentityName          = $parametersObject.managedIdentityName
        newResourceBaseName          = $global:newResourceBaseName
        newFullResourceBaseName      = $global:newFullResourceBaseName
        #objectId                     = $global:objectId
        openAIService                = $global:openAIService
        parameters                   = $parametersObject
        previousFullResourceBaseName = $global:previousFullResourceBaseName
        previousResourceBaseName     = $global:previousResourceBaseName
        redeployResources            = $parametersObject.redeployResources
        redisCacheName               = $parametersObject.redisCacheName
        resourceBaseName             = $parametersObject.resourceBaseName
        resourceGroup                = $global:resourceGroup
        resourceGuid                 = $global:resourceGuid
        resourceProviders            = $global:resourceProviders
        resourceSkills               = $global:resourceSkills
        resourceSuffix               = $parametersObject.resourceSuffix
        resourceSuffixCounter        = $parametersObject.resourceSuffixCounter
        resourceTypes                = $global:resourceTypes
        restoreSoftDeletedResourcess = $global:restoreSoftDeletedResourcess
        result                       = $result
        searchDataSources            = $global:searchDataSources
        searchIndexFieldNames        = $parametersObject.searchIndexFieldNames
        searchIndexes                = $global:searchIndexes
        searchIndexers               = $global:searchIndexers
        searchPublicInternetResults  = $parametersObject.searchPublicInternetResults
        searchRestApiVersion         = $global:searchRestApiVersion
        searchService                = $global:searchService
        searchSkillSets              = $global:searchSkillSets
        siteLogo                     = $parametersObject.siteLogo
        storageService               = $global:storageService
        storageServiceSasTemplate    = $global:storageServiceSasTemplate
        subNet                       = $global:subNet
        subscriptionId               = $global:subscriptionId
        tenantId                     = $global:tenantId
        userAssignedIdentity         = $global:userAssignedIdentity
        useGuid                      = $global:useGuid
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

    Write-Host "Executing Initialize-Azure-Login function..." -ForegroundColor Magenta

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
        [hashtable]$headers = $null,
        [string]$jsonBody = $null
    )

    Write-Host "Executing Invoke-AzureRestMethod function..." -ForegroundColor Magenta

    # Get the access token
    $token = az account get-access-token --query accessToken --output tsv

    $body = $jsonBody | ConvertFrom-Json

    $token = az account get-access-token --query accessToken --output tsv

    if ($headers -eq $null) {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type"  = "application/json"
        }
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

# Function to check if a resource is supported in a region
function Is-ResourceSupported {
    param (
        [string]$region,
        [string]$resourceType
    )

    Write-Host "Executing Is-ResourceSupported function..." -ForegroundColor Magenta

    $supportedRegions = az provider show --namespace $resourceType --expand "resourceTypes" --query "resourceTypes[?resourceType=='accounts'].locations" --output json

    $isSupported = $supportedRegions -contains $region

    if ($isSupported) {
        Write-Host "Resource type '$resourceType' is supported in region '$region'." -ForegroundColor Green
    }
    else {
        Write-Host "Resource type '$resourceType' is NOT supported in region '$region'." -ForegroundColor Red
    }
    
    return $isSupported
}

# Function to check if a skill is supported in a region
function Is-SkillSupported {
    param (
        [string]$region,
        [string]$skillType
    )

    Write-Host "Executing Is-SkillSupported function..." -ForegroundColor Magenta

    $supportedSkills = @(
        "TextSplitter",
        "TextSummarizer",
        "TextSentimentAnalyzer",
        "TextTranslator",
        "TextToSpeech",
        "SpeechToText",
        "ImageCaptioning",
        "ImageClassifier",
        "ImageObjectDetector",
        "ImageSegmenter"
    )

    $isSupported = $supportedSkills -contains $skillName
    
    return $isSupported
}

# Function to create a new AI Assistant
function New-AiAssistant {
    param(
        [psobject]$aiAssistant
    )

    Write-Host "Executing New-AiAssistant function..." -ForegroundColor Magenta

    $openAiKey = $global:openAIService.ApiKey

    $aiAssistantName = $aiAssistant.Name
    $aiAssistantDescription = $aiAssistant.Description
    $aiAssistantTools = $aiAssistant.Tools
    $aiAssistantModel = $aiAssistant.model
    $aiAssistantTemperature = $aiAssistant.temperature
    $aiAssistantInstructions = $aiAssistant.instructions
    $aiAssistantToolsResources = $aiAssistant.toolsResources
    $aiAssistantTopP = $aiAssistant.topP
    $aiAssistantUrl = "https://eastus.api.cognitive.microsoft.com/openai/assistants?api-version=2024-05-01-preview"

    $headers = @{
        "Content-Type" = "application/json"
        "api-key"      = $openAiKey
    }

    $jsonBody = @{
        name           = $aiAssistantName
        description    = $aiAssistantDescription
        tools          = $aiAssistantTools
        model          = $aiAssistantModel
        temperature    = $aiAssistantTemperature
        instructions   = $aiAssistantInstructions
        toolsResources = $aiAssistantToolsResources
        topP           = $aiAssistantTopP
    }

    $jsonBody = $jsonBody | ConvertTo-Json -Depth 10

    $ErrorActionPreference = 'Stop'

    try {
        Invoke-AzureRestMethod -method "POST" -url $aiAssistantUrl -jsonBody $jsonBody -headers $headers
        Write-Host "AI Assistant '$aiAssistantName' created successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create AI Assistant '$aiAssistantName': $_"
    }
}

# Function to create a new AI Hub
function New-AIHub {
    param (
        [psobject]$aiHub,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $storageServiceName = $global:storageService.Name
    $keyVaultName = $global:keyVault.Name

    $aiHubName = $aiHub.Name

    Write-Host "Executing New-AIHub ('$aiHubName') function..." -ForegroundColor Magenta

    Set-DirectoryPath -targetDirectory $global:deploymentPath

    # Create AI Hub
    if ($existingResources -notcontains $aiHubName) {
        try {
            $ErrorActionPreference = 'Stop'
            $storageAccountId = az storage account show --resource-group $resourceGroupName --name $storageServiceName --query 'id' --output tsv
            $keyVaultId = az keyvault show --resource-group $resourceGroupName --name $keyVaultName --query 'id' --output tsv

            az ml workspace create --kind hub --resource-group $resourceGroupName --name $aiHubName --storage-account $storageAccountId --key-vault $keyVaultId

            $global:resourceCounter += 1
            Write-Host "AI Hub: '$aiHubName' created successfully. ($global:resourceCounter)" -ForegroundColor Green
            Write-Log -message "AI Hub: '$aiHubName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" -and $restoreSoftDeletedResources) {
                try {
                    Restore-SoftDeletedResource -resource $aiHub -resourceGroupName $resourceGroupName
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
        Write-Host "AI Hub '$aiHubName' already exists." -ForegroundColor Blue
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
        [psobject]$serviceProperties,
        [array]$existingResources
    )

    $serviceName = $serviceProperties.Name

    Write-Host "Executing New-AIHubConnection ('$serviceName') function..." -ForegroundColor Magenta

    #https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-blob?view=azureml-api-2

    try {
        $ErrorActionPreference = 'Stop'

        $aiConnectionFile = Update-AIConnectionFile -resourceGroupName $resourceGroupName -serviceName $serviceName -serviceProperties $serviceProperties -resourceType $resourceType

        az ml connection create --file $aiConnectionFile --resource-group $resourceGroupName --workspace-name $aiProjectName

        Write-Host "Azure $resourceType '$serviceName' connection for '$aiHubName' created successfully." -ForegroundColor Green
        Write-Log -message  "Azure $resourceType '$serviceName' connection for '$aiHubName' created successfully." -logFilePath $global:LogFilePath
    }
    catch {

        Write-Error "Failed to create Azure $resourceType '$serviceName' connection for '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Azure $resourceType '$serviceName' connection for '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI project
function New-AIProject {
    param (
        [psobject]$aiProject,
        [string]$resourceGroupName,
        [string]$location
    )

    $appInsightsName = $global:appInsightsService.Name
    $userAssignedIdentityName = $global:userAssignedIdentity.Name
    $aiHubName = $global:aiHub.Name
    $aiProjectName = $aiProject.Name
    $location = $aiProject.Location

    Write-Host "Executing New-AIProject ('$aiProjectName') function..." -ForegroundColor Magenta

    $subscriptionId = $global:subscriptionId

    $ErrorActionPreference = 'Stop'

    try {

        $ErrorActionPreference = 'Stop'

        #$storageAccountResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup.Name/providers/Microsoft.Storage/storageAccounts/$storageServiceName"
        #$containerRegistryResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup.Name/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName"
        #$keyVaultResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup.Name/providers/Microsoft.KeyVault/vaults/$keyVaultName"
        $appInsightsResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName"
        $userAssignedIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
        $aiHubResoureceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName"

        az ml workspace create --kind project --resource-group $resourceGroupName --name $aiProjectName --hub-id $aiHubResoureceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId --location $location

        $global:resourceCounter += 1
        Write-Host "AI Project: '$aiProjectName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
        Write-Log -message "AI Project: '$aiProjectName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
    }
    catch {
        Write-Error "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
    }
}

# Function to create a new AI Service connection
function New-ApiManagementApi {
    param (
        [string]$resourceGroupName,
        [string]$keyVaultName,
        [psobject]$apiManagementService
    )

    $apiManagementServiceName = $apiManagementService.Name

    Write-Host "Executing New-ApiManagementApi ('$apiManagementServiceName') function..." -ForegroundColor Magenta

    $global:existingResources = az resource list --resource-group $resourceGroupName --query "[].name" --output tsv | Sort-Object

    $apiManagementServiceExists = $global:existingResources -contains $apiManagementServiceName

    if ($apiManagementServiceExists) {
        $status = az apim show --resource-group $resourceGroupName --name $apiManagementServiceName --query "provisioningState" -o tsv

        if ($status -eq "Activating") {
            Write-Host "API Management Service '$apiManagementServiceName' is activating. Please wait until it is fully provisioned and then rerun the deployment script again." -ForegroundColor Yellow
            Write-Log -message "API Management Service '$apiManagementServiceName' is activating. Please wait until it is fully provisioned and then rerun the deployment script again." -logFilePath $global:LogFilePath
            return
        }
    }

    # Check if the API already exists
    $apiExists = az apim api show --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy
   
    if (-not $apiExists) {
        try {
            # Create the API
            az apim api create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --display-name "KeyVault Proxy" --path keyvault --service-url "https://$keyVaultName.vault.azure.net/" --protocols https
            
            Write-Host "API 'KeyVaultProxy' created successfully." -ForegroundColor Green
            Write-Log -message "API 'KeyVaultProxy' created successfully." -logFilePath $global:LogFilePath
        }
        catch {
            Write-Error "Failed to create API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath               
        }

        try {
            # Check if the operations already exist

            $keyVaultProxyOperationsList = az apim api operation list --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --query "[].name" --output tsv

            foreach ($operation in $global:keyVaultProxyOperations) {
                if ($keyVaultProxyOperationsList -notcontains $operation.Name) {
                    
                    try {
                        az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id $operation.Name --display-name $operation.DisplayName --method $operation.Method --url-template $operation.UrlTemplate
                        
                        Write-Host "Operation '$($operation.Name)' created successfully." -ForegroundColor Green
                        Write-Log -message "Operation '$($operation.Name)' created successfully." -logFilePath $global:LogFilePath
                    }
                    catch {
                        Write-Error "Failed to create operation '$($operation.Name)': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to create operation '$($operation.Name)': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
                    }
                }
                else {
                    Write-Host "Operation '$($operation.Name)' already exists." -ForegroundColor Blue
                    Write-Log -message "Operation '$($operation.Name)' already exists." -logFilePath $global:LogFilePath
                }
            }
        }
        catch {
            Write-Error "Failed to get list of operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to get list of operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
                
        try {
            # Add CORS policy to operations [THIS DOES NOT WORK. NO SUCH COMMAND EXISTS]
            #az apim api operation policy set --resource-group $resourceGroup.Name --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
            #az apim api operation policy set --resource-group $resourceGroup.Name --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
        }
        catch {
            Write-Error "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }

        Write-Host "API 'KeyVaultProxy' and its operations created successfully." -ForegroundColor Green
        Write-Log -message "API 'KeyVaultProxy' and its operations created successfully." -logFilePath $global:LogFilePath
    }
    else {
        Write-Host "API 'KeyVaultProxy' already exists." -ForegroundColor Blue
        Write-Log -message "API 'KeyVaultProxy' already exists." -logFilePath $global:LogFilePath

        try {
            # Check if the operations already exist

            $keyVaultProxyOperationsList = az apim api operation list --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --query "[].name" --output tsv

            foreach ($operation in $global:keyVaultProxyOperations) {
                if ($keyVaultProxyOperationsList -notcontains $operation.Name) {
                    
                    try {
                        az apim api operation create --resource-group $resourceGroupName --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id $operation.Name --display-name $operation.DisplayName --method $operation.Method --url-template $operation.UrlTemplate
                        
                        Write-Host "Operation '$($operation.Name)' created successfully." -ForegroundColor Green
                        Write-Log -message "Operation '$($operation.Name)' created successfully." -logFilePath $global:LogFilePath
                    }
                    catch {
                        Write-Error "Failed to create operation '$($operation.Name)': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to create operation '$($operation.Name)': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
                    }
                }
                else {
                    Write-Host "Operation '$($operation.Name)' already exists." -ForegroundColor Blue
                    Write-Log -message "Operation '$($operation.Name)' already exists." -logFilePath $global:LogFilePath
                }
            }
        }
        catch {
            Write-Error "Failed to get list of operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to get list of operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
                
        try {
            # Add CORS policy to operations [THIS DOES NOT WORK]
            #az apim api operation policy set --resource-group $resourceGroup.Name --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetOpenAIServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
            #az apim api operation policy set --resource-group $resourceGroup.Name --service-name $apiManagementServiceName --api-id KeyVaultProxy --operation-id GetSearchServiceApiKey --xml-policy "<inbound><base /><cors><allowed-origins><origin>$global:appService.Url</origin></allowed-origins><allowed-methods><method>GET</method></allowed-methods></cors></inbound>"
    
        }
        catch {
            Write-Error "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to add CORS policy to operations for API 'KeyVaultProxy': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
}

# Function to create and deploy API Management Service
function New-ApiManagementService {
    param (
        [string]$resourceGroupName,
        [string]$keyVaultName,
        [psobject]$apiManagementService,
        [array]$existingResources
    )

    $apiManagementServiceName = $apiManagementService.Name

    Write-Host "Executing New-ApiManagementService ('$apiManagementServiceName') function..." -ForegroundColor Magenta

    #https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/rest-api/read.png

    if ($global:DeployApiManagementService -eq $false) {
        return
    }

    #$deletedApimServiceList = az apim deletedservice list --query "[?name=='$apiManagementServiceName'].name" --output tsv
    $deletedApimServiceNames = az apim deletedservice list --query "[].name" --output tsv
    $apimServiceExistsInDeletedState = $deletedApimServiceNames -contains $apiManagementServiceName

    if ($existingResources -notcontains $apiManagementServiceName) {
        try {
            $ErrorActionPreference = 'Stop'

            if ($apimServiceExistsInDeletedState) {
                Write-Host "API Management Service '$apiManagementServiceName' exists in a soft-deleted state. Attempting to restore the service..."
                Write-Log -message "API Management Service '$apiManagementServiceName' exists in a soft-deleted state. Attempting to restore the service..." -logFilePath $global:LogFilePath

                #$jsonOutput = az apim undelete --name $apiManagementServiceName --resource-group $resourceGroupName --output none 2>&1
                $jsonOutput = az apim deletedservice purge --service-name $apiManagementServiceName --location $apiManagementService.Location --output none 2>&1

                $jsonOutput = az apim create -n $apiManagementServiceName --publisher-name $apiManagementService.PublisherName --publisher-email $apiManagementService.PublisherEmail --resource-group $resourceGroupName --no-wait --output none 2>&1

                if ($jsonOutput -match "error") {

                    $errorInfo = Format-CustomErrorInfo -jsonOutput $jsonOutput

                    $errorName = $errorInfo["Error"]
                    $errorCode = $errorInfo["Code"]
                    $errorDetails = $errorInfo["Message"]

                    $errorMessage = "Failed to restore API Management Service '$apiManagementServiceName'."
                }
                else {
                    $global:resourceCounter += 1
                    Write-Host "API Management Service '$apiManagementServiceName' restored successfully. [$global:resourceCounter]" -ForegroundColor Green
                    Write-Log -message "API Management Service '$apiManagementServiceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
                }
            }
            else {
                
                $jsonOutput = az apim create -n $apiManagementServiceName --publisher-name $apiManagementService.PublisherName --publisher-email $apiManagementService.PublisherEmail --resource-group $resourceGroupName --no-wait --output none 2>&1

                #Write-Host $jsonOutput

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
                    if (($errorCode -match "FlagMustBeSetForRestore" -or $errorCode -match "ServiceAlreadyExistsInSoftDeletedState" ) -and $global:restoreSoftDeletedResources) {
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Restore-SoftDeletedResource -resource $apiManagementService -resourceGroupName $resourceGroupName
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
                    Write-Host "API Management Service '$apiManagementServiceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
                    Write-Log -message "API Management Service '$apiManagementServiceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
                }
            }

            New-ApiManagementApi -resourceGroupName $resourceGroupName -keyVaultName $keyVaultName -apiManagementService $apiManagementService

        }
        catch {
            Write-Error "Failed to create API Management Service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create API Management Service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "API Management Service '$apiManagementServiceName' already exists." -ForegroundColor Blue
        Write-Log -message "API Management Service '$apiManagementServiceName' already exists." -logFilePath $global:LogFilePath

        $status = az apim show --resource-group $resourceGroupName --name $apiManagementServiceName --query "provisioningState" -o tsv

        if ($status -eq "Activating") {
            Write-Host "API Management Service '$apiManagementServiceName' is activating."
            Write-Log -message "API Management Service '$apiManagementServiceName' is activating." -logFilePath $global:LogFilePath
            return
        }
    }

    New-ApiManagementApi -resourceGroupName $resourceGroupName -apiManagementService $apiManagementService -keyVaultName $keyVaultName
}

# Function to register an app, set API permissions, expose the API, and set Key Vault access policies
function New-AppRegistration {
    param (
        [string]$appServiceName,
        [string]$appServiceUrl,
        [string]$resourceGroupName,
        [string]$keyVaultName,
        [string]$parametersFile
    )

    Write-Host "Executing New-AppRegistration ('$appServiceName') function..." -ForegroundColor Magenta

    try {
        $ErrorActionPreference = 'Stop'

        $appRegRequiredResourceAccessJson = $global:appRegRequiredResourceAccess | ConvertTo-Json -Depth 4

        # Check if the app is already registered
        $existingApp = az ad app list --filter "displayName eq '$appServiceName'" --output json | ConvertFrom-Json

        $objectId = ""
        
        if ($existingApp) {
            $appId = $existingApp.appId

            $objectId = az ad app show --id $appId --query "id" --output json | ConvertFrom-Json
            $appUri = $existingApp.appUri

            Write-Host "App '$appServiceName' is already registered with App ID: $appId and Object ID: $objectId." -ForegroundColor Blue
            Write-Log -message "App '$appServiceName' is already registered with App ID: $appId and Object ID: $objectId."
        }
        else {
            # Register the app
            $appRegistration = az ad app create --display-name $appServiceName --sign-in-audience AzureADandPersonalMicrosoftAccount | ConvertFrom-Json

            $appId = $appRegistration.appId
            $objectId = az ad app show --id $appId --query "id" --output json | ConvertFrom-Json
            $appUri = $appRegistration.appUri

            Write-Host "App '$appServiceName' registered successfully with App ID: $appId and Object ID: $objectId." -ForegroundColor Green
            Write-Log -message "App '$appServiceName' registered successfully with App ID: $appId and Object ID: $objectId."
        }

        # Update the parameters file with the new app registration details
        Update-ParametersFileAppRegistration -parametersFile $parametersFile -appId $appId -appUri $appUri

        $global:appRegistrationClientId = $appId
        $global:appRegistrationObjectId = $existingApp.objectId
        $global:appRegistrationAppUri = $existingApp.appUri

        $permissions = "User.Read.All"
        $apiPermissions = ""
        
        # Check and set API permissions
        $permissionsCount = $global:appRegRequiredResourceAccess.Count

        if ($permissionsCount -eq 0) {
            Write-Host "No API permissions to set for app '$appServiceName'."
            Write-Log -message "No API permissions to set for app '$appServiceName'."
        }
        else {

            foreach ($permission in $global:appRegRequiredResourceAccess) {
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

                        Write-Host "Permission '$permissions' for '$appServiceName' with App ID: $appId added successfully." -ForegroundColor Green
                        Write-Log -message "Permission '$permissions' for '$appServiceName' with App ID: $appId added successfully." -logFilePath $global:LogFilePath
                    }
                    catch {
                        Write-Error "Failed to add permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                        Write-Log -message "Failed to add permission '$permissions' for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    }

                    try {
                        az ad app permission grant --id $appId --api $permissionResourceAppId --scope $permissions

                        Write-Host "Permission '$permissions' for '$appServiceName' with App ID: $appId granted successfully." -ForegroundColor Green
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
        }

        try {
            # Check and expose the API
            $existingScopes = az ad app show --id $appId --query "oauth2Permissions[].value" --output json | ConvertFrom-Json
            $apiScopes = @()
            foreach ($scope in $global:exposeApiScopes) {
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
    
            $appRegistrationClientId = $global:appRegistrationClientId

            # Define the identifierUrisArray
            $appServiceUrl = $global:appServices | Where-Object { $_.Name -eq $appServiceName } | Select-Object -ExpandProperty Url

            $identifierUrisArray = @{"uri" = $appServiceUrl }
            #$identifierUris = "https://app-$global:resourceBaseName.azurewebsites.net api://$appRegistrationClientId"
            $identifierUris = "api://$appRegistrationClientId"

            # Update the identifierUris and oauth2PermissionScopes properties
            #$app.identifierUris = $identifierUris
            $app.api.oauth2PermissionScopes += $apiScopes

            #az ad app update --id $appId--set preAuthorizedApplications="[{\"appId\": \"$appRegistrationClientId\", \"delegatedPermissionIds\": [\"242e8d29-4a20-4d96-9369-9bb59b7b26ad\", \"d4d93556-98ca-4b51-8712-02854daf8197\"]}]"

            # 2025-02-20 ADS: The code below is not working as expected. I need to figure out how to add the permissions from the MS Graph API instead of the AD Graph API.
            # az rest  `
            #     --method PATCH `
            #     --uri "https://graph.microsoft.com/v1.0/applications/$appId" `
            #     --headers 'Content-Type=application/json' `
            #     --body "{api:{preAuthorizedApplications:[{'appId':'$appRegistrationClientId','delegatedPermissionIds':['242e8d29-4a20-4d96-9369-9bb59b7b26ad', 'd4d93556-98ca-4b51-8712-02854daf8197'] }] }}"

            # { api: { preAuthorizedApplications: [{ 'appId': '6782b97e-07a2-48fa-9f7e-5fa0c237fd52', 'delegatedPermissionIds': ['242e8d29-4a20-4d96-9369-9bb59b7b26ad', 'd4d93556-98ca-4b51-8712-02854daf8197'] }] } }

            # The issue with the below code is that the entries made for the API access permissions are using AD Graph and not MS Graph. The AD graph does not have "name" or "description" properties.
            # So even though the original code I had set in the parameters file was correct, the code below is not working as expected so I removed those two properties from the parameters.json file.
            # It was then that I realized that it was using the wrong Graph API because instead of the name of the permission being showm it was the GUID instead.
            # It would appear that the manifest file will not allow me to add the permissions from the MS Graph API only the AD Graph API. 
            # Even though the manifest files for the AD and MS Graph APIs are the same, unless I add the permissions using the GUI in the web portal the values will be saved as AD Graph and not MS Graph.
            # I still need to figure out how to add the permissions from the MS Graph API instead of the AD Graph API.

            # https://learn.microsoft.com/en-us/entra/identity-platform/reference-microsoft-graph-app-manifest

            $app.requiredResourceAccess = $appRegRequiredResourceAccess
            # $app.spa.redirectUris = $identifierUrisArray

            # $app.replyUrlsWithType = @{
            #     "url"  = $appServiceUrl
            #     "type" = "Spa"
            # }
            # Convert the updated manifest back to JSON
            #$appJson = $app | ConvertTo-Json -Depth 10
            #$appSpaJson = $app.spa | ConvertTo-Json -Depth 10

            #$appSpaJson = '"spa": { "redirectUris": [' + $appServiceUrl + ']}'
            
            # Update the application with the modified manifest
            #$appId = "5073ae0e-7f06-45c8-b99d-c6137c0b544a"
            
            #$appJson | Out-File -FilePath "appManifest.json" -Encoding utf8
            #az ad app update --id $appId --set spa=$appSpaJson
            
            try {
                az ad app update --id $appId --sign-in-audience AzureADandPersonalMicrosoftAccount
                
                Write-Host "The property 'Sign-in audience' for '$appServiceName' app registration updated successfully." -ForegroundColor Green
                Write-Log -message "The property 'Sign-in audience' for '$appServiceName' app registration updated successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to update 'sign-in-audience' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update 'sign-in-audience' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }

            try {
                
                $scopesJsonArray = $app.api.oauth2PermissionScopes | ForEach-Object { $_ | ConvertTo-Json -Depth 10 }
                $oauth2PermissionScopesJson = '{"oauth2PermissionScopes": [' + ($scopesJsonArray -join ", ") + "] }"

                $oauth2PermissionScopesJson | Out-File -FilePath "oauth2PermissionScopes.json" -Encoding utf8

                az ad app update --id $appId --set api=@oauth2PermissionScopes.json

                Write-Host "The property 'oauth2PermissionScopes' for '$appServiceName' app registration updated successfully." -ForegroundColor Green
                Write-Log -message "The property 'oauth2PermissionScopes' for '$appServiceName' app registration updated successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to update 'oauth2PermissionScopes' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update 'oauth2PermissionScopes' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
            
            try {
                az ad app update --id $appId --required-resource-accesses $appRegRequiredResourceAccessJson

                Write-Host "The property 'required-resource-accesses' for '$appServiceName' app registration updated successfully." -ForegroundColor Green
                Write-Log -message "The property 'required-resource-accesses' for '$appServiceName' app registration updated successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to update 'required-resource-accesses' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update 'required-resource-accesses' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
            
            try {
                $identifierUris = "api://$appRegistrationClientId"

                az ad app update --id $appId --identifier-uris $identifierUris

                Write-Host "The property 'identifier-uris' for '$appServiceName' app registration updated successfully." -ForegroundColor Green
                Write-Log -message "The property 'identifier-uris' for '$appServiceName' app registration updated successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to update 'identifier-uris' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update 'identifier-uris' property for '$appServiceName' app registration: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }

            #az ad app update --id $appId --identifier-uris $identifierUris
            #az ad app update --id $appId --set displayName=app-copilot-demo-002
            #az ad app update --id $appId --set notes=test

            $appUri = "https://graph.microsoft.com/v1.0/$appId"

            $body = Get-Content -Raw -Path "appManifest.json" 
            az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/$appId" --body $body

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
    
            Write-Host "Key Vault access policies for app '$appServiceName' set successfully." -ForegroundColor Green
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
        [psobject]$appInsightsService,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $appInsightsName = $appInsightsService.Name
    $location = $appInsightsService.Location

    Write-Host "Executing New-ApplicationInsights ('$appInsightsName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $appInsightsName) {


        #$appInsightsName = Get-ValidServiceName -serviceName $appInsightsName

        # Try to create an Application Insights component
        try {
            $ErrorActionPreference = 'Stop'
            az monitor app-insights component create --app $appInsightsName --location $location --resource-group $resourceGroupName --application-type web --output none

            $global:resourceCounter += 1
            Write-Host "Application Insights component '$appInsightsName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Application Insights component '$appInsightsName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Application Insights '$appInsightsName' already exists." -ForegroundColor Blue
        Write-Log -message "Application Insights '$appInsightsName' already exists."
    }
}

# Function to create and deploy app service (either web app or function app)
function New-AppService {
    param (
        [psobject]$appService,
        [string]$appInsightsName,
        [string]$resourceGroupName,        
        [string]$storageServiceName,
        [string]$userAssignedIdentityName,
        [bool]$deployZipResources,
        [array]$existingResources
    )

    $appServiceType = $appService.Type
    $appServiceName = $appService.Name
    $deployZipPackage = $appService.DeployZipPackage

    Write-Host "Executing New-AppService ('$appServiceName') function..." -ForegroundColor Magenta

    $appExists = @()

    $ErrorActionPreference = 'Stop'

    # Making sure we are in the correct folder depending on the app type
    Set-DirectoryPath -targetDirectory $appService.Path

    try {
        try {

            if ($appServiceType -eq "Web") {

                $appExists = az webapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new web app
                    az webapp create --name $appServiceName --resource-group $resourceGroupName --plan $appService.AppServicePlan --runtime $appService.Runtime --deployment-source-url $appService.Url
                    #az webapp cors add --methods GET POST PUT --origins '*' --services b --account-name $appServiceName --account-key $storageAccessKey
                    $userAssignedIdentity = az identity show --resource-group $resourceGroup.Name --name $userAssignedIdentityName

                    az webapp identity assign --name $appServiceName --resource-group $resourceGroup.Name --identities $userAssignedIdentity.id --output tsv
                }
            }
            else {

                # Check if the Function App exists
                $appExists = az functionapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new function app
                    az functionapp create --name $appServiceName --resource-group $resourceGroupName --storage-account $storageServiceName --plan $appService.AppServicePlan --app-insights $appInsightsName --runtime $appService.Runtime --os-type "Windows" --functions-version 4 --output none

                    $webAppService = $global:appServices | Where-Object { $_.type -eq 'Web' } | Select-Object -First 1

                    az functionapp cors add --name $appServiceName --allowed-origins $webAppService.Url --resource-group $resourceGroupName
                }
            }

            if (-not $appExists) {

                $global:resourceCounter += 1
                Write-Host "$appServiceType app '$appServiceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
                Write-Log -message "$appServiceType app '$appServiceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            else {
                Write-Host "$appServiceType app '$appServiceName' already exists."
                Write-Log -message "$appServiceType app '$appServiceName' already exists." -logFilePath $global:LogFilePath
            }

            # Deploy the app service
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
        [psobject]$appServiceEnvironment,
        [string]$resourceGroupName,
        [string]$subscriptionId,
        [array]$existingResources
    )

    $appServiceEnvironmentName = $appServiceEnvironment.Name

    Write-Host "Executing New-AppServiceEnvironment ('$appServiceEnvironmentName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $appServicePlanName) {
        try {
            $ErrorActionPreference = 'Stop'

            # Create the ASE asynchronously
            <#
 # {            $job = Start-Job -ScriptBlock {
                param (
                    $appServiceEnvironmentName,
                    $resourceGroup.Name,
                    $location,
                    $vnetName,
                    $subnetName,
                    $subscriptionId
                )
                az appservice ase create --name $appServiceEnvironmentName --resource-group $resourceGroup.Name --location $location --vnet-name $vnetName --subnet $subnetName --subscription $subscriptionId --output none
            } -ArgumentList $appServiceEnvironmentName, $resourceGroup.Name, $location, $vnetName, $subnetName, $subscriptionId
:Enter a comment or description}
#>
            Write-Host "Waiting for App Service Environment '$appServiceEnvironmentName' to be created before creating app service plan and app services."
            Start-Sleep -Seconds 20

            #az appservice ase create --name $appServiceEnvironmentName --resource-group $resourceGroup.Name --location $location --vnet-name $vnetName --subnet $subnetName --subscription $subscriptionId --output none
            Write-Host "App Service Environment '$appServiceEnvironmentName' created successfully."
            Write-Log -message "App Service Environment '$appServiceEnvironmentName' created successfully."
        }
        catch {
            Write-Error "Failed to create App Service Environment '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create App Service Environment '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "App Service Environment '$appServiceEnvironmentName' already exists." -ForegroundColor Blue
        Write-Log -message "App Service Environment '$appServiceEnvironmentName' already exists."
    }
}

# Function to create a new App Service Plan
function New-AppServicePlan {
    param (
        [psobject]$appServicePlan,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $appServicePlanName = $appServicePlan.Name
    $appServicePlanLocation = $appServicePlan.Location
    $appServicePlanSku = $appServicePlan.Sku
    $appServicePlanOS = $appServicePlan.OS

    Write-Host "Executing New-AppServicePlan ('$appServicePlanName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $appServicePlanName) {
        try {
            $ErrorActionPreference = 'Stop'

            # Check if Microsoft.Web resource provider has been registered
            $resourceProvider = az provider show --namespace Microsoft.Web --query "registrationState" -o tsv

            if ($resourceProvider -ne "Registered") {
                Write-Host "Registering Microsoft.Web resource provider..."
                az provider register --namespace Microsoft.Web
            }

            # Create the App Service Plan (check if OS is Linux or Windows)
            if ($appServicePlanOS -eq "Linux") {
                az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $appServicePlanLocation --sku $appServicePlanSku --is-linux --output none
            }
            else {
                az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $appServicePlanLocation --sku $appServicePlanSku --output none
            }

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
        Write-Host "App Service Plan '$appServicePlanName' already exists." -ForegroundColor Blue
        Write-Log -message "App Service Plan '$appServicePlanName' already exists."
    }
}

# Function to create a new App Service Plan in an App Service Environment (ASE)
function New-AppServicePlanInASE {
    param (
        [psobject]$appServicePlan,
        [string]$resourceGroupName,
        [string]$location,
        [string]$appServiceEnvironmentName,
        [array]$existingResources
    )

    $appServicePlanName = $appServicePlan.Name

    Write-Host "Executing New-AppServicePlanInASE ('$appServicePlanName') in ('$appServiceEnvironmentName') function..." -ForegroundColor Magenta

    $appServicePlanName = $appServicePlan.Name

    try {
        $ErrorActionPreference = 'Stop'
        az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --app-service-environment $appServiceEnvironmentName --sku $sku --output none

        $global:resourceCounter += 1
        Write-Host "App Service Plan '$appServicePlanName' created in ASE '$appServiceEnvironmentName'. [$global:resourceCounter]" -ForegroundColor Green
        Write-Log -message "App Service Plan '$appServicePlanName' created in ASE '$appServiceEnvironmentName'. [$global:resourceCounter]"
    }
    catch {
        Write-Error "Failed to create App Service Plan '$appServicePlanName' in ASE '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create App Service Plan '$appServicePlanName' in ASE '$appServiceEnvironmentName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create a new Bing Grounding resource
function New-BingGrounding {
    param (
        [psobject]$bingGrounding,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $bingGroundingName = $bingGrounding.Name

    Write-Host "Executing New-BingGrounding ('$bingGroundingName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $bingGroundingName) {
        try {
            $ErrorActionPreference = 'Stop'
            az cognitiveservices account create --name $bingGroundingName --resource-group $resourceGroupName --kind Bing.Search v7 --sku S0 --location $location --output none

            $global:resourceCounter += 1
            Write-Host "Bing Grounding '$bingGroundingName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Bing Grounding '$bingGroundingName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Bing Grounding '$bingGroundingName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Bing Grounding '$bingGroundingName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Bing Grounding '$bingGroundingName' already exists." -ForegroundColor Blue
        Write-Log -message "Bing Grounding '$bingGroundingName' already exists."
    }
}

# Function to create new Cognitive Services resources
function New-CognitiveServiceResources {
    param (
        [array]$cognitiveServicesList
    )

    $resourceGroupName = $global:resourceGroup.Name

    foreach ($service in $cognitiveServicesList) {
        $serviceName = $service.Name
        $serviceDescription = $service.Description

        Write-Host "Executing New-CognitiveServiceResources $serviceDescription ('$serviceName') function..." -ForegroundColor Magenta

        if ($global:existingResources -notcontains $serviceName) {

            # Check if a soft-deleted instance exists
            $deletedResource = az cognitiveservices account list-deleted `
                --query "[?name=='$serviceName'].name" `
                --output tsv

            try {
                if ($deletedResource -eq $serviceName) {
                    Write-Host "Found soft-deleted resource '$serviceName'. Attempting restore..." -ForegroundColor Yellow

                    # Restore the soft-deleted resource (assumes Restore-SoftDeletedResource function exists)
                    Restore-SoftDeletedResource -resource $service -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Host "Creating $serviceDescription '$serviceName'..." -ForegroundColor Cyan

                    $createResult = az cognitiveservices account create `
                        --name $serviceName `
                        --resource-group $resourceGroupName `
                        --location $service.Location `
                        --kind $service.Kind `
                        --sku $service.Sku `
                        --output tsv 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        $global:resourceCounter += 1
                        Write-Host "$serviceDescription '$serviceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
                        Write-Log -message "$serviceDescription '$serviceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
                    }
                    else {
                        Write-Error "Failed to create $serviceDescription '$serviceName'. Error: $createResult"
                    }
                }
            }
            catch {
                Write-Error "Error processing $serviceDescription '$serviceName': $_"
            }
        }
        else {
            Write-Host "$serviceDescription '$serviceName' already exists." -ForegroundColor Blue
        }
    }
}

# Function to create a new container registry
function New-ContainerRegistry {
    param (
        [psobject]$containerRegistry,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $containerRegistryName = $containerRegistry.Name
    $containerRegistryLocation = $containerRegistry.Location

    Write-Host "Executing New-ContainerRegistry ('$containerRegistryName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $containerRegistryName) {
        $containerRegistryFile = Update-ContainerRegistryFile -resourceGroupName $resourceGroupName -containerRegistry $containerRegistry

        try {

            $ErrorActionPreference = 'SilentlyContinue'

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
                if ($errorCode -match "FlagMustBeSetForRestore" -and $global:restoreSoftDeletedResources) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $containerRegistryName -resourceType "ContainerRegistry" -location $containerRegistryLocation -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {
                $global:resourceCounter += 1

                Write-Host "Container Registry '$containerRegistryName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
                Write-Log -message "Container Registry '$containerRegistryName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
        }
        catch {
            Write-Error "Failed to create Container Registry '$containerRegistryName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Container Registry '$containerRegistryName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Container Registry '$containerRegistryName' already exists." -ForegroundColor Blue
        Write-Log -message "Container Registry '$containerRegistryName' already exists."
    }
}

# Function to create a new database
function New-Database {
    param (
        [psobject]$database,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $databaseName = $database.Name
    $sqlServerName = $database.SqlServerName

    Write-Host "Executing New-Database ('$databaseName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $databaseName) {
        try {
            $ErrorActionPreference = 'Stop'
            az sql db create --name $databaseName --resource-group $resourceGroupName --server $sqlServerName --service-objective S0 --output none

            $global:resourceCounter += 1
            Write-Host "Database '$databaseName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Database '$databaseName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Database '$databaseName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Database '$databaseName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Database '$databaseName' already exists." -ForegroundColor Blue
        Write-Log -message "Database '$databaseName' already exists."
    }
}

# Function to create a new key vault
function New-KeyVault {
    param (
        [psobject]$keyVault,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $keyVaultName = $keyVault.Name
    $location = $keyVault.Location
    $userAssignedIdentityName = $global:userAssignedIdentity.Name
    $userPrincipalName = $global:userPrincipalName
    $useRBAC = $keyVault.UseRBAC
   
    $jsonOutput = ""
    
    Write-Host "Executing New-KeyVault ('$keyVaultName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $keyVaultName) {

        try {
            $ErrorActionPreference = 'Continue'

            $deletedService = az keyvault list-deleted --query "[?name=='$keyVaultName']" | ConvertFrom-Json

            if ($deletedService.Name -eq $keyVaultName) {
                Write-Host "Found soft-deleted Key Vault '$keyVaultName'. Attempting restore..." -ForegroundColor Yellow

                # Restore the soft-deleted Key Vault
                Restore-SoftDeletedResource -resource $keyVault -resourceGroupName $resourceGroupName
            }
            else {
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

                    Write-Error $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
                else {
                    Write-Host "Key Vault '$keyVaultName' created successfully." -ForegroundColor Green
                    Write-Log -message "Key Vault '$keyVaultName' created successfully." -logFilePath $global:LogFilePath

                    $global:resourceCounter += 1

                    if ($useRBAC) {
                        Write-Host "Key Vault '$keyVaultName' created with RBAC enabled. [$global:resourceCounter]"
                        Write-Log -message "Key Vault '$keyVaultName' created with RBAC enabled. [$global:resourceCounter]"

                        # Assign RBAC roles to the managed identity
                        Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                    }
                    else {
                        Write-Host "Key Vault '$keyVaultName' created with Vault Access Policies. [$global:resourceCounter]"
                        Write-Log -message "Key Vault '$keyVaultName' created with Vault Access Policies. [$global:resourceCounter]"

                        # Set vault access policies for user
                        Set-KeyVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                    }
                }

            }
        }
        catch {
            Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Key Vault '$keyVaultName' already exists." -ForegroundColor Blue
        Write-Log -message "Key Vault '$keyVaultName' already exists."
    }

    $keyVaultExists = az keyvault show --name $keyVaultName --resource-group $resourceGroupName --query "name" --output tsv

    if ($keyVaultExists -ne $null) {

        Set-KeyVaultRoles -keyVaultName $keyVaultName `
            -resourceGroupName $resourceGroup.Name `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -useRBAC $useRBAC

        $global:openAiService.ApiKey = az cognitiveservices account keys list --name $global:openAiService.Name --resource-group $resourceGroupName --query key1 --output tsv

        $global:KeyVaultSecrets.OpenAIServiceApiKey = $global:openAiService.ApiKey
    }
}

# Function to create a new Log Analytics workspace
function New-LogAnalyticsWorkspace {
    param (
        [psobject]$logAnalyticsWorkspace,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $logAnalyticsWorkspaceName = $logAnalyticsWorkspace.Name
    $location = $logAnalyticsWorkspace.Location

    Write-Host "Executing New-LogAnalyticsWorkspace ('$logAnalyticsWorkspaceName') function..." -ForegroundColor Magenta

    $logAnalyticsWorkspaceName = Get-ValidServiceName -serviceName $logAnalyticsWorkspaceName

    if ($existingResources -notcontains $logAnalyticsWorkspaceName) {
        try {
            $ErrorActionPreference = 'Stop'
            az monitor log-analytics workspace create --workspace-name $logAnalyticsWorkspaceName --resource-group $resourceGroupName --location $location --output none

            $global:resourceCounter += 1

            Write-Host "Log Analytics Workspace '$logAnalyticsWorkspaceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Log Analytics Workspace '$logAnalyticsWorkspaceName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Log Analytics workspace '$logAnalyticsWorkspaceName' already exists." -ForegroundColor Blue
        Write-Log -message "Log Analytics workspace '$logAnalyticsWorkspaceName' already exists."
    }
}

# Function to create a new managed identity
function New-ManagedIdentity {
    param (
        [psobject]$userAssignedIdentity,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $userAssignedIdentityName = $userAssignedIdentity.Name
    $location = $userAssignedIdentity.Location

    Write-Host "Executing New-ManagedIdentity ('$userAssignedIdentityName') function..." -ForegroundColor Magenta

    $subscriptionId = $global:subscriptionId

    try {
        $ErrorActionPreference = 'Stop'
        az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none

        $global:resourceCounter += 1

        $global:keyVault.UserAssignedIdentityName = $userAssignedIdentityName

        $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

        $parametersObject.keyVault.userAssignedIdentityName = $userAssignedIdentityName

        $parametersObject | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

        Write-Host "User Assigned Identity '$userAssignedIdentityName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
        Write-Log -message "User Assigned Identity '$userAssignedIdentityName' created successfully. [$global:resourceCounter]"

        Start-Sleep -Seconds 5

        $global:assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $userAssignedIdentityName --query 'principalId' --output tsv

        try {
            $ErrorActionPreference = 'Stop'

            # Ensure the service principal is created
            az ad sp create --id $global:assigneePrincipalId
            Write-Host "Service principal created for identity '$userAssignedIdentityName'." -ForegroundColor Green
            Write-Log -message "Service principal created for identity '$userAssignedIdentityName'."
        }
        catch {
            Write-Error "Failed to create service principal for identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create service principal for identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }

        # Construct the fully qualified resource ID for the User Assigned Identity
        try {
            $ErrorActionPreference = 'Stop'
            #$userAssignedIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup.Name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
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
        [psobject]$aiProject,
        [string]$resourceGroupName,
        [string]$aiHubName,
        [string]$appInsightsName,
        [string]$containerRegistryName,
        [string]$userAssignedIdentityName,
        [string]$storageServiceName,
        [string]$keyVaultName,
        [array]$existingResources
    )

    $aiProjectName = $aiProject.Name

    Write-Host "Executing New-MachineLearningWorkspace ('$aiProjectName') function..." -ForegroundColor Magenta

    $subscriptionId = $global:subscriptionId

    $location = $aiProject.Location
    $storageServiceName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName"
    $containerRegistryName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName"
    $keyVaultName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
    $appInsightsName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName"
    $userAssignedIdentityName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
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
                -storageServiceName $storageServiceName `
                -containerRegistryName $containerRegistryName `
                -userAssignedIdentityName $userAssignedIdentityName 2>&1

            #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

            #https://azuremlschemas.azureedge.net/latest/workspace.schema.json

            $jsonOutput = az ml workspace create --resource-group $resourceGroupName `
                --application-insights $appInsightsName `
                --description "This configuration specifies a workspace configuration with existing dependent resources" `
                --display-name $aiProjectName `
                --hub-id $aiHubName `
                --kind project `
                --location $location `
                --name $aiProjectName `
                --output none 2>&1

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
                if ($errorDetails -match "soft-deleted workspace" -and $global:restoreSoftDeletedResources) {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $aiProjectName -resourceType "MachineLearningWorkspace" -location $location -resourceGroupName $resourceGroupName
                }
                else {
                    Write-Error "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create AI Project '$aiProjectName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

                    Write-Host $errorMessage
                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
            }
            else {

                $aiHubName = $global:aiHub.Name

                Write-Host "AI Project '$aiProjectName' in '$aiHubName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
                Write-Log -message "AI Project '$aiProjectName' in '$aiHubName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
                $global:resourceCounter += 1

                return $jsonOutput
            }
        }
        catch {
            $aiHubName = $global:aiHub.Name

            Write-Error "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "AI Project '$aiProjectName' already exists." -ForegroundColor Blue
        Write-Log -message "AI Project '$aiProjectName' already exists." -logFilePath $global:LogFilePath
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

    Write-Host "Executing New-PrivateEndPoint ('$privateEndPointName') function..." -ForegroundColor Magenta

    try {
        az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroupName --vnet-name $virtualNetworkName --subnet $subnetId --private-connection-resource-id $privateLinkServiceId --group-id "sqlServer" --connection-name $privateLinkServiceName --location $location --output none
        Write-Host "Private endpoint '$privateEndpointName' created successfully." -ForegroundColor Green
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
        [psobject]$resourceGroup
    )

    $resourceGroupName = $resourceGroup.Name
    $resourceGroupLocation = $resourceGroup.Location

    Write-Host "Executing New-ResourceGroup ('$resourceGroupName') function..." -ForegroundColor Magenta

    do {
        $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName

        if ($resourceGroupExists -eq $true) {
            Write-Host "Resource group '$resourceGroupName' already exists. Trying a new name."
            Write-Log -message "Resource group '$resourceGroupName' already exists. Trying a new name."

            $resourceSuffix++
            $resourceGroupName = "$($resourceGroupName)-$resourceSuffix"
        }

    } while ($resourceGroupExists -eq $true)

    try {
        az group create --name $resourceGroupName --location $resourceGroupLocation --output none

        #$global:resourceCounter += 1

        Write-Host "Resource group '$resourceGroupName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
        Write-Log -message "Resource group '$resourceGroupName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        $resourceGroupExists = $false
    }
    catch {
        Write-Host "An error occurred while creating the resource group '$resourceGroupName'."
        Write-Log -message "An error occurred while creating the resource group '$resourceGroupName'." -logFilePath $global:LogFilePath
    }

    return $resourceGroupName
}

# Function to create resources
function New-Resources {
    param
    (
        [psobject]$apiManagementService,
        [psobject]$appInsightsService,
        [psobject]$appServicePlan,
        [psobject]$cognitiveService,
        [psobject]$computerVisionService,
        [psobject]$containerRegistry,
        [psobject]$documentIntelligenceService,
        [psobject]$logAnalyticsWorkspace,
        [psobject]$openAIService,
        [psobject]$resourceGroup,
        [psobject]$searchService,
        [psobject]$searchSkillSets,
        [psobject]$storageService,
        [psobject]$subNet,
        [psobject]$virtualNetwork,
        [array]$existingResources
    )

    #Write-Host "Executing New-Resources function..." -ForegroundColor Magenta

    $resourceGroupName = $resourceGroup.Name

    # **********************************************************************************************************************
    # Create Storage Service

    New-StorageService -storageService $storageService -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Virtual Network

    New-VirtualNetwork -virtualNetwork $virtualNetwork -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Subnet

    New-SubNet -subNet $subNet -vnetName $virtualNetwork.Name -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Private Endpoint
    
    # Still in testing phase

    # New-PrivateEndPoint -privateEndpointName $subNet.PrivateEndpointName -privateLinkServiceName $subNet.PrivateLinkServiceName -resourceGroupName $resourceGroupName -location $virtualNetwork.Location -subnetId $subNet.Id -privateLinkServiceId $subNet.PrivateLinkServiceId -existingResources $existingResources

    # **********************************************************************************************************************
    # Create App Service Environment

    #New-AppServiceEnvironment -appServiceEnvironmentName $appServiceEnvironmentName -resourceGroupName $resourceGroup.Name -location $location -vnetName $virtualNetwork.Name -subnetName $subnet.Name -subscriptionId $subscriptionId -existingResources $existingResources

    # **********************************************************************************************************************
    # Create App Service Plan

    New-AppServicePlan -appServicePlan $appServicePlan -resourceGroupName $resourceGroupName -existingResources $existingResources

    #New-AppServicePlanInASE -appServicePlanName $appServicePlanName -resourceGroupName $resourceGroup.Name -location $location -appServiceEnvironmentName $appServiceEnvironmentName -sku $appServicePlanSku -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Cognitive Service

    New-CognitiveServiceResources -cognitiveServicesList $global:cognitiveServicesList

    # **********************************************************************************************************************
    # Create Search Service

    New-SearchService -searchService $searchService -resourceGroupName $resourceGroupName -searchSkillSets $searchSkillSets -storageService $storageService -cognitiveService $cognitiveService -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Log Analytics Workspace

    New-LogAnalyticsWorkspace -logAnalyticsWorkspace $logAnalyticsWorkspace -resourceGroupName $resourceGroupName -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Application Insights component

    New-ApplicationInsights -appInsightsService $appInsightsService -resourceGroupName $resourceGroupName -existingResources $existingResources

    #**********************************************************************************************************************
    # Create Container Registry

    New-ContainerRegistry -containerRegistry $containerRegistry -resourceGroupName $resourceGroupName -existingResources $existingResources

    #**********************************************************************************************************************
    # Create SQL Server

    # Still in testing phase
    # New-SQLServer -sqlServer $sqlServer -resourceGroupName $resourceGroupName -existingResources $existingResources -databases $global:sqlDatabases -managedIdentityName $global:userAssignedIdentity.Name

    #**********************************************************************************************************************
    # Create SQL Database

    # Still in testing phase
    # New-SQLDatabase -sqlDatabase $global:sqlDatabase -resourceGroupName $resourceGroupName -existingResources $existingResources

}

# Function to create a new search datasource
function New-SearchDataSource {
    param(
        [string]$resourceGroupName,
        [psobject]$searchService,
        [psobject]$searchDataSource,
        [psobject]$storageService,
        [string]$appId = ""
    )

    $subscriptionId = $global:subscriptionId
    $userAssignedIdentityName = $global:userAssignedIdentity.Name

    # https://learn.microsoft.com/en-us/azure/search/search-howto-index-sharepoint-online

    $storageServiceName = $storageService.Name
    $searchServiceName = $searchService.Name
    $searchServiceAPiVersion = $searchService.ApiVersion
    $searchDataSourceName = $searchDataSource.Name
    $searchDataSourceType = $searchDataSource.Type
    $searchDataSourceQuery = $searchDataSource.Query
    $searchDataSourceUrl = $searchDataSource.Url
    $searchDataSourceContainerName = $searchDataSource.ContainerName
    $searchDataSourceConnectionString = ""

    Write-Host "Executing New-SearchDataSource ('$searchDataSourceName') function..." -ForegroundColor Magenta

    try {
        $ErrorActionPreference = 'Continue'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $storageAccessKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

        # appId code is only relevant for SharePoint Online data source
        if ($searchDataSourceType -eq "sharepoint") {
            foreach ($appService in $global:appServices) {
                $appServiceName = $appService.Name

                if ($appService.Type -eq "Web") {
                    #$appId = az webapp show --name $appService.Name --resource-group $resourceGroup.Name --query "id" --output tsv
                    $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
                
                    if ($appId -eq "") {
                        #Write-Error "Failed to retrieve App ID for App Service '$appServiceName' for SharePoint datasource connection."
                        #Write-Log -message "Failed to retrieve App ID for App Service '$appServiceName' for SharePoint datasource connection." -logFilePath $global:LogFilePath

                        return
                    }
                    else {
                        Write-Host "App ID for $($appServiceName): $appId for SharePoint datasource connection."
                    }
                }
            }
        }

        switch ($searchDataSourceType) {
            "azureblob" {
                #$searchDataSourceConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageServiceName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"
                # For User Assigned Identity
                $searchDataSourceConnectionString = "ResourceId=/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName;"
            }
            "azuresql" {
                $searchDataSourceConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlServerAdmin;Password=$sqlServerAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            }
            "cosmosdb" {
                $searchDataSourceConnectionString = "AccountEndpoint=https://$cosmosDBAccountName.documents.azure.com:443/;AccountKey=$cosmosDBAccountKey;"
            }
            "documentdb" {
                $searchDataSourceConnectionString = "AccountEndpoint=https://$documentDBAccountName.documents.azure.com:443/;AccountKey=$documentDBAccountKey;"
            }
            "mysql" {
                $searchDataSourceConnectionString = "Server=$mysqlServerName.mysql.database.azure.com;Database=$mysqlDatabaseName;Uid=$mysqlServerAdmin@$mysqlServerName;Pwd=$mysqlServerAdminPassword;SslMode=Preferred;"
            }
            "sharepoint" {
                $searchDataSourceConnectionString = "SharePointOnlineEndpoint=$searchDataSourceUrl;ApplicationId=$appId;TenantId=$global:tenantId"
            }
            "sql" {
                $searchDataSourceConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlServerAdmin;Password=$sqlServerAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            }
        }

        # https://docs.azure.cn/en-us/search/search-howto-managed-identities-storage

        $searchDataSourceUrl = "https://$($searchServiceName).search.windows.net/datasources?api-version=$($searchServiceAPiVersion)"

        Write-Host "searchDataSourceUrl: $searchDataSourceUrl"

        if ($searchDataSourceType -eq "sharepoint") {
            $body = @{
                name        = $searchDataSourceName
                type        = $searchDataSourceType
                credentials = @{
                    connectionString = $searchDataSourceConnectionString
                }
                container   = @{
                    name  = $searchDataSourceContainerName
                    query = $searchDataSourceQuery
                }
            }
        }
        else {
            $body = @{
                name        = $searchDataSourceName
                type        = $searchDataSourceType
                credentials = @{
                    connectionString = $searchDataSourceConnectionString
                }
                container   = @{
                    name  = $searchDataSourceContainerName
                    query = $searchDataSourceQuery
                }
                identity    = @{
                    "@odata.type"        = "#Microsoft.Azure.Search.DataUserAssignedIdentity"
                    userAssignedIdentity = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
                }
            }
        }

        # Convert the body hashtable to JSON
        $jsonBody = $body | ConvertTo-Json -Depth 10

        try {
            $ErrorActionPreference = 'Continue'

            Invoke-RestMethod -Uri $searchDataSourceUrl -Method Post -Body $jsonBody -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }

            Write-Host "DataSource '$searchDataSourceName' created successfully." -ForegroundColor Green
            Write-Log -message "DataSource '$searchDataSourceName' created successfully."
                
            return $true
        }
        catch {

            Write-Error "Failed to create datasource '$searchDataSourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create datasource '$searchDataSourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return $false
        }
    }
    catch {
        Write-Error "Failed to create datasource '$searchDataSourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create datasource '$searchDataSourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return $false
    }
}

# Function to create a new search index
function New-SearchIndex {
    param(
        [psobject]$searchService,
        [psobject]$searchIndex,
        [string]$resourceGroupName
    )

    $searchIndexName = $searchIndex.Name
    $searchIndexSchema = $searchIndex.Schema

    $searchServiceName = $searchService.Name
    $searchServiceApiVersion = $searchService.ApiVersion

    Write-Host "Executing New-SearchIndex ('$searchIndexName') function..." -ForegroundColor Magenta

    try {

        $content = Get-Content -Path $searchIndexSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $global:previousFullResourceBaseName, $global:newFullResourceBaseName

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
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexes?api-version=$searchServiceApiVersion"

        # Create the index
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Index '$searchIndexName' created successfully." -ForegroundColor Green
            Write-Log -message "Index '$searchIndexName' created successfully."

            $global:searchIndexes += $searchIndexName

            return $true
        }
        catch {
            # If you are getting the 'Normalizers" error, create the index via the Azure Portal and just select "Add index (JSON)" and copy the contents of the appropriate index json file into the textarea and click "save".
            Write-Error "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return $false
        }
    }
    catch {
        Write-Error "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create index '$searchIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return $false
    }
}

# Function to create a new search indexer
function New-SearchIndexer {
    param(
        [psobject]$searchService,
        [psobject]$resourceGroup,
        [psobject]$searchIndexer,
        [string]$searchIndexName,
        [string]$searchDatasourceName,
        [string]$searchSkillSetName
    )

    $searchServiceName = $searchService.Name
    $searchServiceApiVersion = $searchService.ApiVersion
    $searchIndexerName = $searchIndexer.Name
    $searchIndexerSchema = $searchIndexer.Schema

    Write-Host "Executing New-SearchIndexer ('$searchIndexerName') function..." -ForegroundColor Magenta

    try {

        $content = Get-Content -Path $searchIndexerSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $global:previousFullResourceBaseName, $global:newFullResourceBaseName

        Set-Content -Path $searchIndexerSchema -Value $updatedContent

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$searchServiceAPiVersion"

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
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$searchServiceApiVersion"

        $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
            
        $searchIndexExists = $searchIndexes -contains $searchIndexName

        if ($searchIndexExists -eq $false) {
            New-SearchIndex -searchService $searchService -resourceGroupName $resourceGroupName -searchIndex $index
        }

        # Create the indexer
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Search Indexer '$searchIndexerName' created successfully." -ForegroundColor Green
            Write-Log -message "Search Indexer '$searchIndexerName' created successfully."

            $global:searchIndexers += $searchIndexerName

            return $true
        }
        catch {
            Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return $false
        }
    }
    catch {
        Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return $false
    }
}

# Function to create a new search service
function New-SearchService {
    param(
        [psobject]$searchService,
        [psobject]$storageService,
        [psobject]$cognitiveService,
        [string]$resourceGroupName,
        [psobject]$userAssignedIdentity,
        [psobject]$searchSkillSets,
        [array]$existingResources
    )

    $searchServiceName = $searchService.Name
    $cognitiveServiceName = $cognitiveService.Name
    $userAssignedIdentityName = $global:userAssignedIdentity.Name
    $location = $searchService.Location
    $subscriptionId = $global:subscriptionId
    $azureManagementApiVersion = $global:azureManagement.ApiVersion

    Write-Host "Executing New-SearchService ('$searchServiceName') function..." -ForegroundColor Magenta

    #az provider show --namespace Microsoft.Search --query "resourceTypes[?resourceType=='searchServices'].apiVersions"

    if ($existingResources -notcontains $searchServiceName) {
        $searchServiceName = Get-ValidServiceName -serviceName $searchServiceName
        #$searchServiceSku = $searchService.Sku

        try {
            $ErrorActionPreference = 'Stop'

            az search service create --name $searchServiceName --resource-group $resourceGroupName --identity-type SystemAssigned --location $location --sku basic --output none

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create search service: $createServiceOutput"
            }

            $global:resourceCounter += 1

            Write-Host "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]"

            $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

            $global:searchService.ApiKey = $searchServiceApiKey

            $global:KeyVaultSecrets.SearchServiceApiKey = $searchServiceApiKey

            $searchManagementUrl = "https://management.azure.com/subscriptions/$global:subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
            $searchManagementUrl += "?api-version=$($azureManagementApiVersion)"

            #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
            # az search service update --name $searchServiceName --resource-group $resourceGroup.Name --identity SystemAssigned --aad-auth-failure-mode http401WithBearerChallenge --auth-options aadOrApiKey
            #  --identity type=UserAssigned userAssignedIdentities="/subscriptions/$subscriptionId/resourcegroups/$resourceGroup.Name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"

            # https://docs.azure.cn/en-us/search/search-howto-managed-identities-data-sources?tabs=portal-sys%2Crest-user

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
                        type                   = "SystemAssigned,UserAssigned"
                        userAssignedIdentities = @{
                            "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
                        }
                    }
                }

                # Convert the body hashtable to JSON
                $jsonBody = $body | ConvertTo-Json -Depth 10

                $accessToken = (az account get-access-token --query accessToken -o tsv)

                $headers = @{
                    "api-key"       = $searchServiceApiKey
                    "Authorization" = "Bearer $accessToken"  # Add the authorization header
                }

                #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
                Invoke-RestMethod -Uri $searchManagementUrl -Method PUT -Body $jsonBody -ContentType "application/json" -Headers $headers

            }
            catch {
                Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }

            # Example for how to obtain the sharepoint siteid for use with the REST Api: https://fedairs.sharepoint.com/sites/MicrosoftCopilotDemo/_api/site
            $dataSources = Get-SearchDataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

            $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
                
            $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
                        
            $existingSearchSkillSets = Get-SearchSkillSets -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

            foreach ($appService in $global:appServices) {
                if ($appService.Type -eq "Web") {
                    $appServiceName = $appService.Name
                    #$appId = az webapp show --name $appService.Name --resource-group $resourceGroup.Name --query "id" --output tsv
                    $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
                    #Write-Host "App ID for $($appServiceName): $appId"
                }
            }

            foreach ($searchDataSource in $global:searchDataSources) {
                $searchDataSourceName = $searchDataSource.Name
                $dataSourceExists = $dataSources -contains $searchDataSourceName

                if ($dataSourceExists -eq $false) {
                    New-SearchDataSource -searchService $searchService -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageService $storageService -appId $appId
                
                    $dataSourceExists = $true
                }
                else {
                    Write-Host "Search Service Data Source '$searchDataSourceName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
                }
            }

            foreach ($index in $global:searchIndexes) {
                $indexName = $index.Name

                $searchIndexExists = $searchIndexes -contains $indexName

                if ($searchIndexExists -eq $false) {
                    New-SearchIndex -searchService $searchService -resourceGroupName $resourceGroupName -searchIndex $index
                }
                else {
                    Write-Host "Search Index '$indexName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Index '$indexName' already exists."
                }

                $searchIndexExists = $true
            }

            foreach ($searchSkillSet in $searchSkillSets) {

                $searchSkillSetName = $searchSkillSet.Schema.Name

                $searchSkillSetExists = $existingSearchSkillSets -contains $searchSkillSetName

                if ($searchSkillSetExists -eq $false) {

                    Start-Sleep -Seconds 10
                    New-SearchSkillSet -searchService $searchService -resourceGroupName $resourceGroupName -searchSkillSet $searchSkillSet -cognitiveServiceName $cognitiveServiceName
                }
                else {
                    Write-Host "Search Skill Set '$searchSkillSetName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Skill Set '$searchSkillSetName' already exists."
                }
            }

            try {
                if ($dataSourceExists -eq "true" -and $searchIndexExists -eq $true) {

                    $filteredSearchIndexers = $global:searchIndexers | Where-Object { $_.Active -eq $true }

                    foreach ($indexer in $filteredSearchIndexers) {
                        $indexName = $indexer.IndexName
                        $indexerName = $indexer.Name

                        $searchDataSourceName = $indexer.DataSourceName

                        $searchIndexerExists = $searchIndexers -contains $indexerName

                        if ($searchIndexerExists -eq $false) {
                            New-SearchIndexer -searchService $searchService `
                                -resourceGroupName $resourceGroupName `
                                -searchDatasourceName $searchDataSourceName `
                                -searchSkillSetName $searchSkillSetName `
                                -searchIndexName $indexName `
                                -searchIndexer $indexer
                        }
                        else {
                            Write-Host "Search Indexer '$indexerName' already exists." -ForegroundColor Blue
                            Write-Log -message "Search Indexer '$indexerName' already exists." -logFilePath $global:LogFilePath
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

        Write-Host "Search Service '$searchServiceName' already exists." -ForegroundColor Blue
        Write-Log -message "Search Service '$searchServiceName' already exists."

        #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
        #az search service update --name $searchServiceName --resource-group $resourceGroup.Name --identity SystemAssigned --aad-auth-failure-mode http401WithBearerChallenge --auth-options aadOrApiKey
        #  --identity type=UserAssigned userAssignedIdentities="/subscriptions/$subscriptionId/resourcegroups/$resourceGroup.Name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $global:searchService.ApiKey = $searchServiceApiKey

        $global:keyVaultSecrets.SearchServiceApiKey = $searchServiceApiKey

        $searchManagementUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
        $searchManagementUrl += "?api-version=$azureManagementApiVersion"

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
                    type                   = "UserAssigned"
                    userAssignedIdentities = @{
                        "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
                    }
                }
            }

            # Convert the body hashtable to JSON
            $jsonBody = $body | ConvertTo-Json -Depth 10

            $accessToken = (az account get-access-token --query accessToken -o tsv)

            $headers = @{
                "api-key"       = $searchServiceApiKey
                "Authorization" = "Bearer $accessToken"  # Add the authorization header
            }

            #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
            Invoke-RestMethod -Uri $searchManagementUrl -Method PUT -Body $jsonBody -ContentType "application/json" -Headers $headers

        }
        catch {
            Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }

        $dataSources = Get-SearchDataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

        $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
                
        $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
                        
        $existingSearchSkillSets = Get-SearchSkillSets -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName
             
        try {
            $ErrorActionPreference = 'Continue'

            $dataSourceExists = $dataSources -contains $searchDataSourceName

            foreach ($index in $global:searchIndexes) {
                $indexName = $index.Name

                $searchIndexExists = $searchIndexes -contains $indexName

                if ($searchIndexExists -eq $false) {
                    New-SearchIndex -searchService $searchService -resourceGroupName $resourceGroupName -searchIndex $index
                }
                else {
                    Write-Host "Search Index '$indexName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Index '$indexName' already exists."
                }
            }

            foreach ($appService in $global:appServices) {
                $appServiceName = $appService.Name
                if ($appService.Type -eq "Web") {
                    #$appId = az webapp show --name $appService.Name --resource-group $resourceGroup.Name --query "id" --output tsv
                    $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
                    #Write-Host "App ID for $($appServiceName): $appId"
                    break
                }
            }

            foreach ($searchDataSource in $global:searchDataSources) {
                $searchDataSourceName = $searchDataSource.Name
                $dataSourceExists = $dataSources -contains $searchDataSourceName

                if ($dataSourceExists -eq $false) {
                    New-SearchDataSource -searchService $searchService -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageService $storageService -appId $appId
                }
                else {
                    Write-Host "Search Service Data Source '$searchDataSourceName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
                }
            }

            foreach ($searchSkillSet in $searchSkillSets) {

                $searchSkillSetName = $searchSkillSet.Schema.Name

                $searchSkillSetExists = $existingSearchSkillSets -contains $searchSkillSetName

                if ($searchSkillSetExists -eq $false) {

                    Start-Sleep -Seconds 10
                    New-SearchSkillSet -searchService $searchService -resourceGroupName $resourceGroupName -searchSkillSet $searchSkillSet -cognitiveServiceName $cognitiveServiceName
                }
                else {
                    Write-Host "Search Skill Set '$searchSkillSetName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Skill Set '$searchSkillSetName' already exists."
                }
            }

            try {

                $filteredSearchIndexers = $global:searchIndexers | Where-Object { $_.Active -eq $true }

                #$existingSearchIndexers = az search indexer list --resource-group $resourceGroupName --service-name $searchServiceName --output table

                if ($searchServiceApiKey -eq "") {
                    $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
                }

                $headers = @{
                    "content-type" = "application/json"
                    "api-key"      = $searchServiceApiKey
                }

                $existingSearchIndexers = Invoke-AzureRestMethod -Method Get -headers $headers -url "https://$searchServiceName.search.windows.net/indexers?api-version=$($searchService.ApiVersion)"

                $existingSearchIndexerNames = $existingSearchIndexers.value.name

                foreach ($indexer in $filteredSearchIndexers) {
                    $indexName = $indexer.IndexName
                    $indexerName = $indexer.Name

                    $searchDataSourceName = $indexer.DataSourceName

                    $searchIndexerExists = $existingSearchIndexerNames -contains $indexerName

                    if ($searchIndexerExists -eq $false) {
                        New-SearchIndexer -searchService $searchService `
                            -resourceGroupName $resourceGroupName `
                            -searchDatasourceName $searchDataSourceName `
                            -searchSkillSetName $searchSkillSetName `
                            -searchIndexName $indexName `
                            -searchIndexer $indexer
                    }
                    else {
                        Write-Host "Search Indexer '$indexerName' already exists." -ForegroundColor Blue
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
}

# Function to create a new skillset
function New-SearchSkillSet {
    param(
        [psobject]$searchService,
        [string]$resourceGroupName,
        [psobject]$searchSkillSet,
        [string]$cognitiveServiceName
    )

    Write-Host "Executing New-SearchSkillSet function..." -ForegroundColor Magenta

    $searchServiceName = $searchService.Name
    $searchServiceApiVersion = $searchService.ApiVersion

    try {
        $ErrorActionPreference = 'Stop'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        # Might need to get search service API version from the parameters.json file

        $cognitiveServiceKey = az cognitiveservices account keys list --name $cognitiveServiceName --resource-group $resourceGroupName --query "key1" --output tsv

        $skillSetUrl = "https://$searchServiceName.search.windows.net/skillsets?api-version=$searchServiceAPiVersion"

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

            Write-Host "Skillset '$searchSkillSetName' created successfully." -ForegroundColor Green
            Write-Log -message "Skillset '$searchSkillSetName' created successfully."

            return $true
        }
        catch {
            Write-Error "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

            return $false
        }
    }
    catch {
        Write-Error "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create skillset '$searchSkillSetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"

        return $false
    }
}

# Function to create a new SQL Server
function New-SQLServer {
    param (
        [psobject]$sqlServer,
        [string]$resourceGroupName,
        [array]$existingResources,
        [string]$managedIdentityName
    )

    # Need to update code to use managed identity for authentication instead of admin user and password

    $sqlServerName = $sqlServer.Name
    $sqlAdminUser = $sqlServer.AdminUser
    $sqlAdminPassword = $sqlServer.AdminPassword
    $location = $sqlServer.Location

    Write-Host "Executing New-SQLServer ('$sqlServerName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $sqlServerName) {
        try {
            $ErrorActionPreference = 'Stop'
            
            # First create storage account for SQL Server
            $storageAccountName = $sqlServer.StorageAccountName

            $storageAccountExists = az storage account check-name --name $storageAccountName --query "nameAvailable" --output tsv
            if ($storageAccountExists -eq "false") {
                Write-Host "Storage account '$storageAccountName' already exists." -ForegroundColor Blue
                Write-Log -message "Storage account '$storageAccountName' already exists."
            }
            else {
                az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --output none
                Write-Host "Storage account '$storageAccountName' created successfully." -ForegroundColor Green
                Write-Log -message "Storage account '$storageAccountName' created successfully."
            }
            
            az sql server create --name $sqlServerName --resource-group $resourceGroupName --location $location --admin-user $sqlAdminUser --admin-password $sqlAdminPassword --output none

            $global:resourceCounter += 1
            Write-Host "SQL Server '$sqlServerName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "SQL Server '$sqlServerName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create SQL Server '$sqlServerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create SQL Server '$sqlServerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "SQL Server '$sqlServerName' already exists." -ForegroundColor Blue
        Write-Log -message "SQL Server '$sqlServerName' already exists."
    }
}

# Function to create new Azure storage service
function New-StorageService {
    param (
        
        [psobject]$storageService,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $storageServiceName = $storageService.Name
    $storageContainerName = $storageService.ContainerName
    $storageLocation = $storageService.Location
    $storageKind = $storageService.Kind
    $storageSku = $storageService.Sku

    Write-Host "Executing New-StorageService ('$storageServiceName') function..." -ForegroundColor Magenta

    $appService = $global:appServices | Where-Object { $_.Type -eq "Web" }
    $appServiceUrl = $appService.Url

    if ($existingResources -notcontains $storageServiceName) {

        try {
            az storage account create --name $storageServiceName --resource-group $resourceGroupName --location $storageLocation --sku $storageSku --kind $storageKind --output none

            $global:resourceCounter += 1

            Write-Host "Storage account '$storageServiceName' created successfully. [$global:resourceCounter]" -ForegroundColor Green
            Write-Log -message "Storage account '$storageServiceName' created successfully. [$global:resourceCounter]"

            # Retrieve the storage account key
            $global:storageServiceAccountKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

            $global:storageService.Credentials.AccountKey = $global:storageServiceAccountKey

            $global:keyVaultSecrets.StorageServiceApiKey = $global:storageServiceAccountKey

            try {
                az storage container create --name $storageContainerName --account-name $storageServiceName --account-key $global:storageServiceAccountKey --output none

                Write-Host "Storage container '$storageContainerName' created successfully." -ForegroundColor Green
                Write-Log -message "Storage container '$storageContainerName' created successfully." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
            # Enable CORS

            try {
                az storage cors clear --account-name $storageServiceName --services bfqt
                
                az storage cors add --methods GET POST PUT --origins '*' --allowed-headers '*' --exposed-headers '*' --max-age 200 --services b --account-name $storageServiceName --account-key $global:storageServiceAccountKey
                
                az storage cors add --methods GET POST PUT --origins $appServiceUrl --allowed-headers '*' --exposed-headers '*' --max-age 200 --services b --account-name $storageServiceName --account-key $global:storageServiceAccountKey
    
                Write-Host "CORS rules added to Storage Account '$storageServiceName'." -ForegroundColor Green
                Write-Log -message "CORS rules added to Storage Account '$storageServiceName'." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to add CORS rules to Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to add CORS rules to Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        catch {
            Write-Error "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Storage Account '$storageServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {

        Write-Host "Storage account '$storageServiceName' already exists." -ForegroundColor Blue
        Write-Log -message "Storage account '$storageServiceName' already exists."

        # Retrieve the storage account key
        $global:storageServiceAccountKey = az storage account keys list --account-name $storageServiceName --resource-group $resourceGroupName --query "[0].value" --output tsv

        $global:storageService.Credentials.AccountKey = $global:storageServiceAccountKey

        $global:keyVaultSecrets.StorageServiceApiKey = $global:storageServiceAccountKey

        $containerExists = az storage container exists --name $storageContainerName --account-name $storageServiceName --account-key $global:storageServiceAccountKey --output tsv

        if ($containerExists -eq "false") {
            az storage container create --name $storageContainerName --account-name $storageServiceName --account-key $global:storageServiceAccountKey --output none

            Write-Host "Storage container '$storageContainerName' created successfully." -ForegroundColor Green
            Write-Log -message "Storage container '$storageContainerName' created successfully." -logFilePath $global:LogFilePath
        }


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

    Write-Host "Executing New-SubNet ('$subnetName') function..." -ForegroundColor Magenta

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
        Write-Host "Subnet '$subnetName' already exists." -ForegroundColor Blue
        Write-Log -message "Subnet '$subnetName' already exists."
    }
}

# Function to create a new virtual network
function New-VirtualNetwork {
    param (
        [psobject]$virtualNetwork,
        [string]$resourceGroupName,
        [array]$existingResources
    )

    $vnetName = $virtualNetwork.Name

    Write-Host "Executing New-VirtualNetwork ('$vnetName') function..." -ForegroundColor Magenta

    if ($existingResources -notcontains $vnetName) {
        try {
            az network vnet create --resource-group $resourceGroupName --name $vnetName --output none

            $global:resourceCounter += 1

            Write-Host "Virtual Network '$vnetName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Virtual Network '$vnetName' created successfully. [$global:resourceCounter]"
        }
        catch {
            Write-Error "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Virtual Network '$vnetName' already exists." -ForegroundColor Blue
        Write-Log -message "Virtual Network '$vnetName' already exists."
    }
}

# Function to register list of required resource providers
function Register-ResourceProviders {

    Write-Host "Executing Register-ResourceProviders function..." -ForegroundColor Magenta

    foreach ($resourceProvider in $global:resourceProviders) {
        $providerExists = az provider show --namespace $resourceProvider --query "registrationState" --output tsv

        if ($providerExists -ne "Registered") {
            az provider register --namespace $resourceProvider --output none
            Write-Host "Resource provider '$resourceProvider' registered successfully."
            Write-Log -message "Resource provider '$resourceProvider' registered successfully."
        }
        else {
            Write-Host "Resource provider '$resourceProvider' is already registered." -ForegroundColor Blue
            Write-Log -message "Resource provider '$resourceProvider' is already registered."
        }
    }
}

# Function to delete Azure resource groups
function Remove-ResourceGroup {
    param
    (
        [string]$resourceGroupName
    )

    Write-Host "Executing Remove-ResourceGroup function..." -ForegroundColor Magenta

    $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName

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

    Write-Host "Executing Remove-MachineLearningWorkspace function..." -ForegroundColor Magenta

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
        [psobject]$searchService,
        [string]$resourceGroupName,
        [string]$searchIndexerName
    )

    $searchServiceName = $searchService.Name
    $searchServiceAPiVersion = $searchService.ApiVersion

    try {
        $ErrorActionPreference = 'Stop'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers/$searchIndexerName/reset?api-version=$searchServiceAPiVersion"

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
        [psobject]$resource,
        [string]$resourceGroupName
    )

    $resourceName = $resource.Name
    $resourceType = $resource.Type
    $resourceDescription = $resource.Description
    $resourceLocation = $resource.Location

    Write-Host "Executing Restore-SoftDeletedResource ('$resourceName') function..." -ForegroundColor Magenta

    switch ($resourceType) {
        "KeyVault" {
            # Code to restore Key Vault
            Write-Output "Restoring Key Vault: $resourceName"
            try {
                $ErrorActionPreference = 'Stop'
                # Attempt to restore the soft-deleted Key Vault
                az keyvault recover --name $resourceName --resource-group $resourceGroupName --location $resourceLocation --output none

                $global:resourceCounter += 1

                Write-Host "Key Vault: '$resourceName' restored successfully. [$global:resourceCounter]" -ForegroundColor Green
                Write-Log -message "Key Vault: '$resourceName' restored successfully. [$global:resourceCounter]"
            }
            catch {
                Write-Error "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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

                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($resourceLocation.ToUpper() -replace '\s', '') --output none

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
                Write-Output "Restoring '$resourceDescription': $resourceName"

                if ($resourceType -eq "Api Management Service") {
                    az resource update --ids $(az apim show --name $resourceName --resource-group $resourceGroupName --query 'id' --output tsv) --set properties.deletionRecoveryLevel="Recoverable"
                }

                az cognitiveservices account recover --name $resourceName --resource-group $resourceGroupName --location $($resourceLocation.ToUpper() -replace '\s', '') --output none

                $global:resourceCounter += 1
                Write-Host "$resourceDescription '$resourceName' restored successfully. [$global:resourceCounter]"
                Write-Log -message "$resourceDescription '$resourceName' restored successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore $resourceDescription '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore $resourceDescription '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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
        [string]$resourceGroupName,
        [string]$keyVaultName
    )

    Write-Host "Executing Set-KeyVaultAccessPolicies function..." -ForegroundColor Magenta

    #$userPrincipalName = $global:userPrincipalName
    $userPrincipalName = az ad signed-in-user show --query userPrincipalName --output tsv

    try {
        $ErrorActionPreference = 'Stop'
        # Set policy for the user
        az keyvault set-policy --name $keyVaultName --resource-group $resourceGroupName --upn $userPrincipalName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        Write-Host "Key Vault '$keyVaultName' policy permissions set for user: '$userPrincipalName'." -ForegroundColor Yellow
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

    $userAssignedIdentityObjectId = az identity show --name $userAssignedIdentityName --resource-group $resourceGroupName --query 'principalId' --output tsv

    Write-Host "Executing Set-KeyVaultRoles function..." -ForegroundColor Magenta

    # Set policy for the application
    try {
        $ErrorActionPreference = 'Stop'
        #az keyvault set-policy --name $keyVaultName --object-id $userAssignedIdentityObjectId --resource-group $resourceGroupName --spn $userAssignedIdentityName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        #az keyvault set-policy --name $keyVaultName --resource-group $resourceGroupName --spn $userAssignedIdentityName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        az keyvault set-policy --name $keyVaultName --object-id $userAssignedIdentityObjectId --resource-group $resourceGroupName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
        
        Write-Host " Key Vault '$keyVaultName' policy permissions set for user: '$userAssignedIdentityName'." -ForegroundColor Yellow
        Write-Log -message "Key Vault '$keyVaultName' policy permissions set for user: '$userAssignedIdentityName'."
    }
    catch {
        Write-Error "Failed to set Key Vault '$keyVaultName' policy permissions for user: '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to set Key Vault '$keyVaultName' policy permissions for user: '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to set Key Vault storage SAS
function Set-KeyVaultStorageSas {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName
    )

    Write-Host "Executing Set-KeyVaultStorageSas function..." -ForegroundColor Magenta

    $storageServiceName = $global:storageService.Name
    $storageServiceSasTemplate = $global:storageServiceSasTemplate
    $subscriptionId = $global:subscriptionId

    #$storageKey = az storage account keys list --resource-group  $resourceGroupName --account-name $storageServiceName --query "[0].value" --output tsv
    #$storageSAS = az storage account generate-sas --account-name $storageServiceName --account-key $storageKey --resource-types co --services btfq --permissions rwdlacupiytfx --expiry $expirationDate --https-only --output tsv
    
    try {
        $ErrorActionPreference = 'Stop'
        # Create a new key vault managed storage account
        az keyvault storage add --vault-name $keyVaultName -n $storageServiceName --active-key-name key1 --auto-regenerate-key --regeneration-period P30D --resource-id "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageServiceName"

        # Set shared access signature (SAS) definition in key vault
        az keyvault storage sas-definition create --vault-name $keyVaultName --account-name $storageServiceName -n $storageServiceSasTemplate --validity-period P2D --sas-type account --template-uri $storageServiceSasTemplate
        
        # Store the SAS token in Key Vault
        az keyvault secret set --vault-name $keyVaultName --name "StorageSasToken" --value $sasToken --output none

        Write-Host "Key Vault '$keyVaultName' secret 'StorageSasToken' created successfully."
        Write-Log -message "Key Vault '$keyVaultName' secret 'StorageSasToken' created successfully."

        #az keyvault storage sas-definition show --id https://<YourKeyVaultName>.vault.azure.net/storage/<YourStorageAccountName>/sas/<YourSASDefinitionName>
    }
    catch {
        Write-Error "Failed to create Key Vault '$keyVaultName' secret 'StorageSasToken': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Key Vault '$keyVaultName' secret 'StorageSasToken': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create secrets in Key Vault
function Set-KeyVaultSecrets {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName
    )

    Write-Host "Executing Set-KeyVaultSecrets function..." -ForegroundColor Magenta

    # Loop through the array of secrets and store each one in the Key Vault
    foreach ($property in $global:keyVaultSecrets.PSObject.Properties) {
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

    Write-Host "Executing Set-RBACRoles function..." -ForegroundColor Magenta

    try {
        $ErrorActionPreference = 'Stop'
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

        # Retrieve the Object ID of the user-assigned managed identity
        $userAssignedIdentityObjectId = az identity show --name $userAssignedIdentityName --resource-group $resourceGroupName --query 'principalId' --output tsv

        # Define the roles to check
        $roles = @("Key Vault Administrator", "Key Vault Secrets User", "Key Vault Certificate User", "Key Vault Crypto User")

        # Get all current role assignments for the managed identity in the given scope
        $assignedRolesOutput = az role assignment list --assignee $userAssignedIdentityObjectId --scope $scope --query "[].roleDefinitionName" --output tsv
        $assignedRoles = $assignedRolesOutput -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        # Log roles that are already assigned
        foreach ($role in ($roles | Where-Object { $assignedRoles -contains $_ })) {
            Write-Host "Role '$role' is already assigned to '$userAssignedIdentityName'."
            Write-Log -message "Role '$role' is already assigned to '$userAssignedIdentityName'." -logFilePath $global:LogFilePath
        }

        # Filter to only roles that haven't been assigned yet
        $rolesToAssign = $roles | Where-Object { $assignedRoles -notcontains $_ }

        # Loop through each role that still needs to be assigned
        foreach ($role in $rolesToAssign) {
            az role assignment create --role $role --assignee $userAssignedIdentityObjectId --scope $scope
            Write-Host "Assigned role '$role' to managed identity: '$userAssignedIdentityName'."
            Write-Log -message "Assigned role '$role' to managed identity: '$userAssignedIdentityName'." -logFilePath $global:LogFilePath
        }
    }
    catch {
        Write-Error "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to show existing resource deployment status
function Show-ExistingResourceProvisioningStatus {

    $jsonOutput = az resource list --resource-group $resourceGroup.Name  --output json

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

    Write-Host "Executing Start-Deployment function..." -ForegroundColor Magenta

    $ErrorActionPreference = 'Stop'

    # Initialize the deployment path
    $global:deploymentPath = Reset-DeploymentPath

    $global:LogFilePath = "$global:deploymentPath/deployment.log"

    Set-Location -Path $global:deploymentPath

    # Initialize the existing resources array
    $global:existingResources = @()

    $global:resourceCounter = 0
    $global:resourceSuffix = 1

    $global:parametersFile = "parameters.json"

    # Initialize parameters
    #$initParams = Initialize-Parameters -parametersFile $parametersFile
    $parameters = Initialize-Parameters -parametersFile $parametersFile
    
    # Alphabetize the parameters object
    $parameters = Get-ParametersSorted -Parameters $parameters | ConvertTo-Json -Depth 100
    $parametersObj = $parameters | ConvertFrom-Json

    if ($global:appDeploymentOnly -eq $false) {
    
        # Need to install VS Code extensions before executing main deployment script
        Install-Extensions

        # Install Azure CLI
        Install-AzureCLI

        # Login to Azure
        Initialize-Azure-Login

    }
    
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
    $startTime = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"
    $startTimeNumber = Get-Date

    $startTimeMessage = "*** SCRIPT START TIME: $startTime ***"
    Add-Content -Path $logFilePath -Value $startTimeMessage

    #Write-Host "Getting initial value '$($global:resourceGroup.Name)' for global variable 'resourceGroup.Name' and setting local 'resourceGroupName' variable with that value." -ForegroundColor Cyan

    $resourceGroupName = $global:resourceGroup.Name

    $global:currentResourceGroupName = $resourceGroupName

    if ($global:appDeploymentOnly -eq $true) {

        # Update configuration file for web frontend
        Update-ConfigFile -resourceGroupName $resourceGroupName -configFilePath "app/frontend/config.json"
        
        # Deploy web app and function app services
        foreach ($appService in $appServices) {
            Deploy-AppService -appService $appService -resourceGroupName $resourceGroupName -deployZipResources $true

            #New-App-Registration -appServiceName $appService.Name -resourceGroupName $resourceGroup.Name -keyVaultName $global:keyVaultName -appServiceUrl $appService.Url -appRegRequiredResourceAccess $global:appRegRequiredResourceAccess -exposeApiScopes $global:exposeApiScopes -parametersFile $global:parametersFile
        }

        return
    }

    # Register required resource providers
    Register-ResourceProviders

    if ($global:appendUniqueSuffix -eq $true) {

        # Find a unique suffix
        $global:resourceSuffix = Get-UniqueSuffix -resourceGroupName $resourceGroupName -useGuid $global:useGuid -parameters $parametersObj

        #$global:resourceSuffix = 1

        $newUniqueResourceGroupName = "$resourceGroupName-$global:resourceSuffix"

        Write-Host "Setting newly generated globally unique value '$newUniqueResourceGroupName' to global variable 'resourceGroup.Name' and setting local 'resourceGroupName' variable to that value." -ForegroundColor Cyan

        $global:resourceGroup.Name = $newUniqueResourceGroupName

        Write-Host "Setting local 'resourceGroupName' variable to '$newUniqueResourceGroupName'." -ForegroundColor Cyan

        $resourceGroupName = $global:resourceGroup.Name

        Initialize-Parameters -parametersFile $global:parametersFile -updatedResourceList $global:resourceList

        Update-ParametersFile -parametersFile $global:parametersFile

    }

    #$resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName
    $resourceGroupExists = az group exists --resource-group $resourceGroupName
    
    if ($deleteResourceGroup -eq $true) {
        # Delete existing resource groups with the same name
        Remove-ResourceGroup -resourceGroupName $resourceGroupName

        $resourceGroupExists = $false
    }

    if ($resourceGroupExists -eq $true) {
        Write-Host "Resource Group '$resourceGroupName' already exists." -ForegroundColor Blue
        Write-Log -message "Resource Group '$resourceGroupName' already exists." -logFilePath $logFilePath
    }
    else {
        New-ResourceGroup -resourceGroup $global:resourceGroup -resourceGroupExists $false
    }

    #return

    $global:existingResources = az resource list --resource-group $resourceGroupName --query "[].name" --output tsv | Sort-Object

    # Show-ExistingResourceProvisioningStatus
    
    Reset-DeploymentPath

    $userPrincipalName = $global:userPrincipalName

    #**********************************************************************************************************************
    # Create User Assigned Identity

    $userAssignedIdentityName = $global:userAssignedIdentity.Name

    if ($existingResources -notcontains $userAssignedIdentityName) {
        New-ManagedIdentity -userAssignedIdentity $global:userAssignedIdentity -resourceGroupName $resourceGroupName
    }
    else {
        Write-Host "Identity '$userAssignedIdentityName' already exists." -ForegroundColor Blue
        Write-Log -message "Identity '$userAssignedIdentityName' already exists."
    }
   
    # Create new Azure resources
    New-Resources -resourceGroup $global:resourceGroup `
        -storageService $global:storageService `
        -virtualNetwork $global:virtualNetwork `
        -subNet $global:subNet `
        -appServicePlan $global:appServicePlan `
        -cognitiveService $global:cognitiveService `
        -searchService $global:searchService `
        -searchSkillSets $global:searchSkillSets `
        -logAnalyticsWorkspace $global:logAnalyticsWorkspace `
        -appInsightsService $global:appInsightsService `
        -openAIService $global:openAIService `
        -containerRegistry $global:containerRegistry `
        -documentIntelligenceService $global:documentIntelligenceService `
        -computerVisionService $global:computerVisionService `
        -apiManagementService $global:apiManagementService `
        -existingResources $existingResources

    # Create new web app and function app services
    foreach ($appService in $appServices) {
        $appServiceName = $appService.Name
        if ($existingResources -notcontains $appService.Name) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -userAssignedIdentityName $global:userAssignedIdentity.Name -storageServiceName $global:storageService.Name -appInsightsName $global:appInsightsService.Name -deployZipResources $false

            $appId = az webapp show --name $appServiceName --resource-group $resourceGroupName --query "id" --output tsv
            Write-Host "App ID for $($appServiceName): $appId"
        }
    }

    #**********************************************************************************************************************
    # Create Key Vault

    New-KeyVault -keyVault $global:keyVault -resourceGroupName $resourceGroupName -existingResources $existingResources

    # Create Key Vault Roles
    Set-RBACRoles -userAssignedIdentity $global:userAssignedIdentity.Name -resourceGroupName $resourceGroupName

    # Create a new AI Hub and Model
    New-AIHub -aiHub $global:aiHub -resourceGroupName $resourceGroupName -existingResources $existingResources

    # Create Key Vault Secrets
    Set-KeyVaultSecrets -keyVaultName $global:keyVault.Name -resourceGroupName $resourceGroupName

    # The CLI needs to be updated to allow Azure AI Studio projects to be created correctly.
    # This code will create a new workspace in ML Studio but not in AI Studio.
    # I am still having this code execute so that the rest of the script doesn't error out.
    # Once the enture script completes the code will delete the ML workspace.
    # This is admittedly a hack but it is the only way to get the script to work for now.

    # 2025-02-09 ADS: THE ABOVE COMMENT IS NO LONGER VALID. THE CLI HAS BEEN UPDATED TO ALLOW FOR AI STUDIO PROJECTS TO BE CREATED CORRECTLY.
    # I AM KEEPING THE COMMENT ABOVE FOR POSTERITY.

    # Create AI Studio AI Project / ML Studio Workspace

    New-MachineLearningWorkspace -aiProject $global:aiProject `
        -aiHubName $global:aiHub.Name `
        -appInsightsName $global:appInsightsService.Name `
        -containerRegistryName $global:containerRegistry.Name `
        -userAssignedIdentityName $global:userAssignedIdentity.Name `
        -storageServiceName $global:storageService.Name `
        -keyVaultName $global:keyVault.Name `
        -resourceGroupName $resourceGroupName `
        -existingResources $global:existingResources

    Start-Sleep -Seconds 10

    $aiHubConnections = @(
        @{ resourceType = "AIService"; serviceProperties = $global:aiService },
        @{ resourceType = "OpenAIService"; serviceProperties = $global:openAIService },
        @{ resourceType = "StorageAccount"; serviceProperties = $global:storageService },
        @{ resourceType = "SearchService"; serviceProperties = $global:searchService }
    )

    $existingConnections = az ml connection list --workspace-name $global:aiProjectName --resource-group $resourceGroupName --query "[].name" --output tsv

    foreach ($conn in $aiHubConnections) {
        $serviceName = $conn.serviceProperties.Name
        $connExists = $existingConnections -contains $serviceName
        $aiHubName = $global:aiHub.Name
        $resourceType = $conn.resourceType
        $aiProjectName = $global:aiProject.Name

        if ($connExists -eq $false) {
            New-AIHubConnection `
                -aiHubName $aiHubName `
                -aiProjectName $aiProjectName `
                -resourceGroupName $resourceGroupName `
                -resourceType $resourceType `
                -serviceProperties $conn.serviceProperties
        }
        else {
            Write-Host "Azure $resourceType '$serviceName' connection for '$aiHubName' already exists." -ForegroundColor Blue
            Write-Log -message "Azure $resourceType '$serviceName' connection for '$aiHubName' already exists." -logFilePath $global:LogFilePath
        }
    }
    
    Deploy-OpenAIModels -aiProject $global:aiProject -aiServiceName $global:openAIService.Name -aiModels $global:aiModels -resourceGroupName $resourceGroupName -existingResources $existingResources

    # Remove the Machine Learning Workspace
    #Remove-MachineLearningWorkspace -resourceGroupName $resourceGroup.Name -aiProjectName $aiProjectName

    # Update configuration file for web frontend
    Update-ConfigFile - configFilePath "app/frontend/config.json" -resourceGroupName $resourceGroupName

    # Deploy web app and function app services
    foreach ($appService in $appServices) {
        if ($existingResources -notcontains $appService.Name) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -userAssignedIdentityName $global:userAssignedIdentity.Name -storageServiceName $global:storageService.Name -appInsightsName $global:appInsightsService.Name -deployZipResources $true
        }
            
        if ($appService.Name -ne $global:functionAppService.Name) {
            New-AppRegistration -appServiceName $appService.Name -resourceGroupName $resourceGroupName -keyVaultName $global:keyVault.Name -appServiceUrl $appService.Url -parametersFile $global:parametersFile
            
            $appServiceName = $appService.Name

            #$appId = az webapp show --name $appService.Name --resource-group $resourceGroup.Name --query "id" --output tsv
            $appId = az ad app list --filter "displayName eq '$($appServiceName)'" --query "[].appId" --output tsv
            
            #Write-Host "App ID for $($appServiceName): $appId"

            # Executing this function again because now that the app service has been created, the app ID is available and therefore the SharePoint datasource can be created.
            $dataSources = Get-SearchDataSources -resourceGroupName $resourceGroupName -searchServiceName $global:searchService.Name

            foreach ($searchDataSource in $global:searchDataSources) {
                $searchDataSourceName = $searchDataSource.Name
                $dataSourceExists = $dataSources -contains $searchDataSourceName

                if ($dataSourceExists -eq $false) {
                    New-SearchDataSource -searchService $global:searchService -resourceGroupName $resourceGroupName -searchDataSource $searchDataSource -storageService $global:storageService -appId $appId
                }
                else {
                    Write-Host "Search Service Data Source '$searchDataSourceName' already exists." -ForegroundColor Blue
                    Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
                }
            }
        }
    }

    #**********************************************************************************************************************
    # Create API Management Service

    # Commenting out for now because this resource is not being used in the deployment and it takes way too long to provision
    New-ApiManagementService -apiManagementService $apiManagementService -resourceGroupName $resourceGroupName -existingResources $existingResources -keyVaultName $global:keyVault.Name

    # Set $global:previousFullResourceBaseName to the $currentResourceBaseName for use during the next deployment
    $global:previousFullResourceBaseName = $global:currentFullResourceBaseName

    $parametersFileContent = Get-Content -Path $parametersFile -Raw | ConvertFrom-Json

    $parametersFileContent.previousFullResourceBaseName = $global:previousFullResourceBaseName

    # Save the updated parameters back to the parameters.json file
    $parametersFileContent | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

    # End the timer
    $endTime = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"
    $endTimeNumber = Get-Date

    $executionTime = $endTimeNumber - $startTimeNumber

    $endTimeMessage = "*** SCRIPT END TIME: $endTime ***"
    Add-Content -Path $logFilePath -Value $endTimeMessage

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
function Start-SearchIndexer {
    param (
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexerName
    )

    #Write-Host "Executing Start-SearchIndexer function..." -ForegroundColor Magenta

    # try {
    #     $ErrorActionPreference = 'Stop'

    #     $searchServiceApiKey = az search admin-key show --resource-group $resourceGroup.Name --service-name $searchServiceName --query "primaryKey" --output tsv

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

    Write-Host "Executing Test-DirectoryExists function..." -ForegroundColor Yellow

    if (-not (Test-Path -Path $directoryPath -PathType Container)) {
        New-Item -ItemType Directory -Path $directoryPath
    }
}

# The Test-ResourceGroupExists function checks if a specified Azure resource group exists. If it does, the function appends a suffix to the resource group name and checks again. This process continues until a unique resource group name is found.
function Test-ResourceGroupExists {
    param (
        [string]$resourceGroupName
    )

    Write-Host "Executing Test-ResourceGroupExists ('$resourceGroupName') function..." -ForegroundColor Yellow

    $resourceGroupExists = az group exists --resource-group $resourceGroupName --output tsv

    if ($resourceGroupExists -eq $true) {
        return $true
    }
    else {
        return $false
    }
}

# Function to check if a resource exists
function Test-ResourceExists {
    param (
        [string]$resourceName,
        [string]$resourceGroupName,
        [string]$resourceType
    )

    Write-Host "Executing Test-ResourceExists function..." -ForegroundColor Yellow

    if ($global:resourceTypes -contains $resourceType) {
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

    #Write-Host "Executing Test-SubNetExists function..." -ForegroundColor Magenta
    
    try {
        $subNetExists = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[?name=='$subnetName'].name" --output tsv
        
        if ($subNetExists) {
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
        [string]$resourceType,
        [string]$resourceGroupName,
        [string]$serviceName,
        [string]$serviceProperties
    )

    Write-Host "Executing Update-AIConnectionFile ('$serviceName') function..." -ForegroundColor Yellow

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
    $location = $servicePropertiesHashtable['Location'].Replace(" ", "").ToLower()
    $azureEndpoint = "https://$location.api.cognitive.microsoft.com/"

    $filePath = "$rootPath/$yamlFileName"

    switch ($resourceType) {
        "AIService" {
            $endpoint = "https://$serviceName.cognitiveservices.azure.com"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"
            $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiService.Name

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
            $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:openAIServiceName

            $content = @"
name: $serviceName
type: azure_open_ai
azure_endpoint: $azureEndpoint
api_key: $apiKey
"@
        }
        "SearchService" {
            $endpoint = "https://$serviceName.search.windows.net"
            #$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup.Name/providers/Microsoft.CognitiveServices/accounts/$serviceName"

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
            $content = @"
name: $serviceName
type: azure_blob
url: $endpoint
container_name: $containerName
account_name: $serviceName
"@
        }
    }

    try {
        $content | Out-File -FilePath $yamlFileName -Encoding utf8 -Force
        Write-Host "File '$yamlFileName' created and populated." -ForegroundColor Green
        Write-Log -message "File '$yamlFileName' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to '$yamlFileName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to '$yamlFileName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    return $filePath
}

# Function to update the config file
function Update-ConfigFile {
    param (
        [string]$configFilePath,
        [string]$resourceGroupName
    )

    Write-Host "Executing Update-ConfigFile function..." -ForegroundColor Yellow

    try {

        $functionApp = $global:appServices | Where-Object { $_.type -eq 'Function' } | Select-Object -First 1
        $appService = $global:appServices | Where-Object { $_.type -eq 'Web' } | Select-Object -First 1
       
        $storageServiceName = $global:storageService.Name
        $searchServiceName = $global:searchService.Name
        $openAIServiceName = $global:openAIService.Name
        $aiServiceName = $global:aiService.Name
        $functionAppName = $functionApp.Name
        $appServiceName = $appService.Name

        $fullResourceBaseName = $global:newFullResourceBaseName

        $storageKey = az storage account keys list --resource-group  $resourceGroupName --account-name $storageServiceName --query "[0].value" --output tsv
        $startDate = (Get-Date).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $expirationDate = (Get-Date).AddYears(1).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $searchApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
        $openAIApiKey = az cognitiveservices account keys list --resource-group  $resourceGroupName --name $openAIServiceName --query "key1" --output tsv
        $aiServiceKey = az cognitiveservices account keys list --resource-group  $resourceGroupName --name $aiServiceName --query "key1" --output tsv
        $functionApiKey = az functionapp keys list --resource-group  $resourceGroupName --name $functionAppName --query "functionKeys.default" --output tsv
        #$functionAppUrl = az functionapp show -g  $resourceGroupName -n $functionAppName --query "defaultHostName" --output tsv
        $functionAppUrl = $functionApp.Url

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


        # Extract the 'sig' parameter value from the SAS token
        if ($storageSAS -match "sig=([^&]+)") {
            $storageSIG = $matches[1]
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
        $config.AZURE_OPENAI_SERVICE_API_KEY = $openAIApiKey
        $config.AZURE_OPENAI_SERVICE_API_VERSION = $global:openAIService.ApiVersion
        $config.AZURE_FUNCTION_API_KEY = $functionApiKey
        $config.AZURE_FUNCTION_APP_NAME = $functionAppName
        $config.AZURE_FUNCTION_APP_URL = $functionAppUrl

        $config.AZURE_APIM_SERVICE_NAME = $global:apiManagementService.Name

        if ($global:apiManagementService.SubscriptionKey) {
            $config.AZURE_APIM_SUBSCRIPTION_KEY = $global:apiManagementService.SubscriptionKey
        }

        $config.AZURE_APP_REG_CLIENT_APP_ID = $appRegistrationClientId
        $config.AZURE_APP_SERVICE_NAME = $appServiceName
        $config.AZURE_KEY_VAULT_NAME = $global:keyVault.Name
        $config.AZURE_KEY_VAULT_API_VERSION = $global:keyVault.ApiVersion
        $config.AZURE_RESOURCE_BASE_NAME = $global:resourceBaseName
        $config.AZURE_SEARCH_SERVICE_API_KEY = $searchApiKey
        $config.AZURE_SEARCH_SERVICE_API_VERSION = $global:searchService.ApiVersion
        $config.AZURE_SEARCH_SERVICE_SEMANTIC_CONFIG = "vector-profile-srch-index-$fullResourceBaseName-semantic-configuration" -join ""
        $config.AZURE_SEARCH_SERVICE_NAME = $global:searchService.Name
        $config.AZURE_SEARCH_SERVICE_URL = "https://$searchServiceName.search.windows.net"
        #Write-Output "Modified SAS Token: $storageSAS"
        $storageUrl = "https://$storageServiceName.blob.core.windows.net"
        $fullStorageUrl = "$storageUrl/content?comp=list&include=metadata&restype=container"
        $fullStorageUrlSas = "$fullStorageUrl&$storageSAS"

        $config.AZURE_STORAGE_ACCOUNT_NAME = $global:storageService.Name
        $config.AZURE_STORAGE_API_VERSION = $global:storageService.ApiVersion
        $config.AZURE_STORAGE_URL = $storageUrl
        $config.AZURE_STORAGE_FULL_URL = $fullStorageUrl
        $config.AZURE_STORAGE_FULL_URL_SAS = $fullStorageUrlSas
        $config.AZURE_STORAGE_API_KEY = $storageKey
        $config.AZURE_STORAGE_SAS = $storageSAS
        $config.AZURE_STORAGE_SAS_TOKEN.SE = $expirationDate
        $config.AZURE_STORAGE_SAS_TOKEN.SIG = $storageSIG
        $config.AZURE_STORAGE_SAS_TOKEN.SP = $storageSP
        $config.AZURE_STORAGE_SAS_TOKEN.SRT = $storageSRT
        $config.AZURE_STORAGE_SAS_TOKEN.SS = $storageSS
        $config.AZURE_STORAGE_SAS_TOKEN.ST = $startDate

        $config.AZURE_SUBSCRIPTION_ID = $global:subscriptionId

        # DALL-E-3 MODEL IS ONLY DEPLOYED TO THE AI SERVICE AND NOT OPENAI. IT WAS A MISTAKE ON MY PART BUT NOW I CAN'T GET THE MODEL TO DEPLOY TO OPENAI BECAUSE OF CAPACITY LIMITATIONS.
        # THE ONLY SUCCESSFUL DALL-E-3 DEPLOYMENT I'VE MADE TO DATE IN EASTUS WAS FOR THE 002 DEPLOYMENT. THEREFORE, EVEN THOUGH I AM SETTING THE STANDALONE OPENAI VALUES EQUAL TO THE OPENAI ONES,
        # THEY ARE NOT THE SAME AND THE OPENAI KEYS WILL NOT WORK FOR DALL-E-3. TO MITIGATE THIS, I AM USING THE APIKEY FROM THE AI SERVICE DEPLOYED TO 002 IN THE CODE DOWN BELOW AND SETTING THOSE VALUES AT THE AI MODEL LEVEL IN THE CONFIG.JSON FILE.
        $config.OPENAI_ACCOUNT_NAME = $global:openAIService.Name
        $config.OPENAI_API_KEY = $openAIApiKey
        $config.OPENAI_API_VERSION = $global:openAIService.ApiVersion
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
                    "endpoint"         = "https://$searchServiceName.search.windows.net"
                    "index_name"       = "$vectorSearchIndexName"
                    "role_information" = ""
                    "authentication"   = @{
                        "type" = "api_key"
                        "key"  = "$searchApiKey"
                    }
                }
            }
        )
            
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
                        "endpoint"       = "https://$searchServiceName.search.windows.net"
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
        # IDEALLY ALL MODELS SHOULD BE DEPLOYED TO THE OPEN AI SERVICE AND NOT JUST THE PLAIN AI SERVICE.
        # FOR SOME REASON I CAN NO LONGER DEPLOY THE DALL-E-3 MODEL TO EASTUS AND IT CAN ONLY BE DEPLOYED TO EAST SWEDEDN OR EAST AUSTRALIA.
        # FURTHERMORE, THE ONLY SUCCESSFUL DALL-E-3 DEPLOYMENT I'VE MADE TO DATE IN EASTUS WAS FOR THE 002 DEPLOYMENT.
        # UNFORTUNATELY I DEPLOYED IT TO THE AI SERVICE BY MISTAKE. 
        # SO IN ORDER TO USE DALL-E-3, FOR NOW I WILL BE USING THE APIKEY FROM THE AI SERVICE DEPLOYED TO 002 AS OPPOSED TO THE OPEN AI SERVICE FOR EACH UNIQUE WEBAPP DEPLOYMENT. 
        $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiService.Name

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

        #$config.BING_SEARCH_SERVICE.API_KEY = $global:bingSearchService.ApiKey
        #$config.BING_SEARCH_SERVICE.API_VERSION = $global:bingSearchService.ApiVersion
        #$config.BING_SEARCH_SERVICE.URL = $global:bingSearchService.Url

        # Convert the updated object back to JSON format
        $updatedConfig = $config | ConvertTo-Json -Depth 10

        # Write the updated JSON back to the file
        $updatedConfig | Set-Content -Path $configFilePath

        Write-Host "The file Config.json has been updated successfully."
        Write-Log -message "The file Config.json has been updated successfully."
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
        [psobject]$containerRegistry
    )

    Write-Host "Executing Update-ContainerRegistryFile function..." -ForegroundColor Yellow

    $containerRegistryName = $containerRegistry.Name
    $location = $containerRegistry.Location

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

    Write-Host "Executing Update-MLWorkspaceFile function..." -ForegroundColor Yellow

    $rootPath = Get-Item -Path (Get-Location).Path

    $filePath = "${rootPath}/ml.workspace.yaml"

    #$userAssignedIdentityName = $global:userAssignedIdentityName

    $assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $global:userAssignedIdentity.Name --query 'principalId' --output tsv

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

function Update-ParametersFile {
    param (
        [string]$parametersFile
    )

    Write-Host "Executing Update-ParametersFile function..." -ForegroundColor Yellow

    try {
        $ErrorActionPreference = 'Stop'

        # Read the existing parameters.json file
        $parametersObj = Get-Content -Path $parametersFile -Raw | ConvertFrom-Json

        $parametersObj.resourceGroupName = $global:currentResourceGroupName
        $parametersObj.fullResourceBaseName = $global:newFullResourceBaseName
        $parametersObj.resourceGroup.Name = $global:resourceGroupName

        # Update the parameters with new values

        foreach ($resource in $global:resourceList) {
            $parametersResource = $parametersObj.PSObject.Properties | Where-Object { $_.Name -eq $resource.CurrentName }
            $parametersResource.Name = $resource.Name
        }

        # Convert the updated parameters back to JSON
        $updatedParametersJson = $parametersObj | ConvertTo-Json -Depth 10

        # Write the updated JSON back to the parameters.json file
        Set-Content -Path $parametersFile -Value $updatedParametersJson

        Write-Host "The parameters.json file has been updated successfully." -ForegroundColor Green
        Write-Log -message "The parameters.json file has been updated successfully."

        Initialize-Parameters -parametersFile $parametersFile -updatedResourceList $global:resourceList
    }
    catch {
        Write-Error "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to update parameters.json with new values from app registration
function Update-ParametersFileAppRegistration {
    param (
        [string]$parametersFile,
        [string]$appId,
        [string]$appUri
    )

    Write-Host "Executing Update-ParametersFileAppRegistration function..." -ForegroundColor Yellow

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

        Write-Host "The parameters.json file has been updated successfully." -ForegroundColor Green
        Write-Log -message "The parameters.json file has been updated successfully."
    }
    catch {
        Write-Error "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to update parameters.json: (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to update the parameters.json file with the latest API versions. NOTE: This function is not currently used.
function Update-ParameterFileApiVersions {

    Write-Host "Executing Update-ParameterFileApiVersions function..." -ForegroundColor Yellow

    # NOTE: Code below seems to get older API versions for some reason. This function will not be used until I can investigate further.

    # Load parameters from the JSON file
    $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Get the latest API versions in order to Update the parameters.json file
    $storageApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Storage" -resourceType "storageAccounts"
    $openAIApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    $searchServiceAPIVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Search" -resourceType "searchServices"
    $aiServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    $cognitiveServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"

    $parametersObject.storageService.ApiVersion = $storageApiVersion
    $parametersObject.openAIService.ApiVersion = $openAIApiVersion
    $parametersObject.searchService.APIVersion = $searchServiceAPIVersion
    $parametersObject.aiService.ApiVersion = $aiServiceApiVersion
    $parametersObject.cognitiveService.ApiVersion = $cognitiveServiceApiVersion

    # Convert the updated parameters object back to JSON and save it to the file
    $parametersObject | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

}

# Function to udpate the configuration file with new resource base name.
function Update-ResourceBaseName() {
    param (
        [string]$newResourceBaseName = "copilot-demo"
    )

    Write-Host "Executing Update-ResourceBaseName ('$newResourceBaseName') function..." -ForegroundColor Yellow

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
    $parametersFileContent.fullResourceBaseName = $global:newFullResourceBaseName

    # Update the previousResourceBaseName in the parameters file with the value stored in currentResourceBaseName
    $parametersFileContent.resourceBaseName = $newResourceBaseName

    $global:newFullResourceBaseNameUpperCase = $global:newFullResourceBaseName.ToUpper()
    $parametersFileContent.resourceGroupName = "RG-$global:newFullResourceBaseNameUpperCase"

    $parametersFileContent | ForEach-Object {
        $_.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [string]) {
                $_.Value = $_.Value -replace [regex]::Escape($fullResourceBaseName), $global:newFullResourceBaseName
            }
        }
    }

    # Save the updated parameters back to the parameters.json file
    $parametersFileContent | ConvertTo-Json -Depth 10 | Set-Content -Path $parametersFile

    $global:newFullResourceBaseNameNoHyphen = $global:newFullResourceBaseName -replace "-", ""
    $currentFullResourceBaseNameNoHyphen = $fullResourceBaseName -replace "-", ""

    # Replace all instances of currentResourceBaseName with the value stored in $resourceBaseName parameter
    $fileContent = Get-Content -Path $parametersFile

    $fileContent = $fileContent -replace $currentFullResourceBaseNameNoHyphen, $global:newFullResourceBaseNameNoHyphen
    $fileContent = $fileContent -replace $currentFullResourceBaseName, $global:newFullResourceBaseName

    Set-Content -Path $parametersFile -Value $fileContent
}

# Function to update search index files (not currently used)
function Update-SearchIndexFiles {
    param (
        [string]$resourceGroupName,
        [pspbject]$searchService
    )

    $location = $searchService.Location.Replace(" ", "").ToLower()
    $previousLocation = $searchService.PreviousLocation.Replace(" ", "").ToLower()

    $endpoint = "https://$location.api.cognitive.microsoft.com/"
    $previousEndpoint = "https://$previousLocation.api.cognitive.microsoft.com/"

    Write-Host "Executing Update-SearchIndexFiles function..." -ForegroundColor Yellow

    $searchIndexFiles = @("search-index-schema-template.json,search-indexer-schema-template.json,vector-search-index-schema-template.json,vector-search-indexer-schema-template.json,embeddings-search-index-schema-template.json,embeddings-search-indexer-schema-template.json,sharepoint-search-index-schema-template.json,sharepoint-search-indexer-schema-template.json" )

    foreach ($fileName in $searchIndexFiles) {
        $searchIndexFilePath = $fileName -replace "-template", ""

        $content = Get-Content -Path $fileName

        $updatedContent = $content -replace $global:previousFullResourceBaseName, $global:fullResourceBaseName

        $updatedContent = $updatedContent -replace $endpoint, $previousEndpoint

        Set-Content -Path $searchIndexFilePath -Value $updatedContent
    }
}

# Function to update search skill set files
function Update-SearchSkillSetFiles {

    Write-Host "Executing Update-SearchSkillSetFiles function..." -ForegroundColor Yellow

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
    $timestamp = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"
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
