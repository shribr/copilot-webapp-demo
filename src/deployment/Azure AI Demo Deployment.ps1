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
    [string]$parametersFile = "parameters.json"
)

# Mapping of global resource types
$global:ResourceTypes = @(
    "Microsoft.Storage/storageAccounts",
    "Microsoft.KeyVault/vaults",
    "Microsoft.Sql/servers",
    "Microsoft.DocumentDB/databaseAccounts",
    "Microsoft.Web/serverFarms",
    "Microsoft.Web/sites",
    "Microsoft.DataFactory/factories",
    "Microsoft.ContainerRegistry/registries",
    "Microsoft.CognitiveServices/accounts",
    "Microsoft.Search/searchServices",
    "Microsoft.ApiManagement",
    "Microsoft.ContainerRegistry",
    "microsoft.alertsmanagement/alerts",
    "microsoft.insights/actiongroups"
)

$global:AIHubConnectedResources = @()

# List of all KeyVault secret keys
$global:KeyVaultSecrets = @(
    “AzureOpenAiChatGptDeployment”, 
    “AzureOpenAiEmbeddingDeployment”, 
    “AzureOpenAiServiceEndpoint”, 
    “AzureSearchIndex”, 
    “AzureSearchServiceEndpoint”, 
    “AzureStorageAccountEndpoint”, 
    “AzureStorageContainer”, 
    “UseAOAI”, 
    “UseVision”
)

# Initialize the deployment path
$global:deploymentPath = Get-Location

# Initialize the deployment path
$currentLocation = Get-Location
if ($currentLocation.Path -notlike "*src/deployment*") {
    $global:deploymentPath = Join-Path -Path $currentLocation -ChildPath "src/deployment"
}
else {
    $global:deploymentPath = $currentLocation
}

$global:LogFilePath = "$global:deploymentPath/deployment.log"
$global:ConfigFilePath = "$global:deploymentPath/app/frontend/config.json"

Set-Location -Path $global:deploymentPath

# Initialize the existing resources array
$global:existingResources = @()

# function to convert string to proper case
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

function Format-AIModelErrorInfo {
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

    <#
 # {    # Convert the hashtable to an array of key-value pairs
    $array = @()
    foreach ($entry in $properties.GetEnumerator()) {
        $array += [PSCustomObject]@{
            Key   = $entry.Key
            Value = $entry.Value
        }
    }

    # Output the array
    $array | Format-Table -AutoSize:Enter a comment or description}
#>

    return $properties
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
        Write-Error "Failed to query search indexes: $_"
        return $false
    }
   
    <#
 # {    try {
        # List data sources in the search service
        $dataSources = az rest --method get --url "https://$searchServiceName.search.windows.net/datasources?api-version=2024-07-01" --headers "apikey=$apiKey"  --output tsv
        $dataSources = az rest --method get --uri "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName/datasources/?api-version=2024-07-01" --headers "apikey=$apiKey" --output tsv
    
        # Check if the data source exists
        if ($dataSources -contains $dataSourceName) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Write-Error "Failed to query search data sources: $_"
        return $false
    }:Enter a comment or description}
#>
    
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
        $indexes = $response.value | Select-Object -ExpandProperty name
        return $indexes
    }
    catch {
        Write-Error "Failed to query search indexes: $_"
        return $false
    }
}

# Function to find a unique suffix and create resources
function Get-UniqueSuffix {
    param (
        [int]$resourceSuffix,
        [string]$resourceGroupName
    )

    $appResourceExists = $true

    do {
        $storageAccountName = "$($parameters.storageAccountName)$resourceGuid$resourceSuffix"
        $appServicePlanName = "$($parameters.appServicePlanName)-$resourceGuid-$resourceSuffix"
        $searchServiceName = "$($parameters.searchServiceName)-$resourceGuid-$resourceSuffix"
        $logAnalyticsWorkspaceName = "$($parameters.logAnalyticsWorkspaceName)-$resourceGuid-$resourceSuffix"
        $cognitiveServiceName = "$($parameters.cognitiveServiceName)-$resourceGuid-$resourceSuffix"
        $keyVaultName = "$($parameters.keyVaultName)-$resourceGuid-$resourceSuffix"
        $appInsightsName = "$($parameters.appInsightsName)-$resourceGuid-$resourceSuffix"
        $portalDashboardName = "$($parameters.portalDashboardName)-$resourceGuid-$resourceSuffix"
        $managedEnvironmentName = "$($parameters.managedEnvironmentName)-$resourceGuid-$resourceSuffix"
        $userAssignedIdentityName = "$($parameters.userAssignedIdentityName)-$resourceGuid-$resourceSuffix"
        $openAIName = "$($parameters.openAIName)-$resourceGuid-$resourceSuffix"
        $documentIntelligenceName = "$($parameters.documentIntelligenceName)-$resourceGuid-$resourceSuffix"
        $aiHubName = "$($aiHubName)-$($resourceGuid)-$($resourceSuffix)"
        $aiModelName = "$($aiModelName)-$($resourceGuid)-$($resourceSuffix)"
        $aiServiceName = "$($aiServiceName)-$($resourceGuid)-$($resourceSuffix)"

        foreach ($appService in $appServices) {
            $appService.Name = "$($appService.Name)-$($resourceGuid)-$($resourceSuffix)"
        }
        
        $resourceExists = Test-ResourceExists $storageAccountName "Microsoft.Storage/storageAccounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $appServicePlanName "Microsoft.Web/serverFarms" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $searchServiceName "Microsoft.Search/searchServices" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $logAnalyticsWorkspaceName "Microsoft.OperationalInsights/workspaces" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $cognitiveServiceName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $keyVaultName "Microsoft.KeyVault/vaults" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $appInsightsName "Microsoft.Insights/components" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $portalDashboardName "Microsoft.Portal/dashboards" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $managedEnvironmentName "Microsoft.App/managedEnvironments" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $userAssignedIdentityName "Microsoft.ManagedIdentity/userAssignedIdentities" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $openAIName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        Test-ResourceExists $documentIntelligenceName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName

        foreach ($appService in $appServices) {
            $appResourceExists = Test-ResourceExists $appServiceName $appService.Name -resourceGroupName $resourceGroupName -or $resourceExists
            if ($appResourceExists) {
                $resourceExists = $true
                break
            }
        }

        if ($resourceExists) {
            $resourceSuffix++
        }
    } while ($resourceExists)

    <#
    # {    $userPrincipalName = "$($parameters.userPrincipalName)"

        New-Resources -storageAccountName $storageAccountName `
            -appServicePlanName $appServicePlanName `
            -searchServiceName $searchServiceName `
            -logAnalyticsWorkspaceName $logAnalyticsWorkspaceName `
            -cognitiveServiceName $cognitiveServiceName `
            -keyVaultName $keyVaultName `
            -appInsightsName $appInsightsName `
            -portalDashboardName $portalDashboardName `
            -managedEnvironmentName $managedEnvironmentName `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -openAIName $openAIName `
            -documentIntelligenceName $documentIntelligenceName

        foreach ($appService in $appServices) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName
        }

        New-AIHubAndModel -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -location $location
    :Enter a comment or description}
    #>
    return $resourceSuffix
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

# Function to install Visual Studio Code extensions
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

