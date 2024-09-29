param (
    [string]$parametersFile = "parameters.json"
)

# Load parameters from the JSON file
$parameters = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json

$location = $parameters.location
$resourceSuffix = $parameters.resourceSuffix

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

$result = $false

# Function to check if a resource exists
function ResourceExists {
    param (
        [string]$resourceName,
        [string]$resourceType
    )

    if ($resourceType -eq "Microsoft.Resources/resourceGroups") {
        # Check if resource group exists
        $result = az group exists --resource-group $resourceName  
    }
    elseif ($globalResourceTypes -contains $resourceType) {
        switch ($resourceType) {
            "Microsoft.Storage/storageAccounts" {
                $result = az storage account check-name --name $resourceName --query "nameAvailable" --output tsv
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
                $result = az search service list --query "[?name=='$resourceName'].name" --output tsv
            }
        }

        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Output "$resourceName exists."
            return $true
        }
        else {
            Write-Output "$resourceName does not exist."
            return $false
        }
    } 
    else {
        # Check within the subscription
        $result = az resource list --name $resourceName --resource-type $resourceType --query "[].name" --output tsv
        if (-not [string]::IsNullOrEmpty($result)) {
            Write-Output "$resourceName exists."
            return $true
        }
        else {
            Write-Output "$resourceName does not exist."
            return $false
        }
    }
}

# Function to find a unique suffix
function FindUniqueSuffix {
    param (
        [int]$resourceSuffix
    )
    do {
        $resourceGroupName = "$($parameters.resourceGroupName)-$resourceSuffix"
        $storageAccountName = "$($parameters.storageAccountName)$resourceSuffix"
        $appServicePlanName = "$($parameters.appServicePlanName)-$resourceSuffix"
        $searchServiceName = "$($parameters.searchServiceName)-$resourceSuffix"
        $logAnalyticsWorkspaceName = "$($parameters.logAnalyticsWorkspaceName)-$resourceSuffix"
        $cognitiveServiceName = "$($parameters.cognitiveServiceName)-$resourceSuffix"
        $keyVaultName = "$($parameters.keyVaultName)-$resourceSuffix"
        $appInsightsName = "$($parameters.appInsightsName)-$resourceSuffix"
        $portalDashboardName = "$($parameters.portalDashboardName)-$resourceSuffix"
        $managedEnvironmentName = "$($parameters.managedEnvironmentName)-$resourceSuffix"
        $userAssignedIdentityName = "$($parameters.userAssignedIdentityName)-$resourceSuffix"
        $webAppName = "$($parameters.webAppName)-$resourceSuffix"
        $functionAppName = "$($parameters.functionAppName)-$resourceSuffix"
        $openAIName = "$($parameters.openAIName)-$resourceSuffix"
        $documentIntelligenceName = "$($parameters.documentIntelligenceName)-$resourceSuffix"

        $resourceExists = ResourceExists $resourceGroupName "Microsoft.Resources/resourceGroups" -or
        ResourceExists $storageAccountName "Microsoft.Storage/storageAccounts" -or
        ResourceExists $appServicePlanName "Microsoft.Web/serverFarms" -or
        ResourceExists $searchServiceName "Microsoft.Search/searchServices" -or
        ResourceExists $logAnalyticsWorkspaceName "Microsoft.OperationalInsights/workspaces" -or
        ResourceExists $cognitiveServiceName "Microsoft.CognitiveServices/accounts" -or
        ResourceExists $keyVaultName "Microsoft.KeyVault/vaults" -or
        ResourceExists $appInsightsName "Microsoft.Insights/components" -or
        ResourceExists $portalDashboardName "Microsoft.Portal/dashboards" -or
        ResourceExists $managedEnvironmentName "Microsoft.App/managedEnvironments" -or
        ResourceExists $userAssignedIdentityName "Microsoft.ManagedIdentity/userAssignedIdentities" -or
        ResourceExists $webAppName "Microsoft.Web/sites" -or
        ResourceExists $functionAppName "Microsoft.Web/sites" -or
        ResourceExists $openAIName "Microsoft.CognitiveServices/accounts" -or
        ResourceExists $documentIntelligenceName "Microsoft.CognitiveServices/accounts"

        if ($resourceExists) {
            $resourceSuffix++
        }
    } while ($resourceExists)

    return $resourceSuffix
}

# Function to create resources
function CreateResources {
    param (
        [string]$resourceGroupName,
        [string]$location,
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

    az group create --name $resourceGroupName --location $location --output none
    Write-Output "Resource group '$resourceGroupName' created."

    az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --output none
    Write-Output "Storage account '$storageAccountName' created."

    az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku B1 --output none
    Write-Output "App Service Plan '$appServicePlanName' created."

    az search service create --name $searchServiceName --resource-group $resourceGroupName --location $location --sku Basic --output none
    Write-Output "Search Service '$searchServiceName' created."

    az monitor log-analytics workspace create --workspace-name $logAnalyticsWorkspaceName --resource-group $resourceGroupName --location $location --output none
    Write-Output "Log Analytics Workspace '$logAnalyticsWorkspaceName' created."

    az cognitiveservices account create --name $cognitiveServiceName --resource-group $resourceGroupName --location $location --kind CognitiveServices --sku S0 --output none
    Write-Output "Cognitive Services account '$cognitiveServiceName' created."

    az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --output none
    Write-Output "Key Vault '$keyVaultName' created."

    az monitor app-insights component create --app $appInsightsName --resource-group $resourceGroupName --location $location --application-type web --output none
    Write-Output "Application Insights component '$appInsightsName' created."

    az portal dashboard create --name $portalDashboardName --resource-group $resourceGroupName --location $location --output none
    Write-Output "Portal Dashboard '$portalDashboardName' created."

    az managedenvironment create --name $managedEnvironmentName --resource-group $resourceGroupName --location $location --output none
    Write-Output "Managed Environment '$managedEnvironmentName' created."

    az identity create --name $userAssignedIdentityName --resource-group $resourceGroupName --location $location --output none
    Write-Output "User Assigned Identity '$userAssignedIdentityName' created."

    az webapp create --name $webAppName --resource-group $resourceGroupName --plan $appServicePlanName --output none
    Write-Output "Web App '$webAppName' created."

    az functionapp create --name $functionAppName --storage-account $storageAccountName --resource-group $resourceGroupName --plan $appServicePlanName --runtime dotnet --runtime-version 3.1 --functions-version 3 --output none
    Write-Output "Function App '$functionAppName' created."

    az cognitiveservices account create --name $openAIName --resource-group $resourceGroupName --location $location --kind OpenAI --sku S0 --output none
    Write-Output "Azure OpenAI account '$openAIName' created."

    az cognitiveservices account create --name $documentIntelligenceName --resource-group $resourceGroupName --location $location --kind FormRecognizer --sku S0 --output none
    Write-Output "Document Intelligence account '$documentIntelligenceName' created."
}

# Find a unique suffix
$resourceSuffix = FindUniqueSuffix -resourceSuffix $resourceSuffix


# Create resources
<#
 # {CreateResources -resourceGroupName $resourceGroupName `
                -location $location `
                -storageAccountName $storageAccountName `
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
                -documentIntelligenceName $documentIntelligenceName:Enter a comment or description}
#>
