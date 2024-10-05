#**********************************************************************************************************************
# Script: Azure AI Demo Deployment.ps1
#
# Before executing this script, ensure that you have installed the Azure CLI and PowerShell Core. 
# make sure you have an active Azure subscription and have logged in using the 'az login' command.
# To execute this script, run the following command:
# .\Azure AI Demo Deployment.ps1
#
#**********************************************************************************************************************
<#
.SYNOPSIS
    This script automates the deployment of various Azure resources.

.DESCRIPTION
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

$ErrorActionPreference = 'Stop'

# Mapping of global resource types
$globalResourceTypes = @(
    "Microsoft.Storage/storageAccounts",
    "Microsoft.KeyVault/vaults",
    "Microsoft.Sql/servers",
    "Microsoft.DocumentDB/databaseAccounts",
    "Microsoft.Web/serverFarms",
    "Microsoft.Web/sites",
    "Microsoft.DataFactory/factories",
    "Microsoft.ContainerRegistry/registries",
    "Microsoft.CognitiveServices/accounts",
    "Microsoft.Search/searchServices"
)

$globalKeyVaultSecrets = @(
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

# Initialize the parameters
function InitializeParameters {
    param (
        [string]$parametersFile = "parameters.json"
    )

    # Load parameters from the JSON file
    $parameters = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Initialize global variables for each item in the parameters_gao.json file
    $global:aiHubName = $parameters.aiHubName
    $global:aiModelName = $parameters.aiModelName
    $global:aiModelType = $parameters.aiModelType
    $global:aiModelVersion = $parameters.aiModelVersion
    $global:aiServiceName = $parameters.aiServiceName
    $global:aiProjectName = $parameters.aiProjectName
    $global:apiManagementServiceName = $parameters.apiManagementServiceName
    $global:appendUniqueSuffix = $parameters.appendUniqueSuffix
    $global:appServicePlanName = $parameters.appServicePlanName
    $global:appInsightsName = $parameters.appInsightsName
    $global:blobStorageAccountName = $parameters.blobStorageAccountName
    $global:blobStorageContainerName = $parameters.blobStorageContainerName
    $global:cognitiveServiceName = $parameters.cognitiveServiceName
    $global:containerAppName = $parameters.containerAppName
    $global:containerAppsEnvironmentName = $parameters.containerAppsEnvironmentName
    $global:containerRegistryName = $parameters.containerRegistryName
    $global:cosmosDbAccountName = $parameters.cosmosDbAccountName
    $global:documentIntelligenceName = $parameters.documentIntelligenceName
    $global:eventHubNamespaceName = $parameters.eventHubNamespaceName
    $global:functionAppServicePlanName = $parameters.functionAppServicePlanName
    $global:functionAppName = $parameters.functionAppName
    $global:keyVaultName = $parameters.keyVaultName
    $global:location = $parameters.location
    $global:logAnalyticsWorkspaceName = $parameters.logAnalyticsWorkspaceName
    $global:managedIdentityName = $parameters.managedIdentityName
    $global:openAIName = $parameters.openAIName
    $global:portalDashboardName = $parameters.portalDashboardName
    $global:redisCacheName = $parameters.redisCacheName
    $global:resourceGroupName = $parameters.resourceGroupName
    $global:resourceSuffix = $parameters.resourceSuffix
    $global:searchServiceName = $parameters.searchServiceName
    $global:searchIndexName = $parameters.searchIndexName
    $global:searchIndexFieldNames = $parameters.searchIndexFieldNames
    $global:searchIndexerName = $parameters.searchIndexerName
    $global:serviceBusNamespaceName = $parameters.serviceBusNamespaceName
    $global:sharedDashboardName = $parameters.sharedDashboardName
    $global:sqlServerName = $parameters.sqlServerName
    $global:storageAccountName = $parameters.storageAccountName
    $global:userAssignedIdentityName = $parameters.userAssignedIdentityName
    $global:virtualNetworkName = $parameters.virtualNetworkName
    $global:webAppName = $parameters.webAppName
    $global:functionAppPath = $parameters.functionAppPath
    $global:sasFunctionAppName = $parameters.sasFunctionName

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
    $global:resourceGuid = SplitGuid

    $parameters | Add-Member -MemberType NoteProperty -Name "objectId" -Value $global:objectId
    $parameters | Add-Member -MemberType NoteProperty -Name "subscriptionId" -Value $global:subscriptionId
    $parameters | Add-Member -MemberType NoteProperty -Name "tenantId" -Value $global:tenantId
    $parameters | Add-Member -MemberType NoteProperty -Name "userPrincipalName" -Value $global:userPrincipalName
    $parameters | Add-Member -MemberType NoteProperty -Name "resourceGuid" -Value $global:resourceGuid

    return @{
        aiHubName                    = $aiHubName
        aiModelName                  = $aiModelName
        aiModelType                  = $aiModelType
        aiModelVersion               = $aiModelVersion
        aiServiceName                = $aiServiceName
        aiProjectName                = $aiProjectName
        apiManagementServiceName     = $apiManagementServiceName
        appendUniqueSuffix           = $appendUniqueSuffix
        appServicePlanName           = $appServicePlanName
        appInsightsName              = $appInsightsName
        blobStorageAccountName       = $blobStorageAccountName
        blobStorageContainerName     = $blobStorageContainerName
        cognitiveServiceName         = $cognitiveServiceName
        containerAppName             = $containerAppName
        containerAppsEnvironmentName = $containerAppsEnvironmentName
        containerRegistryName        = $containerRegistryName
        cosmosDbAccountName          = $cosmosDbAccountName
        documentIntelligenceName     = $documentIntelligenceName
        eventHubNamespaceName        = $eventHubNamespaceName
        functionAppName              = $functionAppName
        functionAppPath              = $functionAppPath
        functionAppServicePlanName   = $functionAppServicePlanName
        keyVaultName                 = $keyVaultName
        location                     = $location
        logAnalyticsWorkspaceName    = $logAnalyticsWorkspaceName
        managedIdentityName          = $managedIdentityName
        openAIName                   = $openAIName
        portalDashboardName          = $portalDashboardName
        redisCacheName               = $redisCacheName
        resourceGroupName            = $resourceGroupName
        resourceGuid                 = $resourceGuid
        resourceSuffix               = $resourceSuffix
        result                       = $result
        sasFunctionAppName           = $sasFunctionAppName
        searchServiceName            = $searchServiceName
        searchIndexName              = $searchIndexName
        searchIndexFieldNames        = $searchIndexFieldNames
        searchIndexerName            = $searchIndexerName
        serviceBusNamespaceName      = $serviceBusNamespaceName
        sharedDashboardName          = $sharedDashboardName
        sqlServerName                = $sqlServerName
        storageAccountName           = $storageAccountName
        subscriptionId               = $subscriptionId
        tenantId                     = $tenantId
        userAssignedIdentityName     = $userAssignedIdentityName
        userPrincipalName            = $userPrincipalName
        virtualNetworkName           = $virtualNetworkName
        webAppName                   = $webAppName        
        parameters                   = $parameters
    }
}

# Function to split a GUID and return the first 8 characters
function SplitGuid {

    $newGuid = [guid]::NewGuid().ToString()
    $newGuid = $newGuid -replace "-", ""

    $newGuid = $newGuid.Substring(0, 8)

    return $newGuid
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

# Function to check if a resource group exists
function ResourceGroupExists {
    param (
        [int]$resourceSuffix
    )
    do {
        $resourceGroupName = "$($parameters.resourceGroupName)-$resourceSuffix"
        $resourceGroupExists = az group exists --resource-group $resourceGroupName --output tsv

        try {
            if ($resourceGroupExists -eq "true") {
                Write-Host "Resource group '$resourceGroupName' exists."
                $resourceSuffix++
            }
            else {
                az group create --name $resourceGroupName --location $location --output none
                Write-Host "Resource group '$resourceGroupName' created."
                $resourceGroupExists = $false
                        
            }
        }
        catch {
            Write-Error "Failed to create Resource Group: $_ (Line $_.InvocationInfo.ScriptLineNumber)"
            Write-Log -message "Failed to create Resource Group: $_ (Line $_.InvocationInfo.ScriptLineNumber)"
        }

    } while ($resourceGroupExists)

    return $resourceGroupName
}

# Function to check if a resource exists
function ResourceExists {
    param (
        [string]$resourceName,
        [string]$resourceType,
        [string]$resourceGroupName
    )

    if ($globalResourceTypes -contains $resourceType) {
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
            "Microsoft.Search/searchServices" {
                $result = az search service list --resource-group $resourceGroupName --query "[?name=='$resourceName'].name" --output tsv
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

# Function to find a unique suffix
function FindUniqueSuffix {
    param (
        [int]$resourceSuffix,
        [string]$resourceGroupName
    )

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
        $webAppName = "$($parameters.webAppName)-$resourceGuid-$resourceSuffix"
        $functionAppName = "$($parameters.functionAppName)-$resourceGuid-$resourceSuffix"
        $openAIName = "$($parameters.openAIName)-$resourceGuid-$resourceSuffix"
        $documentIntelligenceName = "$($parameters.documentIntelligenceName)-$resourceGuid-$resourceSuffix"
        $aiHubName = "$($aiHubName)-$($resourceGuid)-$($resourceSuffix)"
        $aiModelName = "$($aiModelName)-$($resourceGuid)-$($resourceSuffix)"
        $aiServiceName = "$($aiServiceName)-$($resourceGuid)-$($resourceSuffix)"
        
        $resourceExists = ResourceExists $storageAccountName "Microsoft.Storage/storageAccounts" -resourceGroupName $resourceGroupName -or
        ResourceExists $appServicePlanName "Microsoft.Web/serverFarms" -resourceGroupName $resourceGroupName -or
        ResourceExists $searchServiceName "Microsoft.Search/searchServices" -resourceGroupName $resourceGroupName -or
        ResourceExists $logAnalyticsWorkspaceName "Microsoft.OperationalInsights/workspaces" -resourceGroupName $resourceGroupName -or
        ResourceExists $cognitiveServiceName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        ResourceExists $keyVaultName "Microsoft.KeyVault/vaults" -resourceGroupName $resourceGroupName -or
        ResourceExists $appInsightsName "Microsoft.Insights/components" -resourceGroupName $resourceGroupName -or
        ResourceExists $portalDashboardName "Microsoft.Portal/dashboards" -resourceGroupName $resourceGroupName -or
        ResourceExists $managedEnvironmentName "Microsoft.App/managedEnvironments" -resourceGroupName $resourceGroupName -or
        ResourceExists $userAssignedIdentityName "Microsoft.ManagedIdentity/userAssignedIdentities" -resourceGroupName $resourceGroupName -or
        ResourceExists $webAppName "Microsoft.Web/sites" -resourceGroupName $resourceGroupName -or
        ResourceExists $functionAppName "Microsoft.Web/sites" -resourceGroupName $resourceGroupName -or
        ResourceExists $openAIName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName -or
        ResourceExists $documentIntelligenceName "Microsoft.CognitiveServices/accounts" -resourceGroupName $resourceGroupName

        if ($resourceExists) {
            $resourceSuffix++
        }
    } while ($resourceExists)

    $userPrincipalName = "$($parameters.userPrincipalName)"

    CreateResources -storageAccountName $storageAccountName `
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
        -webAppName $webAppName `
        -functionAppName $functionAppName `
        -openAIName $openAIName `
        -documentIntelligenceName $documentIntelligenceName

    CreateAIHubAndModel -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -location $location

    return $resourceSuffix
}

# Function to create resources
function CreateResources {
    param (
        [string]$storageAccountName,
        [string]$appServicePlanName,
        [string]$searchServiceName,
        [string]$logAnalyticsWorkspaceName,
        [string]$cognitiveServiceName,
        [string]$keyVaultName,
        [string]$appInsightsName,
        [string]$portalDashboardName,
        [string]$managedEnvironmentName,
        [string]$userAssignedIdentityName,
        [string]$userPrincipalName,
        [string]$webAppName,
        [string]$functionAppName,
        [string]$functionAppServicePlanName,
        [string]$openAIName,
        [string]$documentIntelligenceName
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

    # **********************************************************************************************************************
    # Create a storage account

    try {
        az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --output none
        Write-Host "Storage account '$storageAccountName' created."
        Write-Log -message "Storage account '$storageAccountName' created."
    }
    catch {
        Write-Error "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    $storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv
    $storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

    # **********************************************************************************************************************
    # Create an App Service Plan

    try {
        az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku B1 --output none
        Write-Host "App Service Plan '$appServicePlanName' created."
        Write-Log -message "App Service Plan '$appServicePlanName' created."
    }
    catch {
        Write-Error "Failed to create App Service Plan '$appServicePlanName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create App Service Plan '$appServicePlanName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # **********************************************************************************************************************
    # Create a Search Service

    $searchServiceName = Get-ValidServiceName -serviceName $searchServiceName
    $searchServiceSku = "basic"

    # Try to create a Search Service
    try {
        az search service create --name $searchServiceName --resource-group $resourceGroupName --location $location --sku $searchServiceSku --output none
        Write-Host "Search Service '$searchServiceName' created."
        Write-Log -message "Search Service '$searchServiceName' created."
    }
    catch {
        Write-Error "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Try to create a Search Service datasource
    try {
        az search datasource create --name $searchDatasourceName --service-name $searchServiceName --resource-group $resourceGroupName --connection-string $storageConnectionString --type azureblob --container name=$blobStorageContainerName --output none
        Write-Host "Search Service datasource '$searchDatasourceName' for '$searchServiceName' created."
        Write-Log -message "Search Service datasource '$searchDatasourceName' for '$searchServiceName' created."
    }
    catch {
        Write-Error "Failed to create Search Service datasource '$searchDatasourceName' for '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Service datasource '$searchDatasourceName' for '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Try to create a Search Service index
    try {
        az search index create --name $searchIndexName --service-name $searchServiceName --resource-group $resourceGroupName --fields '[{"name": "id", "type": "Edm.String", "key": true, "searchable": false}, {"name": "content", "type": "Edm.String", "searchable": true}]' --output none
        Write-Host "Search Service index '$searchIndexName' for '$searchServiceName' created."
        Write-Log -message "Search Service index '$searchIndexName' for '$searchServiceName' created."
    }
    catch {
        Write-Error "Failed to create Search Service index '$searchIndexName' for '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Service index '$searchIndexName' for '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # **********************************************************************************************************************
    # Create a Log Analytics Workspace

    $logAnalyticsWorkspaceName = Get-ValidServiceName -serviceName $logAnalyticsWorkspaceName

    # Try to create a Log Analytics Workspace
    try {
        az monitor log-analytics workspace create --workspace-name $logAnalyticsWorkspaceName --resource-group $resourceGroupName --location $location --output none
        Write-Host "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
        Write-Log -message "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
    }
    catch {
        Write-Error "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    #**********************************************************************************************************************
    # Create an Application Insights component

    $appInsightsName = Get-ValidServiceName -serviceName $appInsightsName

    # Try to create an Application Insights component
    try {
        az monitor app-insights component create --app $appInsightsName --location $location --resource-group $resourceGroupName --application-type web --output none
        Write-Host "Application Insights component '$appInsightsName' created."
        Write-Log -message "Application Insights component '$appInsightsName' created."
    }
    catch {
        Write-Error "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    #**********************************************************************************************************************
    # Create a Cognitive Services account

    $cognitiveServiceName = Get-ValidServiceName -serviceName $cognitiveServiceName

    try {
        $ErrorActionPreference = 'Stop'
        az cognitiveservices account create --name $cognitiveServiceName --resource-group $resourceGroupName --location $location --sku S0 --kind CognitiveServices --output none
        Write-Host "Cognitive Services account '$cognitiveServiceName' created."
        Write-Log -message "Cognitive Services account '$cognitiveServiceName' created."
    }
    catch {
        # Check if the error is due to soft deletion
        if ($_ -match "has been soft-deleted") {
            try {
                # Attempt to restore the soft-deleted Cognitive Services account
                az cognitiveservices account recover --name $cognitiveServiceName --resource-group $resourceGroupName --location $location
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

    #**********************************************************************************************************************
    # Create User Assigned Identity

    try {
        $ErrorActionPreference = 'Stop'
        az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none
        Write-Host "User Assigned Identity '$userAssignedIdentityName' created."
        Write-Log -message "User Assigned Identity '$userAssignedIdentityName' created."

        # Construct the fully qualified resource ID for the User Assigned Identity
        try {
            #$userAssignedIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
            $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
            $roles = @("Contributor", "Cognitive Services OpenAI User", "Search Index Data Reader", "Storage Blob Data Reader")  # List of roles to assign
            $assigneePrincipalId = az identity show --resource-group $resourceGroupName --name $userAssignedIdentityName --query 'principalId' --output tsv
            
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

    #**********************************************************************************************************************
    # Create Web Application

    try {
        az webapp create --name $webAppName --resource-group $resourceGroupName --plan $appServicePlanName --output none
        Write-Host "Web App '$webAppName' created."
        Write-Log -message "Web App '$webAppName' created."
    }
    catch {
        Write-Error "Failed to create Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    $useRBAC = $false

    #**********************************************************************************************************************
    # Create Key Vault

    try {
        $ErrorActionPreference = 'Stop'
        if ($useRBAC) {
            az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $true --output none
            Write-Host "Key Vault: '$keyVaultName' created with RBAC enabled."
            Write-Log -message "Key Vault: '$keyVaultName' created with RBAC enabled."

            # Assign RBAC roles to the managed identity
            AssignRBACRoles -userAssignedIdentityName $userAssignedIdentityName
        }
        else {
            az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $false --output none
            Write-Host "Key Vault: '$keyVaultName' created with Vault Access Policies."
            Write-Log -message "Key Vault: '$keyVaultName' created with Vault Access Policies."

            # Set vault access policies for user
            SetVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
        }
    }
    catch {
        # Check if the error is due to soft deletion
        if ($_ -match "has been soft-deleted") {
            if ($useRBAC) {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Key Vault
                    az keyvault recover --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $true --output none
                    Write-Host "Key Vault: '$keyVaultName' created with Vault Access Policies."
                    Write-Log -message "Key Vault: '$keyVaultName' created with Vault Access Policies."

                    # Assign RBAC roles to the managed identity
                    AssignRBACRoles -userAssignedIdentityName $userAssignedIdentityName
                }
                catch {
                    Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
            else {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Key Vault
                    az keyvault recover --name $keyVaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization $false --output none
                    Write-Host "Key Vault: '$keyVaultName' created with Vault Access Policies."
                    Write-Log -message "Key Vault: '$keyVaultName' created with Vault Access Policies."

                    SetVaultAccessPolicies -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -userPrincipalName $userPrincipalName
                }
                catch {
                    Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                    Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                }
            }
        }
        else {
            Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }

    CreateKeyVaultRoles -keyVaultName $keyVaultName `
        -resourceGroupName $resourceGroupName `
        -userAssignedIdentityName $userAssignedIdentityName `
        -userPrincipalName $userPrincipalName `
        -useRBAC $useRBAC

    CreateSecrets -keyVaultName $keyVaultName `
        -resourceGroupName $resourceGroupName

    #**********************************************************************************************************************
    # Create a Function App
    try {
        $ErrorActionPreference = 'Stop'
        #$consumerPlanLocation = az functionapp list-consumption-locations --query "[?name=='$location'].name" --output tsv
        $latestDontNetRuntimeFuncApp = Get-LatestDotNetRuntime -resourceType "functionapp" -os "linux" -version "4"

        az appservice plan create --name $functionAppServicePlanName --resource-group $resourceGroupName --location $location --sku B1 --is-linux --output none
        
        az functionapp create --name $functionAppName `
            --consumption-plan-location $($location -replace '\s', '')  `
            --storage-account $storageAccountName `
            --resource-group $resourceGroupName `
            --runtime dotnet `
            --runtime-version $latestDontNetRuntimeFuncApp `
            --functions-version 4 `
            --plan $functionAppServicePlanName `
            --output none
                          
        az functionapp create --name $functionAppName `
            --consumption-plan-location $($location -replace '\s', '')  `
            --storage-account $storageAccountName `
            --resource-group $resourceGroupName `
            --runtime dotnet `
            --runtime-version $latestDontNetRuntimeFuncApp `
            --functions-version 4 `
            --output none

        Write-Host "Function App '$functionAppName' created."
        Write-Log -message "Function App '$functionAppName' created."
    }
    catch {
        az functionapp create --name $functionAppName `
            --consumption-plan-location $($location -replace '\s', '')  `
            --storage-account $storageAccountName `
            --resource-group $resourceGroupName `
            --runtime dotnet `
            --runtime-version $latestDontNetRuntimeFuncApp `
            --functions-version 4 `
            --output none

        Write-Error "Failed to create Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    #**********************************************************************************************************************
    # Create OpenAI account

    try {
        $ErrorActionPreference = 'Stop'
        az cognitiveservices account create --name $openAIName --resource-group $resourceGroupName --location $location --kind OpenAI --sku S0 --output none
        Write-Host "Azure OpenAI account '$openAIName' created."
        Write-Log -message "Azure OpenAI account '$openAIName' created."
    }
    catch {
        # Check if the error is due to soft deletion
        if ($_ -match "has been soft-deleted") {
            try {
                $ErrorActionPreference = 'Stop'
                # Attempt to restore the soft-deleted Cognitive Services account
                az cognitiveservices account recover --name $openAIName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind OpenAI --sku S0 --output none
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

    #**********************************************************************************************************************
    # Create Document Intelligence account

    $availableLocations = az cognitiveservices account list-skus --kind FormRecognizer --query "[].locations" --output tsv

    # Check if the desired location is available
    if ($availableLocations -contains $($location.ToUpper() -replace '\s', '')  ) {
        # Try to create a Document Intelligence account
        try {
            $ErrorActionPreference = 'Stop'
            az cognitiveservices account create --name $documentIntelligenceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind FormRecognizer --sku S0 --output none
            Write-Host "Document Intelligence account '$documentIntelligenceName' created."
            Write-Log -message "Document Intelligence account '$documentIntelligenceName' created."
        }
        catch {     
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted") {
                try {
                    $ErrorActionPreference = 'Stop'
                    # Attempt to restore the soft-deleted Cognitive Services account
                    az cognitiveservices account recover --name $documentIntelligenceName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind FormRecognizer --sku S0 --output none
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

# Function to set Key Vault access policies
function SetVaultAccessPolicies {
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

# Function to assign RBAC roles to a managed identity
function AssignRBACRoles {
    params(
        [string]$userAssignedIdentityName
    )
    try {
        $ErrorActionPreference = 'Stop'
        $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
                
        az role assignment create --role "Key Vault Administrator" --assignee $userAssignedIdentityName --scope $scope
        az role assignment create --role "Key Vault Secrets User" --assignee $userAssignedIdentityName --scope $scope
        az role assignment create --role "Key Vault Certificates User" --assignee $userAssignedIdentityName --scope $scope
        az role assignment create --role "Key Vault Crypto User" --assignee $userAssignedIdentityName --scope $scope

        Write-Host "RBAC roles assigned to managed identity: '$userAssignedIdentityName'."
        Write-Log -message "RBAC roles assigned to managed identity: '$userAssignedIdentityName'."
    }
    catch {
        Write-Error "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to assign RBAC roles to managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

#Create Key Vault Roles
function CreateKeyVaultRoles {
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
function CreateSecrets {
    param (
        [string]$keyVaultName,
        [string]$resourceGroupName
    )
    # Loop through the array of secrets and store each one in the Key Vault
    foreach ($secretName in $globalKeyVaultSecrets) {
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

# Function to delete Azure resource groups
function DeleteAzureResourceGroups {
    $resourceGroups = az group list --query "[?starts_with(name, 'myResourceGroup')].name" --output tsv

    foreach ($rg in $resourceGroups) {
        try {
            az group delete --name $rg --yes --output none
            Write-Host "Resource group '$rg' deleted."
            Write-Log -message "Resource group '$rg' deleted."
        }
        catch {
            Write-Error "Failed to create Resource Group: $_ (Line $_.InvocationInfo.ScriptLineNumber)"
            Write-Log -message "Failed to create Resource Group: $_ (Line $_.InvocationInfo.ScriptLineNumber)"
        }
    }
}

# Function to create AI Hub and AI Model
function CreateAIHubAndModel {
    param (
        [string]$aiHubName,
        [string]$aiModelName,
        [string]$aiModelType,
        [string]$aiModelVersion,
        [string]$aiServiceName,
        [string]$resourceGroupName,
        [string]$location
    )
    
    #$aiHubWorkspaceName = "workspace-$aiHubName"

    # Create AI Hub
    try {
        $ErrorActionPreference = 'Stop'
        az ml workspace create --kind hub --resource-group $resourceGroupName --name $aiHubName
        #az ml connection create --file "ai.connection.yaml" --resource-group $resourceGroupName --workspace-name $aiHubName
        Write-Host "AI Hub: '$aiHubName' created."
        Write-Log -message "AI Hub: '$aiHubName' created."
    }
    catch {
        # Check if the error is due to soft deletion
        if ($_ -match "has been soft-deleted") {
            try {
                $ErrorActionPreference = 'Stop'
                # Attempt to restore the soft-deleted Cognitive Services account
                az cognitiveservices account recover --name $aiHubName --resource-group $resourceGroupName --location $($location.ToUpper() -replace '\s', '')   --kind AIHub --sku S0 --output none
                Write-Host "AI Hub '$aiHubName' restored."
                Write-Log -message "AI Hub '$aiHubName' restored."
            }
            catch {
                Write-Error "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to restore AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
        }
        else {
            Write-Error "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }    
    }

    # Create AI Service
    try {
        $ErrorActionPreference = 'Stop'
        az cognitiveservices account create --name $aiServiceName --resource-group $resourceGroupName --location $location --kind AIServices --sku S0 --output none
        Write-Host "AI Service: '$aiServiceName' created."
        Write-Log -message "AI Service: '$aiServiceName' created."
    }
    catch {
        Write-Error "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    ReadAIConnectionFile -resourceGroupName $resourceGroupName -aiServiceName $aiServiceName

    # Try to create an Azure Machine Learning workspace (AI Hub)
    try {
        $ErrorActionPreference = 'Stop'
        az ml workspace create --kind hub --name $aiHubName --resource-group $resourceGroupName --location $location --output none
        Write-Host "Azure AI Machine Learning workspace '$aiHubName' created."
        Write-Log -message "Azure Machine Learning workspace '$aiHubName' created."
    }
    catch {
        Write-Error "Failed to create Azure Machine Learning workspace '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Azure Machine Learning workspace '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create AI Hub connection
    try {
        az ml connection create --file "ai.connection.yaml" --resource-group $resourceGroupName --workspace-name $aiHubName
        Write-Host "Azure AI Machine Learning Hub connection '$aiHubName' created."
        Write-Log -message "Azure AI Machine Learning Hub connection '$aiHubName' created."
    }
    catch {
        Write-Error "Failed to create Azure AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Azure AI Machine Learning Hub connection '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create AI Model Deployment
    try {
        $ErrorActionPreference = 'Stop'
        #az cognitiveservices account deployment create --name $cognitiveServiceName --resource-group $resourceGroupName --deployment-name chat --model-name gpt-4o --model-version "0613" --model-format OpenAI --sku-capacity 1 --sku-name "Standard"
        az cognitiveservices account deployment create --name $cognitiveServiceName --resource-group $resourceGroupName --deployment-name chat --model-name gpt-4o --model-version "0613" --model-format OpenAI --sku-capacity 1 --sku-name "Standard"
        Write-Host "AI Model deployment: '$aiModelName' created."
        Write-Log -message "AI Model deployment: '$aiModelName' created."
    }
    catch {
        Write-Error "Failed to create AI Model deployment '$aiModelName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Model deployment '$aiModelName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create AI Project
    try {
        az ml workspace create --kind project --hub-id $aiHubName --resource-group $resourceGroupName --name $aiProjectName
        Write-Host "AI project '$aiProjectName' in '$aiHubName' created."
        Write-Log -message  "AI project '$aiProjectName' in '$aiHubName' created."
    }
    catch {
        Write-Error "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI project '$aiProjectName' in '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
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

# Function to read AI connection file
function ReadAIConnectionFile {
    param (
        [string]$resourceGroupName,
        [string]$aiServiceName
    )

    $filePath = "ai.connection.yaml"

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
}

# Function to create a Node.js Function App
function CreateNodeJSFunctionApp {
    param (
        [string]$functionAppName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$storageAccountName
    )
    
    try {
        $ErrorActionPreference = 'Stop'
        az functionapp create --name $sasFunctionAppName --consumption-plan-location $location --storage-account $storageAccountName --resource-group $resourceGroupName --runtime node --output none
        Write-Host "Node.js Function App '$sasFunctionAppName' created."
        Write-Log -message "Node.js Function App '$sasFunctionAppName' created."

        DeployNodeJSFunctionApp -functionAppName $sasFunctionAppName -resourceGroupName $resourceGroupName -location $location -storageAccountName $storageAccountName
    }
    catch {
        Write-Error "Failed to create Node.js Function App '$sasFunctionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Node.js Function App '$sasFunctionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to deploy a Node.js Function App
function DeployNodeJSFunctionApp {
    param (
        [string]$functionAppName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$storageAccountName
    )

    try {
        $ErrorActionPreference = 'Stop'
        
        # Navigate to the project directory
        Set-Location -Path $functionAppPath

        # compress the function app code
        zip -r $functionAppCodePath.zip $functionAppCodePath

        # Initialize a git repository if not already done
        if (-not (Test-Path -Path ".git")) {
            git init
            git add .
            git commit -m "Initial commit"
        }

        # Push code to Azure
        git push azure master

        az functionapp deployment source config-zip --name $functionAppName --resource-group $resourceGroupName --src $functionAppCodePath --output none
        Write-Host "Node.js Function App '$functionAppName' deployed."
        Write-Log -message "Node.js Function App '$functionAppName' deployed."
    }
    catch {
        Write-Error "Failed to deploy Node.js Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to deploy Node.js Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
}

# Function to write messages to a log file
function Write-Log {
    param (
        [string]$message
    )

    $logFilePath = "deployment.log"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"

    Add-Content -Path $logFilePath -Value $logMessage
}

# Function to start the deployment
function StartDeployment {

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

    #return

    # Delete existing resource groups with the same name
    DeleteAzureResourceGroups

    # Check if the resource group exists
    $resourceGroupName = ResourceGroupExists -resourceSuffix $resourceSuffix

    if ($appendUniqueSuffix -eq $true) {

        #$resourceGroupName = "$resourceGroupName$resourceSuffix"

        # Find a unique suffix
        $resourceSuffix = FindUniqueSuffix -resourceSuffix $resourceSuffix -resourceGroupName $resourceGroupName
    }
    else {
        $userPrincipalName = "$($parameters.userPrincipalName)"

        CreateResources -storageAccountName $storageAccountName `
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
            -webAppName $webAppName `
            -functionAppName $functionAppName `
            -functionAppServicePlanName $functionAppServicePlanName `
            -openAIName $openAIName `
            -documentIntelligenceName $documentIntelligenceName
    }

    CreateAIHubAndModel -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -location $location
    
    CreateNodeJSFunctionApp -functionAppName $sasFunctionAppName -resourceGroupName $resourceGroupName -consumption-plan-location "eastus" -storageAccountName $storageAccountName

    # End the timer
    $endTime = Get-Date
    $executionTime = $endTime - $startTime

    # Format the execution time
    $executionTimeFormatted = "{0:D2} HRS : {1:D2} MIN : {2:D2} SEC : {3:D3} MS" -f $executionTime.Hours, $executionTime.Minutes, $executionTime.Seconds, $executionTime.Milliseconds

    # Log the total execution time
    $executionTimeMessage = "*** TOTAL SCRIPT EXECUTION TIME: $executionTimeFormatted ***"
    Add-Content -Path $logFilePath -Value $executionTimeMessage

    # Add a line break
    Add-Content -Path $logFilePath -Value ""
}

#**********************************************************************************************************************
# Main script
#**********************************************************************************************************************

# Initialize parameters
$initParams = InitializeParameters -parametersFile $parametersFile
#Write-Host "Parameters initialized."
#Write-Log -message "Parameters initialized."

# Extract initialized parameters
$parameters = $initParams.parameters

$userPrincipalName = $parameters.userPrincipalName

# Start the deployment
StartDeployment

#**********************************************************************************************************************
# End of script