# Initialize the parameters
function Initialize-Parameters {
    param (
        [string]$parametersFile = "parameters.json"
    )

    # Navigate to the project directory
    Set-DirectoryPath -targetDirectory $global:deploymentPath
        
    # Load parameters from the JSON file
    $parametersObject = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Initialize global variables for each item in the parameters.json file
    $global:aiHubName = $parametersObject.aiHubName
    $global:aiModelName = $parametersObject.aiModelName
    $global:aiModelType = $parametersObject.aiModelType
    $global:aiModelVersion = $parametersObject.aiModelVersion
    $global:aiServiceName = $parametersObject.aiServiceName
    $global:aiProjectName = $parametersObject.aiProjectName
    $global:apiManagementService = $parametersObject.apiManagementService
    $global:appendUniqueSuffix = $parametersObject.appendUniqueSuffix
    $global:appServicePlanName = $parametersObject.appServicePlanName
    $global:appServices = $parametersObject.appServices
    $global:appInsightsName = $parametersObject.appInsightsName
    $global:blobStorageAccountName = $parametersObject.blobStorageAccountName
    $global:blobStorageContainerName = $parametersObject.blobStorageContainerName
    $global:computerVisionName = $parametersObject.computerVisionName
    $global:configFilePath = $parametersObject.configFilePath
    $global:cognitiveServiceName = $parametersObject.cognitiveServiceName
    $global:containerAppName = $parametersObject.containerAppName
    $global:containerAppsEnvironmentName = $parametersObject.containerAppsEnvironmentName
    $global:containerRegistryName = $parametersObject.containerRegistryName
    $global:cosmosDbAccountName = $parametersObject.cosmosDbAccountName
    $global:createResourceGroup = $parametersObject.createResourceGroup
    $global:deleteResourceGroup = $parametersObject.deleteResourceGroup
    $global:deployZipResources = $parametersObject.deployZipResources
    $global:documentIntelligenceName = $parametersObject.documentIntelligenceName
    $global:eventHubNamespaceName = $parametersObject.eventHubNamespaceName
    $global:keyVaultName = $parametersObject.keyVaultName
    $global:location = $parametersObject.location
    $global:logAnalyticsWorkspaceName = $parametersObject.logAnalyticsWorkspaceName
    $global:managedIdentityName = $parametersObject.managedIdentityName
    $global:openAIName = $parametersObject.openAIName
    $global:portalDashboardName = $parametersObject.portalDashboardName
    $global:privateEndPointName = $parametersObject.privateEndPointName
    $global:redisCacheName = $parametersObject.redisCacheName
    $global:resourceGroupName = $parametersObject.resourceGroupName
    $global:resourceSuffix = $parametersObject.resourceSuffix
    $global:restoreSoftDeletedResource = $parametersObject.restoreSoftDeletedResource
    $global:searchDataSourceName = $parametersObject.searchDataSourceName
    $global:searchServiceName = $parametersObject.searchServiceName
    $global:searchIndexName = $parametersObject.searchIndexName
    $global:searchIndexFieldNames = $parametersObject.searchIndexFieldNames
    $global:searchIndexerName = $parametersObject.searchIndexerName
    $global:serviceBusNamespaceName = $parametersObject.serviceBusNamespaceName
    $global:sharedDashboardName = $parametersObject.sharedDashboardName
    $global:siteLogo = $parametersObject.siteLogo
    $global:sqlServerName = $parametersObject.sqlServerName
    $global:storageAccountName = $parametersObject.storageAccountName
    $global:subNetName = $parametersObject.subNetName
    $global:userAssignedIdentityName = $parametersObject.userAssignedIdentityName
    $global:virtualNetwork = $parametersObject.virtualNetwork

    $global:aiServiceProperties = $parametersObject.aiServiceProperties
    $global:containerRegistryProperties = $parametersObject.containerRegistryProperties
    $global:machineLearningProperties = $parametersObject.machineLearningProperties
    $global:searchServiceProperties = $parametersObject.searchServiceProperties
    $global:storageServiceProperties = $parametersObject.storageServiceProperties

    #$global:objectId = $parametersObject.objectId

    #**********************************************************************************************************************
    # Add the following code to the InitializeParameters function to set the subscription ID, tenant ID, object ID, and user principal name.

    # Retrieve the subscription ID
    $global:subscriptionId = az account show --query "id" --output tsv
    # Retrieve the tenant ID
    $global:tenantId = az account show --query "tenantId" --output tsv
    # Retrieve the object ID of the signed-in user
    $global:objectId = az ad signed-in-user show --query "objectId" --output tsv
    # Retrieve the user principal name
    $global:userPrincipalName = az ad signed-in-user show --query userPrincipalName --output tsv
    # Retrieve the resource GUID
    $global:resourceGuid = Split-Guid


    if ($parametersObject.PSObject.Properties.Name.Contains("objectId")) {
        $global:objectId = $parametersObject.objectId
    }
    else {
        $global:objectId = az ad signed-in-user show --query "objectId" --output tsv

        $parametersObject | Add-Member -MemberType NoteProperty -Name "objectId" -Value $global:objectId
    }
    
    #$parametersObject | Add-Member -MemberType NoteProperty -Name "subscriptionId" -Value $global:subscriptionId
    $parametersObject | Add-Member -MemberType NoteProperty -Name "tenantId" -Value $global:tenantId
    $parametersObject | Add-Member -MemberType NoteProperty -Name "userPrincipalName" -Value $global:userPrincipalName
    $parametersObject | Add-Member -MemberType NoteProperty -Name "resourceGuid" -Value $global:resourceGuid

    Write-Host "Doc Intelligence: $documentIntelligenceName"
    Write-Host "Search Service Name: $searchServiceName"

    # Debugging output
    Write-Host "searchIndexName from parametersObject: $($parametersObject.searchIndexName)"
    Write-Host "searchIndexName from global: $($global:searchIndexName)"

    return @{
        aiHubName                    = $aiHubName
        aiModelName                  = $aiModelName
        aiModelType                  = $aiModelType
        aiModelVersion               = $aiModelVersion
        aiServiceName                = $aiServiceName
        aiProjectName                = $aiProjectName
        apiManagementService         = $apiManagementService
        appendUniqueSuffix           = $appendUniqueSuffix
        appServices                  = $appServices
        appServicePlanName           = $appServicePlanName
        appInsightsName              = $appInsightsName
        blobStorageAccountName       = $blobStorageAccountName
        blobStorageContainerName     = $blobStorageContainerName
        computerVisionName           = $computerVisionName
        configFilePath               = $configFilePath
        cognitiveServiceName         = $cognitiveServiceName
        containerAppName             = $containerAppName
        containerAppsEnvironmentName = $containerAppsEnvironmentName
        containerRegistryName        = $containerRegistryName
        cosmosDbAccountName          = $cosmosDbAccountName
        createResourceGroup          = $createResourceGroup
        deleteResourceGroup          = $deleteResourceGroup
        deployZipResources           = $deployZipResources
        documentIntelligenceName     = $documentIntelligenceName
        eventHubNamespaceName        = $eventHubNamespaceName
        keyVaultName                 = $keyVaultName
        location                     = $location
        logAnalyticsWorkspaceName    = $logAnalyticsWorkspaceName
        managedIdentityName          = $managedIdentityName
        openAIName                   = $openAIName
        objectId                     = $objectId
        portalDashboardName          = $portalDashboardName
        privateEndPointName          = $privateEndPointName
        redisCacheName               = $redisCacheName
        resourceGroupName            = $resourceGroupName
        resourceGuid                 = $resourceGuid
        resourceSuffix               = $resourceSuffix
        restoreSoftDeletedResource   = $restoreSoftDeletedResource
        result                       = $result
        searchServiceName            = $searchServiceName
        searchIndexName              = $searchIndexName
        searchIndexFieldNames        = $searchIndexFieldNames
        searchIndexerName            = $searchIndexerName
        serviceBusNamespaceName      = $serviceBusNamespaceName
        searchDataSourceName         = $searchDataSourceName
        sharedDashboardName          = $sharedDashboardName
        siteLogo                     = $siteLogo
        sqlServerName                = $sqlServerName
        storageAccountName           = $storageAccountName
        subNetName                   = $subNetName
        subscriptionId               = $subscriptionId
        tenantId                     = $tenantId
        userAssignedIdentityName     = $userAssignedIdentityName
        userPrincipalName            = $userPrincipalName
        virtualNetwork               = $virtualNetwork
        aiServiceProperties          = $aiServiceProperties
        containerRegistryProperties  = $containerRegistryProperties
        machineLearningProperties    = $machineLearningProperties
        searchServiceProperties      = $searchServiceProperties
        storageServiceProperties     = $storageServiceProperties
        parameters                   = $parametersObject
    }
}

