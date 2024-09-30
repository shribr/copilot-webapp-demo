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
        [string]$parametersFile
    )

    # Load parameters from the JSON file
    $parameters = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

    # Retrieve the subscription ID
    $global:subscriptionId = az account show --query "id" --output tsv
    # Retrieve the tenant ID
    $global:tenantId = az account show --query "tenantId" --output tsv
    # Retrieve the object ID of the signed-in user
    $global:objectId = az ad signed-in-user show --query "objectId" --output tsv
    # Retrieve the location
    $global:location = $parameters.location
    # Retrieve the resource suffix
    $global:resourceSuffix = $parameters.resourceSuffix
    # Initialize the result variable
    $global:result = $false
    # Generate a unique resource GUID
    $global:resourceGuid = SplitGuid
    # Retrieve the resource group name
    $global:resourceGroupName = $parameters.resourceGroupName
    # Retrieve the model name and type
    $global:aiModelName = $parameters.aiModelName
    # Retrieve the model type
    $global:aiModelType = $parameters.aiModelType
    # Retrieve the AI Hub name
    $global:aiHubName = $parameters.aiHubName
    # Retrieve the AI model version
    $global:aiModelVersion = $parameters.aiModelVersion
    $global:aiServiceName = $parameters.aiServiceName

    return @{
        parameters        = $parameters
        subscriptionId    = $subscriptionId
        tenantId          = $tenantId
        objectId          = $objectId
        location          = $location
        resourceSuffix    = $resourceSuffix
        result            = $result
        resourceGuid      = $resourceGuid
        resourceGroupName = $resourceGroupName
        aiModelName       = $aiModelName
        aiModelType       = $aiModelType
        aiHubName         = $aiHubName
        aiModelVersion    = $aiModelVersion
        aiServiceName     = $aiServiceName
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
        [string]$resourceType
    )

    if ($resourceType -eq "functionapp") {
        $runtime = az functionapp list-runtimes --query "[?platform=='dotnet'].majorVersion" --output json | ConvertFrom-Json
    }
    elseif ($resourceType -eq "webapp") {
        $runtime = az webapp list-runtimes --query "[?platform=='dotnet'].majorVersion" --output json | ConvertFrom-Json
    }
    else {
        throw "Unsupported resource type: $resourceType"
    }

    $latestRuntime = ($runtime | Sort-Object -Descending)[0]
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
        [string]$webAppName,
        [string]$functionAppName,
        [string]$openAIName,
        [string]$documentIntelligenceName
    )

    # Get the latest API versions
    $storageApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Storage" -resourceType "storageAccounts"
    $appServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Web" -resourceType "serverFarms"
    $searchApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Search" -resourceType "searchServices"
    $logAnalyticsApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.OperationalInsights" -resourceType "workspaces"
    $cognitiveServicesApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
    #$keyVaultApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.KeyVault" -resourceType "vaults"
    $appInsightsApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.Insights" -resourceType "components"
   
    # Debug statements to print variable values
    Write-Host "subscriptionId: $subscriptionId"
    Write-Host "resourceGroupName: $resourceGroupName"
    Write-Host "storageAccountName: $storageAccountName"
    Write-Host "appServicePlanName: $appServicePlanName"
    Write-Host "location: $location"


    # **********************************************************************************************************************
    # Create resources using the Azure REST API
    # **********************************************************************************************************************

    # **********************************************************************************************************************
    # Create a storage account

    $storageAccountUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $storageAccountName, $storageApiVersion
    
    #Write-Host "Constructed storageAccountUrl: $storageAccountUrl"

    $storageAccountProperties = @{
        location   = $location
        sku        = @{
            name = "Standard_LRS"
        }
        kind       = "StorageV2"
        properties = @{}
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $storageAccountProperties | ConvertTo-Json -Depth 10

    try {
        Invoke-AzureRestMethod -method "PUT" -url $storageAccountUrl -jsonBody $jsonBody
        Write-Host "Storage account '$storageAccountName' created."
        Write-Log -message "Storage account '$storageAccountName' created."
    }
    catch {
        Write-Error "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Storage Account '$storageAccountName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # **********************************************************************************************************************
    # Create an App Service Plan

    $appServicePlanUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/serverFarms/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $appServicePlanName, $appServiceApiVersion

    #Write-Host "Constructed appServicePlanUrl: $appServicePlanUrl"
    #Write-Log -message "Constructed appServicePlanUrl: $appServicePlanUrl"

    $appServicePlanProperties = @{
        location   = $location
        sku        = @{
            name = "B1"
        }
        properties = @{}
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $appServicePlanProperties | ConvertTo-Json -Depth 10

    # Try to create an App Service Plan
    try {
        Invoke-AzureRestMethod -method "PUT" -url $appServicePlanUrl -jsonBody $jsonBody
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

    $searchServiceUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Search/searchServices/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $searchServiceName, $searchApiVersion

    #Write-Host "Constructed searchServiceUrl: $searchServiceUrl"
    #Write-Log -message "Constructed searchServiceUrl: $searchServiceUrl"
    
    $searchServiceProperties = @{
        location   = $location
        sku        = @{
            name = "basic"
        }
        properties = @{}
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $searchServiceProperties | ConvertTo-Json -Depth 10

    # Try to create a Search Service
    try {
        Invoke-AzureRestMethod -method "PUT" -url $searchServiceUrl -jsonBody $jsonBody
        Write-Host "Search Service '$searchServiceName' created."
        Write-Log -message "Search Service '$searchServiceName' created."
    }
    catch {
        Write-Error "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Search Service '$searchServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # **********************************************************************************************************************
    # Create a Log Analytics Workspace

    $logAnalyticsWorkspaceName = Get-ValidServiceName -serviceName $logAnalyticsWorkspaceName

    $logAnalyticsWorkspaceUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $logAnalyticsWorkspaceName, $logAnalyticsApiVersion

    #Write-Host "Constructed logAnalyticsWorkspaceUrl: $logAnalyticsWorkspaceUrl"
    #Write-Log -message "Constructed logAnalyticsWorkspaceUrl: $logAnalyticsWorkspaceUrl"

    $logAnalyticsWorkspaceProperties = @{
        location   = $location
        properties = @{}
    }
    # Convert the properties to JSON and inspect
    $jsonBody = $logAnalyticsWorkspaceProperties | ConvertTo-Json -Depth 10

    try {
        Invoke-AzureRestMethod -method "PUT" -url $logAnalyticsWorkspaceUrl -jsonBody $jsonBody

        Write-Host "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
        Write-Log -message "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."
    }
    catch {
        Write-Error "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Log Analytics Workspace '$logAnalyticsWorkspaceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    #**********************************************************************************************************************
    # Create a Cognitive Services account

    $cognitiveServiceName = Get-ValidServiceName -serviceName $cognitiveServiceName

    $cognitiveServicesUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.CognitiveServices/accounts/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $cognitiveServiceName, $cognitiveServicesApiVersion

    #Write-Host "Constructed cognitiveServicesUrl: $cognitiveServicesUrl"
    #Write-Log -message "Constructed cognitiveServicesUrl: $cognitiveServicesUrl"

    $cognitiveServicesProperties = @{
        location   = $location
        sku        = @{
            name = "S0"
        }
        kind       = "CognitiveServices"
        properties = @{}
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $cognitiveServicesProperties | ConvertTo-Json -Depth 10

    # Try to create a Cognitive Services account
    try {
        Invoke-AzureRestMethod -method "PUT" -url $cognitiveServicesUrl -jsonBody $jsonBody
        Write-Host "Cognitive Services account '$cognitiveServiceName' created."
        Write-Log -message "Cognitive Services account '$cognitiveServiceName' created."
    }
    catch {
        Write-Error "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Cognitive Services account '$cognitiveServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    <#
    #**********************************************************************************************************************
    # Create a Key Vault

    $keyVaultName = Get-ValidServiceName -serviceName $keyVaultName

    $keyVaultUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $keyVaultName, $keyVaultApiVersion

    #Write-Host "Constructed keyVaultUrl: $keyVaultUrl"
    
    $keyVaultProperties = @{
        sku        = @{
            family = "A"
            name   = "standard"
        }
        tenantId   = $tenantId
        properties = @{
            accessPolicies = @(
                @{
                    tenantId    = $tenantId
                    objectId    = $objectId
                    permissions = @{
                        keys         = @("get", "list", "update", "create", "import", "delete", "backup", "restore", "recover", "purge", "encrypt", "decrypt", "unwrapKey", "wrapKey")
                        secrets      = @("get", "list", "set", "delete", "backup", "restore", "recover", "purge", "encrypt", "decrypt")
                        certificates = @("get", "list", "delete", "create", "import", "update", "managecontacts", "getissuers", "listissuers", "setissuers", "deleteissuers", "manageissuers", "recover", "purge")
                    }
                }
            )
        }
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $keyVaultProperties | ConvertTo-Json -Depth 10

    # Try to create a Key Vault
    try {
        Invoke-AzureRestMethod -method "PUT" -url $keyVaultUrl -jsonBody $jsonBody 
        Write-Host "Key Vault '$keyVaultName' created."
        Write-Log -message "Key Vault '$keyVaultName' created."
    }
    catch {
        Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
    #>

    #**********************************************************************************************************************
    # Create an Application Insights component

    $appInsightsName = Get-ValidServiceName -serviceName $appInsightsName

    $appInsightsUrl = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Insights/components/{2}?api-version={3}" -f $subscriptionId, $resourceGroupName, $appInsightsName, $appInsightsApiVersion

    #Write-Host "Constructed appInsightsUrl: $appInsightsUrl"
    #Write-Log -message "Constructed appInsightsUrl: $appInsightsUrl"
    
    $appInsightsProperties = @{
        location   = $location
        kind       = "web"
        properties = @{
            Application_Type = "web"
        }
    }

    # Convert the properties to JSON and inspect
    $jsonBody = $appInsightsProperties | ConvertTo-Json -Depth 10

    #Try to create an Application Insights component
    try {
        Invoke-AzureRestMethod -method "PUT" -url $appInsightsUrl -jsonBody $jsonBody
    
        Write-Host "Application Insights component '$appInsightsName' created."
        Write-Log -message "Application Insights component '$appInsightsName' created."
    }
    catch {
        Write-Error "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Application Insights component '$appInsightsName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    #**********************************************************************************************************************
    # End create resources using the Azure REST API
    #**********************************************************************************************************************
    
    # Try to create a User Assigned Identity
    try {
        az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none
        Write-Host "User Assigned Identity '$userAssignedIdentityName' created."
        Write-Log -message "User Assigned Identity '$userAssignedIdentityName' created."
    }
    catch {
        Write-Error "Failed to create User Assigned Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create User Assigned Identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Try to create a Web App
    try {
        az webapp create --name $webAppName --resource-group $resourceGroupName --plan $appServicePlanName --output none
        Write-Host "Web App '$webAppName' created."
        Write-Log -message "Web App '$webAppName' created."

        # Assign the managed identity to the web app
        try {
            az webapp identity assign --name $webAppName --resource-group $resourceGroupName --identities $userAssignedIdentityName
            Write-Host "Managed identity '$userAssignedIdentityName' assigned to Web App '$webAppName'."
            Write-Log -message "Managed identity '$userAssignedIdentityName' assigned to Web App '$webAppName'."
        }
        catch {
            Write-Error "Failed to assign managed identity '$userAssignedIdentityName' to Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to assign managed identity '$userAssignedIdentityName' to Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    catch {
        Write-Error "Failed to create Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Web App '$webAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create the Key Vault with RBAC enabled
    try {
        az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --output none
        Write-Host "Key Vault: '$keyVaultName' created."
        Write-Log -message "Key Vault: '$keyVaultName' created."

        # Assign RBAC roles to the managed identity
        try {
            $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
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

        try {
            az keyvault set-policy --name $keyVaultName --resource-group $resourceGroupName --spn $webAppName --key-permissions get list update create import delete backup restore recover purge encrypt decrypt unwrapKey wrapKey --secret-permissions get list set delete backup restore recover purge encrypt decrypt --certificate-permissions get list delete create import update managecontacts getissuers listissuers setissuers deleteissuers manageissuers recover purge
            Write-Host "Policy permissions set for Key Vault: '$keyVaultName'."
            Write-Log -message "Policy permissions set for Key Vault: '$keyVaultName'."
        }
        catch {
            Write-Error "Failed to set policy permissions for Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to set policy permissions for Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }
    catch {
        Write-Error "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }


    # Loop through the array of secrets and store each one in the Key Vault
    foreach ($secretName in $globalKeyVaultSecrets) {
        # Generate a random value for the secret
        $secretValue = New-RandomPassword
    
        try {
            az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue --output none
            Write-Host "Secret: '$secretName' stored in Key Vault: '$keyVaultName'."
            Write-Log -message "Secret: '$secretName' stored in Key Vault: '$keyVaultName'."
        }
        catch {
            Write-Error "Failed to store secret '$secretName' in Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to store secret '$secretName' in Key Vault '$keyVaultName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
    }

    # Try to create a Function App
    try {
        $latestDontNetRuntimeFuncApp = Get-LatestDotNetRuntime -resourceType "functionapp"

        az functionapp create --name $functionAppName -os-type Linux --storage-account $storageAccountName --resource-group $resourceGroupName --plan $appServicePlanName --runtime dotnet --runtime-version $latestDontNetRuntimeFuncApp --functions-version 4 --output none
        #$functionApp = New-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName -StorageAccountName $storageAccountName -AppServicePlan $appServicePlanName -Location $location

        Write-Host "Function App '$functionAppName' created."
        Write-Log -message "Function App '$functionAppName' created."
    }
    catch {
        Write-Error "Failed to create Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Function App '$functionAppName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Try to create an Azure OpenAI account
    try {
        az cognitiveservices account create --name $openAIName --resource-group $resourceGroupName --location $location --kind OpenAI --sku S0 --output none
        Write-Host "Azure OpenAI account '$openAIName' created."
        Write-Log -message "Azure OpenAI account '$openAIName' created."
    }
    catch {
        Write-Error "Failed to create Azure OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Azure OpenAI account '$openAIName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Try to create a Document Intelligence account
    try {
        az cognitiveservices account create --name $documentIntelligenceName --resource-group $resourceGroupName --location $location --kind FormRecognizer --sku S0 --output none
        Write-Host "Document Intelligence account '$documentIntelligenceName' created."
        Write-Log -message "Document Intelligence account '$documentIntelligenceName' created."
    }
    catch {
        Write-Error "Failed to create Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Document Intelligence account '$documentIntelligenceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    <#
    # Try to create a Managed Environment
    try {
        az appservice ase create --name $managedEnvironmentName --resource-group $resourceGroupName --location $location --output none
        Write-Host "Managed Environment '$managedEnvironmentName' created."
        Write-Log -message "Managed Environment '$managedEnvironmentName' created."
    }
    catch {
        Write-Error "Failed to create Managed Environment: $_"
        Write-Log -message "Failed to create Managed Environment: $_"
    }
    #>
}

# Function to get the latest API version
function New-RandomPassword {
    param (
        [int]$length = 16,
        [int]$nonAlphanumericCount = 2
    )

    $alphanumericChars = [char[]]"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $nonAlphanumericChars = [char[]]"!@#$%^&*()-_=+[]{}|;:,.<>?/~"

    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $passwordChars = New-Object char[] $length

    for ($i = 0; $i -lt ($length - $nonAlphanumericCount); $i++) {
        $passwordChars[$i] = $alphanumericChars[$random.GetInt32($alphanumericChars.Length)]
    }

    for ($i = ($length - $nonAlphanumericCount); $i -lt $length; $i++) {
        $passwordChars[$i] = $nonAlphanumericChars[$random.GetInt32($nonAlphanumericChars.Length)]
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
    
    # Create AI Hub
    try {
        az cognitiveservices account create --name $aiHubName --resource-group $resourceGroupName --location $location --kind AIHub --sku S0 --output none
        Write-Host "AI Hub: '$aiHubName' created."
        Write-Log -message "AI Hub: '$aiHubName' created."
    }
    catch {
        Write-Error "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Hub '$aiHubName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create AI Service
    try {
        az cognitiveservices account create --name $aiServiceName --resource-group $resourceGroupName --location $location --kind AIServices --sku S0 --output none
        Write-Host "AI Service: '$aiServiceName' created."
        Write-Log -message "AI Service: '$aiServiceName' created."
    }
    catch {
        Write-Error "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Service '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }

    # Create AI Model Deployment
    try {
        #az cognitiveservices account deployment create --name $cognitiveServiceName --resource-group $resourceGroupName --deployment-name chat --model-name gpt-4o --model-version "0613" --model-format OpenAI --sku-capacity 1 --sku-name "Standard"
        az cognitiveservices account deployment create --name $cognitiveServiceName --resource-group $resourceGroupName --deployment-name chat --model-name gpt-4o --model-version "0613" --model-format OpenAI --sku-capacity 1 --sku-name "Standard"
        Write-Host "AI Model deployment: '$aiModelName' created."
        Write-Log -message "AI Model deployment: '$aiModelName' created."
    }
    catch {
        Write-Error "Failed to create AI Model deployment '$aiModelName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create AI Model deployment '$aiModelName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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
        [string]$cognitiveServiceName
    )

    $filePath = "ai.connection.yaml"

    #$apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $cognitiveServiceName

    $content = @"
name: $cognitiveServiceName
type: azure_ai_services
endpoint: https://eastus.api.cognitive.microsoft.com/
api_key: $apiKey
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

    # Find a unique suffix
    $resourceSuffix = FindUniqueSuffix -resourceSuffix $resourceSuffix -resourceGroupName $resourceGroupName

    #CreateAIHubAndModel -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -resourceGroupName $resourceGroupName -location $location

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
$subscriptionId = $initParams.subscriptionId
$tenantId = $initParams.tenantId
$objectId = $initParams.objectId
$location = $initParams.location
$resourceSuffix = $initParams.resourceSuffix
$result = $initParams.result
$resourceGuid = $initParams.resourceGuid
$resourceGroupName = $initParams.resourceGroupName
$aiModelName = $initParams.aiModelName
$aiModelType = $initParams.aiModelType
$aiHubName = $parameters.aiHubName
$aiModelVersion = $parameters.aiModelVersion
$aiServiceName = $parameters.aiServiceName

# Start the deployment
StartDeployment

#**********************************************************************************************************************
# End of script