# Function to create AI Hub and AI Model
function New-AIHubAndModel {
    param (
        [string]$aiHubName,
        [string]$aiModelName,
        [string]$aiModelType,
        [string]$aiModelVersion,
        [string]$aiServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$appInsightsName,
        [array]$existingResources
    )

    Set-DirectoryPath -targetDirectory $global:deploymentPath
    
    # Create AI Hub
    if ($existingResources -notcontains $aiHubName) {
        try {
            $ErrorActionPreference = 'Stop'
            $storageAccountId = az storage account show --resource-group $resourceGroupName --name $storageAccountName --query 'id' --output tsv
            $keyVaultId = az keyvault show --resource-group $resourceGroupName --name $keyVaultName --query 'id' --output tsv
        
            az ml workspace create --kind hub --resource-group $resourceGroupName --name $aiHubName --storage-account $storageAccountId --key-vault $keyVaultId
            
            Write-Host "AI Hub: '$aiHubName' created."
            Write-Log -message "AI Hub: '$aiHubName' created." -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                try {
                    Restore-SoftDeletedResource -resourceGroupName $resourceGroupName -resourceName $aiHubName -resourceType "Microsoft.MachineLearningServices/workspaces"
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

    # Create AI Service
    if ($existingResources -notcontains $aiServiceName) {
        try {
            $ErrorActionPreference = 'Stop'
            
            az cognitiveservices account create --name $aiServiceName --resource-group $resourceGroupName --location $location --kind AIServices --sku S0 --custom-domain --output none
            
            Write-Host "AI Service: '$aiServiceName' created."
            Write-Log -message "AI Service: '$aiServiceName' created."
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                try {
                    Restore-SoftDeletedResource -resourceGroupName $resourceGroupName -resourceName $aiServiceName -resourceType "Microsoft.CognitiveServices/accounts"    
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

    # Create AI Model Deployment
    if ($existingResources -notcontains $aiModelName) {

        $modelList = az cognitiveservices model list `
            --location $location `
            --query "[].{Kind:kind, ModelName:model.name, Version:model.version, Format:model.format, LifecycleStatus:model.lifecycleStatus, MaxCapacity:model.maxCapacity, SKUName:model.skus[0].name, DefaultCapacity:model.skus[0].capacity.default}" `
            --output table | Out-String
        
        Write-Host $modelList

        try {
            $ErrorActionPreference = 'Stop'
            
            $jsonOutput = az cognitiveservices account deployment create --name $aiServiceName --resource-group $resourceGroupName --deployment-name ai --model-name gpt-4o --model-version "2024-05-13" --model-format OpenAI --sku-capacity 1 --sku-name "Standard" 2>&1

            # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message

            if ($jsonOutput -match "error") {

                $errorInfo = Format-AIModelErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create AI Model deployment '$aiModelName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                Write-Host $errorMessage
                Write-Log -message $errorMessage -logFilePath $global:LogFilePath
            }
            else {
                Write-Host "AI Model deployment: '$aiModelName' created."
                Write-Log -message "AI Model deployment: '$aiModelName' created." -logFilePath $global:LogFilePath
            }
        }
        catch {
            
            Write-Host "Failed to create AI Model deployment '$aiModelName'."
            Write-Log -message "Failed to create AI Model deployment '$aiModelName'." -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "AI Model '$aiModelName' already exists."
        Write-Log -message "AI Model '$aiModelName' already exists." -logFilePath $global:LogFilePath
    }

    # Create AI Project / ML Studio Workspace
    if ($existingResources -notcontains $aiProjectName) {
        try {
            $ErrorActionPreference = 'Stop'
            
            # https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-openai?view=azureml-api-2
            # "While the az ml connection commands can be used to manage both Azure Machine Learning and Azure AI Studio connections, the OpenAI connection is specific to Azure AI Studio."

            $mlWorkspaceFile = Update-MLWorkspaceFile `
                -aiProjectName $aiProjectName `
                -resourceGroupName $resourceGroupName `
                -appInsightsName $appInsightsName `
                -keyVaultName $keyVaultName `
                -location $location `
                -subscriptionId $subscriptionId `
                -storageAccountName $storageAccountName `
                -containerRegistryName $containerRegistryName 2>&1
            
            #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

            $jsonOutput = az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName 2>&1

            if ($jsonOutput -match "error") {

                $errorInfo = Format-AIModelErrorInfo -jsonOutput $jsonOutput

                $errorName = $errorInfo["Error"]
                $errorCode = $errorInfo["Code"]
                $errorDetails = $errorInfo["Message"]

                $errorMessage = "Failed to create AI Project '$aiProjectName'. `
        Error: $errorName `
        Code: $errorCode `
        Message: $errorDetails"

                #throw $errorMessage

                Write-Host $errorMessage
                Write-Log -message $errorMessage -logFilePath $global:LogFilePath
            }
            else {
                Write-Host "AI Project '$aiProjectName' in '$aiHubName' created."
                Write-Log -message "AI Project '$aiProjectName' in '$aiHubName' created." -logFilePath $global:LogFilePath
            }
        }
        catch {
            Write-Error "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "AI Project '$aiProjectName' already exists."
        Write-Log -message "AI Project '$aiProjectName' already exists." -logFilePath $global:LogFilePath
    }

    # Add storage account connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -resourceGroupName $resourceGroupName -resourceType "StorageService" -serviceName $storageAccountName -serviceProperties $storageServiceProperties
        
    # Add search service connection to AI Hub
    New-AIHubConnection -aiHubName $aiHubName -resourceGroupName $resourceGroupName -resourceType "SearchService" -serviceName $searchServiceName -serviceProperties $searchServiceProperties

}

function New-AIHubConnection {
    param (
        [string]$aiHubName,
        [string]$aiProjectName,
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$serviceName,
        [string]$serviceProperties
    )

    #https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-blob?view=azureml-api-2

    $existingConnections = az ml connection list --workspace-name $aiProjectName --resource-group $resourceGroupName --query "[?name=='$serviceName'].name" --output tsv

    <#
        # {    # Define the AI services and their new endpoints
            $aiServices = @{
                "aiService1" = "https://new-endpoint-1.api.cognitive.microsoft.com"
                "aiService2" = "https://new-endpoint-2.api.cognitive.microsoft.com"
                "aiService3" = "https://new-endpoint-3.api.cognitive.microsoft.com"
            }

            # Loop through each AI service and update the endpoint
            foreach ($aiServiceName in $aiServices.Keys) {
                $newEndpoint = $aiServices[$aiServiceName]
            
                az cognitiveservices account update `
                    --name $aiServiceName `
                    --resource-group $resourceGroupName `
                    --custom-domain $newEndpoint
            
                Write-Host "Updated endpoint for $aiServiceName to $newEndpoint"
            }:Enter a comment or description}
        #>
    
    if ($existingConnections -notcontains $serviceName) {
        try {
            $aiConnectionFile = Update-AIConnectionFile -resourceGroupName $resourceGroupName -aiServiceName $aiServiceName

            az ml connection create --file $aiConnectionFile --resource-group $resourceGroupName --workspace-name $aiProjectName
            
            Write-Host "Azure AI Machine Learning Hub connection '$aiHubName' created."
            Write-Log -message "Azure AI Machine Learning Hub connection '$aiHubName' created." -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                try {
                    Restore-SoftDeletedResource -resourceGroupName $resourceGroupName -resourceName $aiHubName -resourceType "Microsoft.MachineLearningServices/workspaces"    
                }
                catch {
                    Write-Error "Failed to restore soft-deleted AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore soft-deleted AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
                }
            }
            else {
                Write-Error "Failed to create Azure AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Azure AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
            }    
        }
    }
    else {              
        Write-Host "AI Hub connection for '$aiHubName' already exists."
        Write-Log -message "AI Hub connection for '$aiHubName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create and deploy API Management service
function New-ApiManagementService {
    param (
        [string]$resourceGroupName,
        [array]$apiManagementService
    )

    $apiManagementServiceName = $apiManagementService.Name

    try {
        $ErrorActionPreference = 'Stop'
        $jsonOutput = az apim create -n $apiManagementServiceName --publisher-name $apiManagementService.PublisherName --publisher-email $apiManagementService.PublisherEmail --resource-group $resourceGroupName --no-wait

        Write-Host $jsonOutput

        Write-Host "API Management service '$apiManagementServiceName' created."
        Write-Log -message "API Management service '$apiManagementServiceName' created." -logFilePath $global:LogFilePath

    }
    catch {
        Write-Error "Failed to create API Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create API Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
    }
}

# Function to create and deploy app service (either web app or function app)
function New-AppService {
    param (
        [array]$appService,
        [string]$resourceGroupName,
        [string]$storageAccountName,
        [bool]$deployZipResources
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
                }
            }
            else {

                # Check if the Function App exists
                $appExists = az functionapp show --name $appService.Name --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new function app
                    az functionapp create --name $appServiceName --resource-group $resourceGroupName --storage-account $storageAccountName --plan $appService.AppServicePlan --app-insights $appInsightsName --runtime $appService.Runtime --os-type "Windows" --functions-version 4 --output none
                    
                    $functionAppKey = az functionapp keys list --name $appServiceName --resource-group $resourceGroupName --query "functionKeys.default" --output tsv
                    az functionapp cors add --methods GET POST PUT --origins '*' --services b --account-name $appServiceName --account-key $functionAppKey
                }
            }

            if (-not $appExists) {

                Write-Host "$appServiceType app '$appServiceName' created."
                Write-Log -message "$appServiceType app '$appServiceName' created. Moving on to deployment." -logFilePath $global:LogFilePath
            }
            else {              
                Write-Host "$appServiceType app '$appServiceName' already exists. Moving on to deployment."
                Write-Log -message "$appServiceType app '$appServiceName' already exists. Moving on to deployment." -logFilePath $global:LogFilePath
            }

            if ($deployZipResources -eq $true -and $deployZipPackage -eq $true) {
                try {

                    $appRoot = Find-AppRoot -currentDirectory (Get-Location).Path

                    $tempPath = Join-Path -Path $appRoot -ChildPath "temp"

                    if (-not (Test-Path $tempPath)) {
                        New-Item -Path $tempPath -ItemType Directory
                    }

                    # Compress the function app code
                    $zipFilePath = "$tempPath/$appServiceType-$appServiceName.zip"

                    if (Test-Path $zipFilePath) {
                        Remove-Item $zipFilePath
                    }
                    
                    # compress the function app code
                    zip -r $zipFilePath * .env

                    if ($appService.Type -eq "Web") {
                        # Deploy the web app
                        #az webapp deployment source config-zip --name $appServiceName --resource-group $resourceGroupName --src $zipFilePath
                        az webapp deploy --src-path $zipFilePath --name $appServiceName --resource-group $resourceGroupName --type zip
                    }
                    else {
                        # Deploy the function app
                        az functionapp deployment source config-zip --name $appServiceName --resource-group $resourceGroupName --src $zipFilePath
                        
                        $searchServiceKeys = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
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

# Function to create key vault
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
            $ErrorActionPreference = 'Stop'
            if ($useRBAC) {
                az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $true --output none
                Write-Host "Key Vault: '$keyVaultName' created with RBAC enabled."
                Write-Log -message "Key Vault: '$keyVaultName' created with RBAC enabled."

                # Assign RBAC roles to the managed identity
                Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName
            }
            else {
                az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $false --output none
                Write-Host "Key Vault: '$keyVaultName' created with Vault Access Policies."
                Write-Log -message "Key Vault: '$keyVaultName' created with Vault Access Policies."

                # Set vault access policies for user
                Set-KeyVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
            }
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                Restore-SoftDeletedResource -resourceName $keyVaultName -resourceType "KeyVault" -resourceGroupName $resourceGroupName -useRBAC $true -userAssignedIdentityName $userAssignedIdentityName
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

        Set-KeyVaultSecrets -keyVaultName $keyVaultName `
            -resourceGroupName $resourceGroupName
    }
    else {
        Write-Host "Key Vault '$keyVaultName' already exists."
        Write-Log -message "Key Vault '$keyVaultName' already exists."
    }
}

# Function to create a new managed identity
function New-ManagedIdentity {
    param (
        [string]$userAssignedIdentityName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$subscriptionId
    )

    try {
        $ErrorActionPreference = 'Stop'
        az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none
        Write-Host "User Assigned Identity '$userAssignedIdentityName' created."
        Write-Log -message "User Assigned Identity '$userAssignedIdentityName' created."

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

# Function to create a new private endpoint
function New-PrivateEndPoint {
    param (
        [string]$privateEndpointName,
        [string]$privateLinkServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$subnetId,
        [string]$privateLinkServiceId
    )

    try {
        az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroupName --vnet-name $virtualNetworkName --subnet $subnetId --private-connection-resource-id $privateLinkServiceId --group-id "sqlServer" --connection-name $privateLinkServiceName --location $location --output none
        Write-Host "Private endpoint '$privateEndpointName' created."
        Write-Log -message "Private endpoint '$privateEndpointName' created."
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
        [string]$resourceGroupName,
        [string]$location
    )

    do {
        $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName -location $location

        if ($resourceGroupExists -eq "true") {
            Write-Host "Resource group '$resourceGroupName' already exists. Trying a new name."
            Write-Log -message "Resource group '$resourceGroupName' already exists. Trying a new name."

            $resourceSuffix++
            $resourceGroupName = "$($resourceGroupName)-$resourceSuffix"
        }

    } while ($resourceGroupExists -eq "true")

    try {
        az group create --name $resourceGroupName --location $location --output none
        Write-Host "Resource group '$resourceGroupName' created."
        $resourceGroupExists = $false
    }
    catch {
        Write-Host "An error occurred while creating the resource group."
    }

    return $resourceGroupName
}

# Function to create resources
function New-Resources {
    param (
        [string]$storageAccountName,
        [string]$blobStorageContainerName,
        [string]$appServicePlanName,
        [string]$searchServiceName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$searchDatasourceName,
        [string]$logAnalyticsWorkspaceName,
        [string]$computerVisionName,
        [string]$cognitiveServiceName,
        [string]$keyVaultName,
        [string]$appInsightsName,
        [string]$portalDashboardName,
        [string]$managedEnvironmentName,
        [string]$userAssignedIdentityName,
        [string]$userPrincipalName,
        [string]$openAIName,
        [string]$documentIntelligenceName,
        [string]$containerRegistryName,
        [array]$existingResources,
        [array]$apiManagementService
    )

    # Get the latest API versions
    #$storageApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Storage" -resourceType "storageAccounts"
    #$appServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Web" -resourceType "serverFarms"
    #$searchApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Search" -resourceType "searchServices"
    #$logAnalyticsApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.OperationalInsights" -resourceType "workspaces"
    #$cognitiveServicesApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    #$keyVaultApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.KeyVault" -resourceType "vaults"
    #$appInsightsApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Insights" -resourceType "components"

    # Debug statements to print variable values
    Write-Host "subscriptionId: $subscriptionId"
    Write-Host "resourceGroupName: $resourceGroupName"
    Write-Host "storageAccountName: $storageAccountName"
    Write-Host "appServicePlanName: $appServicePlanName"
    Write-Host "location: $location"
    Write-Host "userPrincipalName: $userPrincipalName"
    Write-Host "searchIndexName: $searchIndexName"
    Write-Host "searchIndexerName: $searchIndexerName"

    # **********************************************************************************************************************
    # Create a storage account

    if ($existingResources -notcontains $storageAccountName) {

        try {
            az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --output none
            
            Write-Host "Storage account '$storageAccountName' created."
            Write-Log -message "Storage account '$storageAccountName' created."

            # Retrieve the storage account key
            $storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv
        
            # Enable CORS
            az storage cors clear --account-name $storageAccountName --services bfqt
            az storage cors add --methods GET POST PUT --origins '*' --allowed-headers '*' --exposed-headers '*' --max-age 200 --services b --account-name $storageAccountName --account-key $storageAccessKey
            
            az storage container create --name $blobStorageContainerName --account-name $storageAccountName --account-key $storageAccessKey --output none

        }
        catch {
            Write-Error "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    else {
        Write-Host "Storage account '$storageAccountName' already exists."
        Write-Log -message "Storage account '$storageAccountName' already exists."
    }

    #$storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv
    #$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

    # **********************************************************************************************************************
    # Create an App Service Plan

    if ($existingResources -notcontains $appServicePlanName) {
        try {
            az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku B1 --output none
            Write-Host "App Service Plan '$appServicePlanName' created."
            Write-Log -message "App Service Plan '$appServicePlanName' created."
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

    # **********************************************************************************************************************
    # Create a Search Service

    az provider show --namespace Microsoft.Search --query "resourceTypes[?resourceType=='searchServices'].apiVersions"

    if ($existingResources -notcontains $searchServiceName) {
        $searchServiceName = Get-ValidServiceName -serviceName $searchServiceName
        #$searchServiceSku = "basic"

        try {
            $ErrorActionPreference = 'Continue'

            az search service create --name $searchServiceName --resource-group $resourceGroupName --location $location --sku basic --output none
            
            Write-Host "Search Service '$searchServiceName' created."
            Write-Log -message "Search Service '$searchServiceName' created."

            $dataSourceExists = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

            if ($dataSourceExists -eq $false) {
                New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSourceName $searchDataSourceName -storageAccountName $storageAccountName
            }
            else {
                Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
            }

            $dataSourceExists = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

            $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

            $searchIndexExists = $searchIndexes -contains $global:searchIndexName

            if ($searchIndexExists -eq $false) {
                New-SearchIndex -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $searchIndexName -searchIndexFieldNames $searchIndexFieldNames
            }
            
            $searchIndexExists = $searchIndexes -contains $global:searchIndexName

            Start-Sleep -Seconds 15

            if ($dataSourceExists -eq "true" && $searchIndexExists -eq $true) {
                $searchIndexerExists = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $searchIndexerName

                if ($searchIndexerExists -eq $false) {
                    New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $searchIndexName -searchIndexerName $searchIndexerName -searchDatasourceName $searchDatasourceName -searchIndexSchema $searchIndexSchema -searchIndexerSchedule $searchIndexerSchedule
                }
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

        try {
            $ErrorActionPreference = 'Continue'

            $dataSourceExists = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

            if ($dataSourceExists -eq $false) {
                New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSourceName $searchDataSourceName -storageAccountName $storageAccountName
            }
            else {
                Write-Host "Search Data Source '$searchDataSourceName' already exists."
                Write-Log -message "Search Data Source '$searchDataSourceName' already exists."
            }

            $dataSourceExists = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName

            $searchIndexes = Get-SearchIndexes -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName

            $searchIndexExists = $searchIndexes -contains $global:searchIndexName

            if ($searchIndexExists -eq $false) {
                New-SearchIndex -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $searchIndexName -searchIndexFieldNames $searchIndexFieldNames
            }
            else {
                Write-Host "Search Index '$searchIndexName' already exists."
                Write-Log -message "Search Index '$searchIndexName' already exists."
            }

            $searchIndexExists = $searchIndexes -contains $global:searchIndexName

            Start-Sleep -Seconds 15

            try {
                if ($dataSourceExists -eq "true" && $searchIndexExists -eq $true) {
                    $searchIndexerExists = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $searchIndexerName
                
                    if ($searchIndexerExists -eq $false) {
                        New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $searchIndexName -searchIndexerName $searchIndexerName -searchDatasourceName $searchDatasourceName -searchIndexSchema $searchIndexSchema -searchIndexerSchedule $searchIndexerSchedule
                    }
                    else {
                        Write-Host "Search Indexer '$searchIndexerName' already exists."
                        Write-Log -message "Search Indexer '$searchIndexerName' already exists."
                    }
                }
            }
            catch {
                Write-Error "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        catch {
            Write-Error "Failed to create Search Service Index '$searchServiceIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Search Service '$searchServiceIndexName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }

    # **********************************************************************************************************************
    # Create a Log Analytics Workspace

    $logAnalyticsWorkspaceName = Get-ValidServiceName -serviceName $logAnalyticsWorkspaceName

    if ($existingResources -notcontains $logAnalyticsWorkspaceName) {
        try {
            $ErrorActionPreference = 'Stop'
            az monitor log-analytics workspace create --workspace-name $logAnalyticsWorkspaceName --resource-group $resourceGroupName --location $location --output none
            Write-Host "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
            Write-Log -message "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
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

    #**********************************************************************************************************************
    # Create an Application Insights component

    if ($existingResources -notcontains $appInsightsName) {


        $appInsightsName = Get-ValidServiceName -serviceName $appInsightsName

        # Try to create an Application Insights component
        try {
            $ErrorActionPreference = 'Stop'
            az monitor app-insights component create --app $appInsightsName --location $location --resource-group $resourceGroupName --application-type web --output none
            Write-Host "Application Insights component '$appInsightsName' created."
            Write-Log -message "Application Insights component '$appInsightsName' created."
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

    #**********************************************************************************************************************
    # Create a Cognitive Services account

    $cognitiveServiceName = Get-ValidServiceName -serviceName $cognitiveServiceName

    if ($existingResources -notcontains $cognitiveServiceName) {
        try {
            $ErrorActionPreference = 'Stop'
            az cognitiveservices account create --name $cognitiveServiceName --resource-group $resourceGroupName --location $location --sku S0 --kind CognitiveServices --output none
            
            Write-Host "Cognitive Services account '$cognitiveServiceName' created."
            Write-Log -message "Cognitive Services account '$cognitiveServiceName' created."       
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                try {
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $cognitiveServiceName -resourceType "CognitiveServices" -resourceGroupName $resourceGroupName
                    Write-Host "Cognitive Services account '$cognitiveServiceName' restored."
                    Write-Log -message "Cognitive Services account '$cognitiveServiceName' restored."
                }
                catch {
                    Write-Error "Failed to restore Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                Write-Error "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            } 
        }
    }
    else {
        Write-Host "Cognitive Service '$cognitiveServiceName' already exists."
        Write-Log -message "Cognitive Service '$cognitiveServiceName' already exists."
    }

    #**********************************************************************************************************************
    # Create OpenAI account

    if ($existingResources -notcontains $openAIName) {

        try {
            $ErrorActionPreference = 'Stop'
            az cognitiveservices account create --name $openAIName --resource-group $resourceGroupName --location $location --kind OpenAI --sku S0 --output none
            Write-Host "Azure OpenAI account '$openAIName' created."
            Write-Log -message "Azure OpenAI account '$openAIName' created."
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $openAIName -resourceType "CognitiveServices" -resourceGroupName $resourceGroupName
                    Write-Host "OpenAI account '$openAIName' restored."
                    Write-Log -message "OpenAI account '$openAIName' restored."
                }
                catch {
                    Write-Error "Failed to restore OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                Write-Error "Failed to create Azure OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to create Azure OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }   
        }
    }
    else {
        Write-Host "OpenAI Service '$openAIName' already exists."
        Write-Log -message "OpenAI Service '$openAIName' already exists."
    }

    #**********************************************************************************************************************
    # Deploy Open AI model

    $deploymentName = "ai"
    $modelName = $aiModelType
    $modelFormat = "OpenAI"
    $modelVersion = "2024-05-13"
    $skuName = "Standard"
    $skuCapacity = "100"

    try {
        # Check if the deployment already exists
        $deploymentExists = az cognitiveservices account deployment list --resource-group $resourceGroupName --name $openAIName --query "[?name=='$deploymentName']" --output tsv

        if ($deploymentExists) {
            Write-Host "OpenAI model deployment '$deploymentName' already exists."
            Write-Log -message "OpenAI model deployment '$deploymentName' already exists."
        }
        else {
            # Create the deployment if it does not exist
            az cognitiveservices account deployment create --resource-group $resourceGroupName --name $openAIName --deployment-name $deploymentName --model-name $modelName --model-format $modelFormat --model-version $modelVersion --sku-name $skuName --sku-capacity $skuCapacity
            Write-Host "OpenAI model deployment '$deploymentName' created successfully."
            Write-Log -message "OpenAI model deployment '$deploymentName' created successfully."
        }
    }
    catch {
        Write-Error "Failed to create OpenAI model deployment '$deploymentName': $_"
        Write-Log -message "Failed to create OpenAI model deployment '$deploymentName': $_"
    }
    
    
    #**********************************************************************************************************************
    # Create Container Registry

    if ($existingResources -notcontains $containerRegistryName) {
        $containerRegistryFile = Update-ContainerRegistryFile -resourceGroupName $resourceGroupName -containerRegistryName $containerRegistryName -location $location

        try {
            az ml registry create --file $containerRegistryFile --resource-group $resourceGroupName
        
            Write-Host "Container Registry '$containerRegistryName' created."
            Write-Log -message "Container Registry '$containerRegistryName' created."
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

    #**********************************************************************************************************************
    # Create Document Intelligence account

    if ($existingResources -notcontains $documentIntelligenceName) {

        $availableLocations = az cognitiveservices account list-skus --kind FormRecognizer --query "[].locations" --output tsv

        # Check if the desired location is available
        if ($availableLocations -contains $($location.ToUpper() -replace '\s', '')  ) {
            # Try to create a Document Intelligence account
            try {
                $ErrorActionPreference = 'Stop'
                               
                $jsonOutput = az cognitiveservices account create --name $documentIntelligenceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '') --kind FormRecognizer --sku S0 --output none
                # The Azure CLI does not return a terminating error when the deployment fails, so we need to check the output for the error message
    
                if ($jsonOutput -match "error") {

                    $jsonProperties = '{"restore": true}'
                    $jsonOutput = az resource create --subscription $subscriptionId -g $resourceGroupName -n $documentIntelligenceName --location $location --namespace Microsoft.CognitiveServices --resource-type accounts --properties $jsonProperties
                
                    $errorInfo = Format-ErrorInfo -jsonOutput $jsonOutput
                    
                    $errorMessage = "Failed to create Document Intelligence Service  '$documentIntelligenceName'. `
        `Error: $($errorInfo.Code) `
        `Code: $($errorInfo.Error) `
        `Details: $($errorInfo.SKU)"

                    Write-Host $errorMessage

                    Write-Log -message $errorMessage -logFilePath $global:LogFilePath
                }
                else {
                    Write-Host "Document Intelligence account '$documentIntelligenceName' created."
                    Write-Log -message "Document Intelligence account '$documentIntelligenceName' created." -logFilePath $global:LogFilePath
                }
                
            }
            catch {     
                # Check if the error is due to soft deletion
                if ($_ -match "has been soft-deleted") {
                    try {
                        $ErrorActionPreference = 'Stop'
                        # Attempt to restore the soft-deleted Cognitive Services account
                        Recover-SoftDeletedResource -resourceName $documentIntelligenceName -resourceType "CognitiveServices" -resourceGroupName $resourceGroupName
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

    #**********************************************************************************************************************
    # Create Computer Vision account

    if ($existingResources -notcontains $computerVisionName) {
        $computerVisionName = Get-ValidServiceName -serviceName $computerVisionName

        try {
            $ErrorActionPreference = 'Stop'
            az cognitiveservices account create --name $computerVisionName --resource-group $resourceGroupName --location $location --kind ComputerVision --sku S1 --output none
            Write-Host "Computer Vision account '$computerVisionName' created."
            Write-Log -message "Computer Vision account '$computerVisionName' created."
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted") {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Cognitive Services account
                    Restore-SoftDeletedResource -resourceName $computerVisionName -resourceType "CognitiveServices" -resourceGroupName $resourceGroupName
                    Write-Host "Computer Vision account '$computerVisionName' restored."
                    Write-Log -message "Computer Vision account '$computerVisionName' restored."
                }
                catch {
                    Write-Error "Failed to restore Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to restore Computer Vision account '$computerVisionName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
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

    #**********************************************************************************************************************
    # Create API Management Service
    
    <#
    # {    if ($existingResources -notcontains $apiManagementService.Name) {
            New-ApiManagementService -apiManagementService $apiManagementService -resourceGroupName $resourceGroupName
        }:Enter a comment or description}
    #>

}

# Function to create a new search datasource
function New-SearchDataSource {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchDatasourceName,
        [string]$searchDatasourceType = "azureblob",
        [string]$searchDatasourceContainerName = "content",
        [string]$searchDatasourceQuery = "*",
        [string]$searchDatasourceDataChangeDetectionPolicy = "HighWaterMark",
        [string]$searchDatasourceDataDeletionDetectionPolicy = "SoftDeleteColumn"
    )

    try {
        $ErrorActionPreference = 'Continue'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
        $searchServiceAPiVersion = "2024-07-01"

        $storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv

        $searchDatasourceConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

        $searchDatasourceUrl = "https://$searchServiceName.search.windows.net/datasources?api-version=$searchServiceAPiVersion"
    
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
            Write-Error "Failed to create datasource '$searchDatasourceName': $_"
            Write-Log -message "Failed to create datasource '$searchDatasourceName': $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create datasource '$searchDatasourceName': $_"
        Write-Log -message "Failed to create datasource '$searchDatasourceName': $_"

        return false
    }
}
# Function to create a new search index
function New-SearchIndex {
    param(
        [string]$searchServiceName,
        [string]$resourceGroupName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$searchDatasourceName,
        [string]$searchIndexSchema,
        [string]$searchIndexerSchedule = "0 0 0 * * *"
    )

    try {
        $jsonFilePath = "search-index-schema.json"
    
        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
        #$searchServiceAPiVersion = az search service show --resource-group $resourceGroupName --name $searchServiceName --query "apiVersion" --output tsv
        $searchServiceAPiVersion = "2024-07-01"
    
        $searchIndexUrl = "https://$searchServiceName.search.windows.net/indexes?api-version=$searchServiceAPiVersion"
    
        $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
    
        $jsonContent.'@odata.context' = $searchIndexUrl
        $jsonContent.name = $global:searchIndexName
    
        if ($jsonContent.PSObject.Properties.Match('semantic')) {
            $jsonContent.PSObject.Properties.Remove('semantic')
        }
    
        if ($jsonContent.PSObject.Properties.Match('vectorSearch')) {
            $jsonContent.PSObject.Properties.Remove('vectorSearch')
        }
    
        if ($jsonContent.PSObject.Properties.Match('normalizer')) {
            $jsonContent.PSObject.Properties.Remove('normalizer')
        }
    
        $updatedJsonContent = $jsonContent | ConvertTo-Json -Depth 10
    
        $updatedJsonContent | Set-Content -Path $jsonFilePath
    
        # Construct the REST API URL
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexes?api-version=$searchServiceAPiVersion"
    
        # Create the index
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Index '$global:searchIndexName' created successfully."
            Write-Log -message "Index '$global:searchIndexName' created successfully."

            return true
        }
        catch {
            Write-Error "Failed to create index '$global:searchIndexName': $_"
            Write-Log -message "Failed to create index '$global:searchIndexName': $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create index '$global:searchIndexName': $_"
        Write-Log -message "Failed to create index '$global:searchIndexName': $_"

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
        [string]$searchIndexSchema,
        [string]$searchIndexerSchedule = "0 0 0 * * *"
    )

    try {

        $jsonFilePath = "search-indexer-schema.json"
    
        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
        #$searchServiceAPiVersion = az search service show --resource-group $resourceGroupName --name $searchServiceName --query "apiVersion" --output tsv
        $searchServiceAPiVersion = "2024-07-01"
    
        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$searchServiceAPiVersion"
    
        $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
    
        $jsonContent.'@odata.context' = $searchIndexerUrl
        $jsonContent.name = $global:searchIndexerName
        $jsonContent.dataSourceName = $searchDatasourceName
        $jsonContent.targetIndexName = $global:searchIndexName
    
        if ($jsonContent.PSObject.Properties.Match('cache')) {
            $jsonContent.PSObject.Properties.Remove('cache')
        }
    
        if ($jsonContent.PSObject.Properties.Match('vectorSearch')) {
            $jsonContent.PSObject.Properties.Remove('vectorSearch')
        }
    
        if ($jsonContent.PSObject.Properties.Match('normalizer')) {
            $jsonContent.PSObject.Properties.Remove('normalizer')
        }
    
        $updatedJsonContent = $jsonContent | ConvertTo-Json -Depth 10
    
        $updatedJsonContent | Set-Content -Path $jsonFilePath
    
        # Construct the REST API URL
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$searchServiceAPiVersion"
    
        # Create the index
        try {
            Invoke-RestMethod -Uri $searchServiceUrl -Method Post -Body $updatedJsonContent -ContentType "application/json" -Headers @{ "api-key" = $searchServiceApiKey }
            Write-Host "Index '$global:searchIndexerName' created successfully."
            Write-Log -message "Index '$global:searchIndexerName' created successfully."

            return true
        }
        catch {
            Write-Error "Failed to create index '$global:searchIndexerName': $_"
            Write-Log -message "Failed to create index '$global:searchIndexerName': $_"

            return false
        }
    }
    catch {
        Write-Error "Failed to create index '$global:searchIndexerName': $_"
        Write-Log -message "Failed to create index '$global:searchIndexerName': $_"

        return false
    }
}

# Function to create a new subnet
function New-SubNet {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [string]$subnetName,
        [string]$subnetAddressPrefix
    )

    try {
        az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name $subnetName --address-prefixes $subnetAddressPrefix --output none
        Write-Host "Subnet '$subnetName' created."
        Write-Log -message "Subnet '$subnetName' created."
    }
    catch {
        Write-Error "Failed to create Subnet '$subnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Subnet '$subnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to create a new virtual network
function New-VirtualNetwork {
    param (
        [array]$virtualNetwork
    )

    $vnetName = $virtualNetwork.Name

    try {
        az network vnet create --resource-group $virtualNetwork.ResourceGroup --name  $virtualNetwork.Name --output none
        Write-Host "Virtual Network '$vnetName' created."
        Write-Log -message "Virtual Network '$vnetName' created."
    }
    catch {
        Write-Error "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Virtual Network '$vnetName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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
                    Write-Host "Key Vault: '$resourceName' created with Vault Access Policies."
                    Write-Log -message "Key Vault: '$resourceName' created with Vault Access Policies."

                    # Assign RBAC roles to the managed identity
                    Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName
                }
                catch {
                    Write-Error "Failed to create Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Key Vault '$resourceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Key Vault
                    az keyvault recover --name $keyVaultName --resource-group $resourceGroupName --location $location --output none
                    Write-Host "Key Vault: '$keyVaultName' created with Vault Access Policies."
                    Write-Log -message "Key Vault: '$keyVaultName' created with Vault Access Policies."

                    Set-KeyVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                }
                catch {
                    Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }
        "StorageAccount" {
            # Code to restore Storage Account
            Write-Output "Restoring Storage Account: $resourceName"

        }
        "AppService" {
            # Code to restore App Service
            Write-Output "Restoring App Service: $resourceName"

        }
        "CognitiveService" {
            # Code to restore Cognitive Service
            try {
                Write-Output "Restoring Cognitive Service: $resourceName"
                az cognitiveservices account recover --name $aiHubName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind AIHub --sku S0 --output none
                Write-Host "AI Hub '$aiHubName' restored."
                Write-Log -message "AI Hub '$aiHubName' restored." -logFilePath $global:LogFilePath
            }
            catch {
                Write-Error "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        "OpenAI" {
            # Code to restore OpenAI
            Write-Output "Restoring OpenAI: $resourceName"
            az cognitiveservices account recover --name $openAIName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind OpenAI --sku S0 --output none
            Write-Host "OpenAI account '$openAIName' restored."
            Write-Log -message "OpenAI account '$openAIName' restored." -logFilePath $global:LogFilePath
        }
        "ContainerRegistry" {
            # Code to restore Container Registry
            Write-Output "Restoring Container Registry: $resourceName"
            az ml registry recover --name $containerRegistryName --resource-group $resourceGroupName --output none
            Write-Host "Container Registry '$containerRegistryName' restored."
            Write-Log -message "Container Registry '$containerRegistryName' restored." -logFilePath $global:LogFilePath
        }
        "DocumentIntelligence" {
            # Code to restore Document Intelligence
            Write-Output "Restoring Document Intelligence: $resourceName"
            az cognitiveservices account recover --name $documentIntelligenceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind FormRecognizer --sku S0 --output none
            Write-Host "Document Intelligence account '$documentIntelligenceName' restored."
            Write-Log -message "Document Intelligence account '$documentIntelligenceName' restored." -logFilePath $global:LogFilePath
        }
        "Microsoft.MachineLearningServices/workspaces" {
            # Code to restore Machine Learning Workspace
            Write-Output "Restoring Machine Learning Workspace: $resourceName"
            az ml workspace recover --name $resourceName --resource-group $resourceGroupName --output none
            Write-Host "Machine Learning Workspace '$resourceName' restored."
            Write-Log -message "Machine Learning Workspace '$resourceName' restored." -logFilePath $global:LogFilePath
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
    param([string]$keyVaultName, 
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
    foreach ($secretName in $global:KeyVaultSecrets) {
        # Generate a random value for the secret
        #$secretValue = New-RandomPassword
        $secretValue = "TESTSECRET"

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
        [string]$userAssignedIdentityName
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

# Function to split a GUID and return the first 8 characters
function Split-Guid {

    $newGuid = [guid]::NewGuid().ToString()
    $newGuid = $newGuid -replace "-", ""

    $newGuid = $newGuid.Substring(0, 8)

    return $newGuid
}

# Function to start the deployment
function Start-Deployment {

    az config set extension.use_dynamic_install=yes_without_prompt

    $logFilePath = "deployment.log"

    # Initialize the sequence number
    $sequenceNumber = 1

    #$deleteResourceGroup = $false

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
        $resourceGroupName = "$resourceGroupName$resourceSuffix"
    }

    $resourceGroupExists = Test-ResourceGroupExists -resourceGroupName $resourceGroupName -location $location

    if ($deleteResourceGroup -eq $true) {
        # Delete existing resource groups with the same name
        Remove-AzureResourceGroup -resourceGroupName $resourceGroupName
    }
    
    if ($resourceGroupExists -eq $true) {

        if ($createResourceGroup -eq $true) {        
            New-ResourceGroup -resourceGroupName $resourceGroupName -location $location
        } 
        else {
            Write-Host "Using existing resource group '$resourceGroupName'."
            Write-Log -message "Using existing resource group '$resourceGroupName'."
        }  
    }
    else {
        New-ResourceGroup -resourceGroupName $resourceGroupName -location $location
    }

    #return 
    
    if ($appendUniqueSuffix -eq $true) {

        # Find a unique suffix
        $resourceSuffix = Get-UniqueSuffix -resourceSuffix $resourceSuffix -resourceGroupName $resourceGroupName

        $existingResources = az resource list --resource-group $resourceGroupName --query "[].name" --output tsv

        New-Resources -storageAccountName $storageAccountName `
            -blobStorageContainerName $blobStorageContainerName `
            -appServicePlanName $appServicePlanName `
            -searchServiceName $searchServiceName `
            `searchIndexName $searchIndexName `
            `searchIndexerName $searchIndexerName `
            -searchDatasourceName $searchDatasourceName `
            -logAnalyticsWorkspaceName $logAnalyticsWorkspaceName `
            -cognitiveServiceName $cognitiveServiceName `
            -computerVisionName $computerVisionName `
            -keyVaultName $keyVaultName `
            -appInsightsName $appInsightsName `
            -portalDashboardName $portalDashboardName `
            -managedEnvironmentName $managedEnvironmentName `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -openAIName $openAIName `
            -documentIntelligenceName $documentIntelligenceName `
            -containerRegistryName $containerRegistryName `
            -existingResources $existingResources
    }
    else {
        $userPrincipalName = "$($parameters.userPrincipalName)"

        $existingResources = az resource list --resource-group $resourceGroupName --query "[].name" --output tsv

        New-Resources -storageAccountName $storageAccountName `
            -blobStorageContainerName $blobStorageContainerName `
            -appServicePlanName $appServicePlanName `
            -searchServiceName $searchServiceName `
            `searchIndexName $searchIndexName `
            `searchIndexerName $searchIndexerName `
            -searchDatasourceName $searchDatasourceName `
            -logAnalyticsWorkspaceName $logAnalyticsWorkspaceName `
            -cognitiveServiceName $cognitiveServiceName `
            -computerVisionName $computerVisionName `
            -keyVaultName $keyVaultName `
            -appInsightsName $appInsightsName `
            -portalDashboardName $portalDashboardName `
            -managedEnvironmentName $managedEnvironmentName `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -openAIName $openAIName `
            -documentIntelligenceName $documentIntelligenceName `
            -existingResources $existingResources `
            -apiManagementService $apiManagementService `
            -containerRegistryName $containerRegistryName
    }

    # Create new web app and function app services
    foreach ($appService in $appServices) {
        if ($existingResources -notcontains $appService) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -deployZipResources $false
        }
    }

    #**********************************************************************************************************************
    # Create User Assigned Identity

    if ($existingResources -notcontains $userAssignedIdentityName) {
        New-ManagedIdentity -userAssignedIdentityName $userAssignedIdentityName -resourceGroupName $resourceGroupName -location $location -subscriptionId $subscriptionId
    }
    else {
        Write-Host "Identity '$userAssignedIdentityName' already exists."
        Write-Log -message "Identity '$userAssignedIdentityName' already exists."
    }

    $useRBAC = $false

    #**********************************************************************************************************************
    # Create Key Vault

    if ($existingResources -notcontains $keyVaultName) {
        New-KeyVault -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -location $location -useRBAC $useRBAC -userAssignedIdentityName $userAssignedIdentityName
    }
    else {
        Write-Host "Key Vault '$keyVaultName' already exists."
        Write-Log -message "Key Vault '$keyVaultName' already exists."
    }

    #Set-RBACRoles -userAssignedIdentityName $userAssignedIdentityName

    # Filter appService nodes with type equal to 'function'
    $functionAppServices = $appServices | Where-Object { $_.type -eq 'Function' }

    # Return the first instance of the filtered appService nodes
    $functionAppService = $functionAppServices | Select-Object -First 1

    $functionAppServiceName = $functionAppService.Name

    # Create a new AI Hub and Model
    New-AIHubAndModel -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -aiServiceName $aiServiceName -appInsightsName $appInsightsName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources
    
    # Update configuration file for web frontend
    Update-ConfigFile - configFilePath "app/frontend/config.json" -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -searchServiceName $searchServiceName -openAIName $openAIName -functionAppName $functionAppServiceName -searchIndexerName $searchIndexerName -searchIndexName $searchIndexName -siteLogo $global:siteLogo
    
    # Deploy web app and function app services
    foreach ($appService in $appServices) {
        if ($existingResources -notcontains $appService) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -deployZipResources $true
        }
    }

    # End the timer
    $endTime = Get-Date
    $executionTime = $endTime - $startTime

    # Format the execution time
    $executionTimeFormatted = "{0:D2} HRS : {1:D2} MIN : {2:D2} SEC : {3:D3} MS" -f $executionTime.Hours, $executionTime.Minutes, $executionTime.Seconds, $executionTime.Milliseconds

    # Log the total execution time
    $executionTimeMessage = "*** TOTAL SCRIPT EXECUTION TIME: $executionTimeFormatted ***"

    Write-Host $executionTimeMessage
    Write-Log -message $executionTimeMessage -logFilePath $logFilePath

    # Add a line break
    Add-Content -Path $logFilePath -Value ""
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
        #Write-Log -message "Resource group '$resourceGroupName' exists."

        return true
    }
    else {
        #Write-Host "Resource group '$resourceGroupName' does not exist."
        #Write-Log -message "Resource group '$resourceGroupName' does not exist."

        return false
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
            "Microsoft.ApiManagement/" {
                $result = az apim api list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
            }
            "Microsoft.ContainerRegistry/" {
                $result = az container list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
            }
        }

        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Host "$resourceName exists."
            return $true
        }
        else {
            Write-Host "$resourceName does not exist."
            return $false
        }
    } 
    else {
        # Check within the subscription
        $result = az resource list --name $resourceName --resource-type $resourceType --query "[].name" --output tsv
        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Host "$resourceName exists."
            return $true
        }
        else {
            Write-Host "$resourceName does not exist."
            return $false
        }
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

    $filePath = "$rootPath/app/container.registry.yaml"

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
        [string]$location,
        [string]$subscriptionId,
        [string]$storageAccountName,
        [string]$appInsightsName,
        [string]$keyVaultName
    )
    
    $rootPath = Get-Item -Path (Get-Location).Path

    $filePath = "$rootPath/app/ml.workspace.yaml"

    $content = @"
name: $aiProjectName
location: $location
display_name: $aiProjectName
description: This configuration specifies a workspace configuration with existing dependent resources
storage_account: /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName
container_registry: /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName
key_vault: /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName
application_insights: /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName
tags:
  purpose: Azure AI Hub Project
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

# Function to update AI connection file
function Update-AIConnectionFileOld {
    param (
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$serviceName,
        [string]$serviceProperties
    )
    
    $rootPath = Get-Item -Path (Get-Location).Path

    #$rootAppPath = Find-AppRoot -currentDirectory (Get-Location).Path
    $filePath = "$rootPath/app/ai.connection.yaml"

    $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $cognitiveServiceName

    $content = @"
name: $aiServiceName
type: azure_ai_services
endpoint: https://eastus.api.cognitive.microsoft.com/
api_key: $apiKey
ai_services_resource_id: /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$aiServiceName
"@

    try {
        $content | Out-File -FilePath $filePath -Encoding utf8 -Force
        Write-Host "File 'ai.connection.yaml' created and populated."
        Write-Log -message "File 'ai.connection.yaml' created and populated."
    }
    catch {
        Write-Error "Failed to create or write to 'ai.connection.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create or write to 'ai.connection.yaml': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    return $filePath
}

# Function to update AI connection file
function Update-AIConnectionFile {
    param (
        [string]$resourceGroupName,
        [string]$resourceType,
        [string]$searchServiceName = $global:searchServiceName,
        [string]$serviceName,
        [string]$serviceProperties
    )
    
    $rootPath = Get-Item -Path (Get-Location).Path

    #$rootAppPath = Find-AppRoot -currentDirectory (Get-Location).Path
    #$filePath = "$rootPath/app/ai.connection.yaml"
    $yamlFileName = $serviceProperties.YamlFileName

    $filePath = "$rootPath/app/$yamlFileName"

    $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiServiceName
    
    $storageAccountKey = az storage account keys list `
        --resource-group $resourceGroupName `
        --account-name $storageAccountName `
        --query "[0].value" `
        --output tsv

    switch ($resourceType) {
        "AiService" {
            $endpoint = "https://$searchServiceName.cognitiveservices.azure.com/"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"

            $content = @"
name: $serviceName
type: azure_ai_services
endpoint: $endpoint
api_key: $apiKey
ai_services_resource_id: $resourceId
"@
        }
        "SearchService" {
            $endpoint = "https://api.openai.com/v1"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CognitiveServices/accounts/$serviceName"
            
            $content = @"
            name: $serviceName
type: "azure_ai_search"

endpoint: $endpoint
api_key: $apiKey
"@   
        }
        "StorageAccount" {
            $endpoint = "https://$storageAccountName.blob.core.windows.net/"
            $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
            $containerName = $serviceProperties.ContainerName

            $content = @"
name: $serviceName
type: azure_blob
url: $endpoint
container_name: $containerName
account_name: $storageAccountName

credentials:
  account_key: $storageAccountKey
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

# Function to update the config file
function Update-ConfigFile {
    param (
        [string]$configFilePath,
        [string]$resourceGroupName,
        [string]$storageAccountName,
        [string]$searchServiceName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$openAIName,
        [string]$functionAppName,
        [string]$siteLogo
    )

    try {
        $storageKey = az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query "[0].value" --output tsv
        $startDate = (Get-Date).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $expirationDate = (Get-Date).AddYears(1).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $searchApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
    
        $functionAppKey = az functionapp keys list --resource-group $resourceGroupName --name $functionAppName --query "functionKeys.default" --output tsv
        $functionAppUrl = az functionapp show -g $resourceGroupName -n $functionAppName --query "defaultHostName" --output tsv
        
        # https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-user-delegation-sas-create-cli
        $storageSAS = az storage account generate-sas --account-name $storageAccountName --account-key $storageKey --resource-types co --services btfq --permissions rwdlacupiytfx --expiry $expirationDate --https-only --output tsv
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

        $fulllUrl = "https://$storageAccountName.blob.core.windows.net/content?comp=list&include=metadata&restype=container&$storageSAS"

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
        $config.AZURE_STORAGE_KEY = $storageKey
        $config.AZURE_STORAGE_ACCOUNT_NAME = $storageAccountName
        $config.AZURE_SEARCH_SERVICE_NAME = $searchServiceName
        $config.AZURE_SEARCH_API_KEY = $searchApiKey
        $config.AZURE_SEARCH_FULL_URL = $fulllUrl
        $config.AZURE_SEARCH_INDEX_NAME = $searchIndexName
        $config.AZURE_SEARCH_INDEXER_NAME = $searchIndexerName
        $config.AZURE_STORAGE_SAS_TOKEN.SE = $expirationDate
        $config.AZURE_STORAGE_SAS_TOKEN.ST = $startDate
        $config.AZURE_STORAGE_SAS_TOKEN.SIG = $storageSASKey
        $config.AZURE_STORAGE_SAS_TOKEN.SS = $storageSS
        $config.AZURE_STORAGE_SAS_TOKEN.SP = $storageSP
        $config.AZURE_STORAGE_SAS_TOKEN.SRT = $storageSRT
        $config.AZURE_FUNCTION_APP_NAME = $functionAppName
        $config.AZURE_FUNCTION_API_KEY = $functionAppKey
        $config.AZURE_FUNCTION_APP_URL = "https://$functionAppUrl"
        $config.AZURE_KEY_VAULT_NAME = $global:keyVaultName
        $config.SITE_LOGO = $global:siteLogo

        $config.OPEN_AI_KEY = az cognitiveservices account keys list --resource-group $resourceGroupName --name $openAIName --query "key1" --output tsv
    
        # Convert the updated object back to JSON format
        $updatedConfig = $config | ConvertTo-Json -Depth 10
    
        # Write the updated JSON back to the file
        $updatedConfig | Set-Content -Path $configFilePath

        Write-Host "Config file updated successfully."
        Write-Log -message "Config file updated successfully."
    }
    catch {
        Write-Host "Failed to update the config file: : (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to update the config file: : (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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

$ErrorActionPreference = 'Stop'

#$global:subscriptionId = az account show --query "{Id:id}" --output tsv

# Initialize parameters
$initParams = Initialize-Parameters -parametersFile $parametersFile
#Write-Host "Parameters initialized."
#Write-Log -message "Parameters initialized."

# Alphabetize the parameters object
$parameters = Get-Parameters-Sorted -Parameters $initParams.parameters

# Set the user-assigned identity name
$userPrincipalName = $parameters.userPrincipalName

Set-DirectoryPath -targetDirectory $global:deploymentPath

# Start the deployment
Start-Deployment

#**********************************************************************************************************************
# End of script
