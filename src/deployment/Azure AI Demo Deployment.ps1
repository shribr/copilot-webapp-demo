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

# Mapping of global AI Hub connected resources
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
        [string]$storageAccountName,
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
function Deploy-OpenAIModel {
    param (
        [string]$resourceGroupName,
        [string]$aiServiceName,
        [string]$aiModelName,
        [string]$aiModelType,
        [string]$aiModelVersion,
        [string]$aiModelApiVersion,
        [string]$aiModelFormat,
        [string]$aiModelSkuName,
        [string]$aiModelSkuCapacity,
        [string]$aiModelDeploymentName
    )

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

                $errorMessage = "Failed to deploy Model '$aiModelName' for '$aiServiceName'. `
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
        Write-Error "Failed to create Model deployment '$deploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to create Model deployment '$deploymentName' for '$aiServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
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
    $global:aiModelDeploymentName = $parametersObject.aiModelDeploymentName
    $global:aiModelFormat = $parametersObject.aiModelFormat
    $global:aiModelName = $parametersObject.aiModelName
    $global:aiModels = $parametersObject.aiModels
    $global:aiModelSkuCapacity = $parametersObject.aiModelSkuCapacity
    $global:aiModelSkuName = $parametersObject.aiModelSkuName
    $global:aiModelType = $parametersObject.aiModelType
    $global:aiModelVersion = $parametersObject.aiModelVersion
    $global:aiProjectName = $parametersObject.aiProjectName
    $global:aiServiceName = $parametersObject.aiServiceName
    $global:aiServiceProperties = $parametersObject.aiServiceProperties
    $global:apiManagementService = $parametersObject.apiManagementService
    $global:appDeploymentOnly = $parametersObject.appDeploymentOnly
    $global:appendUniqueSuffix = $parametersObject.appendUniqueSuffix
    $global:appInsightsName = $parametersObject.appInsightsName
    $global:appServiceEnvironmentName = $parametersObject.appServiceEnvironmentName
    $global:appServicePlanName = $parametersObject.appServicePlanName
    $global:appServicePlanSku = $parametersObject.appServicePlanSku
    $global:appServices = $parametersObject.appServices
    $global:blobStorageAccountName = $parametersObject.blobStorageAccountName
    $global:blobStorageContainerName = $parametersObject.blobStorageContainerName
    $global:cognitiveServiceName = $parametersObject.cognitiveServiceName
    $global:computerVisionName = $parametersObject.computerVisionName
    $global:configFilePath = $parametersObject.configFilePath
    $global:containerAppName = $parametersObject.containerAppName
    $global:containerAppsEnvironmentName = $parametersObject.containerAppsEnvironmentName
    $global:containerRegistryName = $parametersObject.containerRegistryName
    $global:containerRegistryProperties = $parametersObject.containerRegistryProperties
    $global:cosmosDbAccountName = $parametersObject.cosmosDbAccountName
    $global:createResourceGroup = $parametersObject.createResourceGroup
    $global:deleteResourceGroup = $parametersObject.deleteResourceGroup
    $global:deployZipResources = $parametersObject.deployZipResources
    $global:documentIntelligenceName = $parametersObject.documentIntelligenceName
    $global:eventHubNamespaceName = $parametersObject.eventHubNamespaceName
    $global:keyVaultName = $parametersObject.keyVaultName
    $global:location = $parametersObject.location
    $global:logAnalyticsWorkspaceName = $parametersObject.logAnalyticsWorkspaceName
    $global:machineLearningProperties = $parametersObject.machineLearningProperties
    $global:machineLearningWorkspace = $parametersObject.machineLearningWorkspace
    $global:managedIdentityName = $parametersObject.managedIdentityName
    $global:openAIAccountName = $parametersObject.openAIAccountName
    $global:openAIApiKey = $parametersObject.openAIApiKey
    $global:openAIApiVersion = $parametersObject.openAIApiVersion
    $global:openAIServiceProperties = $parametersObject.openAIServiceProperties
    $global:portalDashboardName = $parametersObject.portalDashboardName
    $global:previousResourceBaseName = $parametersObject.previousResourceBaseName
    $global:privateEndPointName = $parametersObject.privateEndPointName
    $global:redisCacheName = $parametersObject.redisCacheName
    $global:redeployResources = $parametersObject.redeployResources
    $global:resourceBaseName = $parametersObject.resourceBaseName
    $global:resourceGroupName = $parametersObject.resourceGroupName
    $global:resourceSuffix = $parametersObject.resourceSuffix
    $global:restoreSoftDeletedResource = $parametersObject.restoreSoftDeletedResource
    $global:searchDataSourceName = $parametersObject.searchDataSourceName
    $global:searchEndpoint = $parametersObject.searchEndpoint
    $global:searchIndexFieldNames = $parametersObject.searchIndexFieldNames
    $global:searchIndexName = $parametersObject.searchIndexName
    $global:searchIndexerName = $parametersObject.searchIndexerName
    $global:searchIndexers = $parametersObject.searchIndexers
    $global:searchIndexes = $parametersObject.searchIndexes
    $global:searchAzureOpenAIModel = $parametersObject.searchAzureOpenAIModel
    $global:searchPublicInternetResults = $parametersObject.searchPublicInternetResults
    $global:searchServiceApiVersion = $parametersObject.searchServiceApiVersion
    $global:searchServiceName = $parametersObject.searchServiceName
    $global:searchServiceProperties = $parametersObject.searchServiceProperties
    $global:searchSkillSet = $parametersObject.searchSkillSet
    $global:searchSkillSetName = $parametersObject.searchSkillSetName
    $global:searchSkillSetSchema = $parametersObject.searchSkillSetSchema
    $global:searchSkillSets = $parametersObject.searchSkillSets
    $global:searchVectorIndexName = $parametersObject.searchVectorIndexName
    $global:searchVectorIndexerName = $parametersObject.searchVectorIndexerName
    $global:serviceBusNamespaceName = $parametersObject.serviceBusNamespaceName
    $global:serviceProperties = $parametersObject.serviceProperties
    $global:sharedDashboardName = $parametersObject.sharedDashboardName
    $global:siteLogo = $parametersObject.siteLogo
    $global:sqlServerName = $parametersObject.sqlServerName
    $global:storageApiVersion = $parametersObject.storageApiVersion
    $global:storageAccountName = $parametersObject.storageAccountName
    $global:storageServiceProperties = $parametersObject.storageServiceProperties
    $global:subNet = $parametersObject.subNet
    $global:subNetName = $parametersObject.subNetName
    $global:userAssignedIdentityName = $parametersObject.userAssignedIdentityName
    $global:virtualNetwork = $parametersObject.virtualNetwork

    # Make sure the previousResourceBaseName parameter in the parameters.json file is different than the resourceBaseName parameter. 
    # What this code does is determine whether or not you are attempting to redeploy the same resources with the same base name or if you are trying to provision an entirely new deployment with a new resource group name etc.
    if ($parametersObject.previousResourceBaseName -eq $parametersObject.resourceBaseName -and $redeployResources -eq $false) {
        Write-Host "The previousResourceBaseName parameter is the same as the resourceBaseName parameter. Please change the previousResourceBaseName parameter to a different value."
        exit
    }

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

    Write-Host "searchSkillSetName from parametersObject: $($parametersObject.searchSkillSetName)"
    Write-Host "searchSkillSetName from global: $($global:searchSkillSetName)"

    Write-Host "virtualNetworkName from parametersObject: $($parametersObject.virtualNetwork.Name)"
    Write-Host "virtualNetworkName from global: $($global:virtualNetwork.Name)"

    Write-Host "appServiceEnvironmentName from parametersObject: $($parametersObject.appServiceEnvironmentName)"
    Write-Host "appServiceEnvironmentName from global: $($global:appServiceEnvironmentName)"

    return @{
        aiDeploymentName             = $aiDeploymentName
        aiHubName                    = $aiHubName
        aiModelDeploymentName        = $aiModelDeploymentName
        aiModelFormat                = $aiModelFormat
        aiModelName                  = $aiModelName
        aiModels                     = $aiModels
        aiModelSkuCapacity           = $aiModelSkuCapacity
        aiModelSkuName               = $aiModelSkuName
        aiModelType                  = $aiModelType
        aiModelVersion               = $aiModelVersion
        aiProjectName                = $aiProjectName
        aiServiceName                = $aiServiceName
        aiServiceProperties          = $aiServiceProperties
        apiManagementService         = $apiManagementService
        appDeploymentOnly            = $appDeploymentOnly
        appendUniqueSuffix           = $appendUniqueSuffix
        appInsightsName              = $appInsightsName
        appServiceEnvironmentName    = $appServiceEnvironmentName
        appServicePlanName           = $appServicePlanName
        appServicePlanSku            = $appServicePlanSku
        appServices                  = $appServices
        blobStorageAccountName       = $blobStorageAccountName
        blobStorageContainerName     = $blobStorageContainerName
        cognitiveServiceName         = $cognitiveServiceName
        computerVisionName           = $computerVisionName
        configFilePath               = $configFilePath
        containerAppName             = $containerAppName
        containerAppsEnvironmentName = $containerAppsEnvironmentName
        containerRegistryName        = $containerRegistryName
        containerRegistryProperties  = $containerRegistryProperties
        cosmosDbAccountName          = $cosmosDbAccountName
        createResourceGroup          = $createResourceGroup
        deleteResourceGroup          = $deleteResourceGroup
        deployZipResources           = $deployZipResources
        documentIntelligenceName     = $documentIntelligenceName
        eventHubNamespaceName        = $eventHubNamespaceName
        keyVaultName                 = $keyVaultName
        location                     = $location
        logAnalyticsWorkspaceName    = $logAnalyticsWorkspaceName
        machineLearningProperties    = $machineLearningProperties
        machineLearningWorkspace     = $machineLearningWorkspace
        managedIdentityName          = $managedIdentityName
        objectId                     = $objectId
        openAIAccountName            = $openAIAccountName
        openAIKey                    = $openAIApiKey
        openAIApiVersion             = $openAIApiVersion
        openAIServiceProperties      = $openAIServiceProperties
        parameters                   = $parametersObject
        portalDashboardName          = $portalDashboardName
        previousResourceBaseName     = $previousResourceBaseName
        privateEndPointName          = $privateEndPointName
        redeployResources            = $redeployResources
        redisCacheName               = $redisCacheName
        resourceBaseName             = $resourceBaseName
        resourceGroupName            = $resourceGroupName
        resourceGuid                 = $resourceGuid
        resourceSuffix               = $resourceSuffix
        restoreSoftDeletedResource   = $restoreSoftDeletedResource
        result                       = $result
        searchDataSourceName         = $searchDataSourceName
        searchEndpoint               = $searchEndpoint
        searchIndexFieldNames        = $searchIndexFieldNames
        searchIndexName              = $searchIndexName
        searchIndexerName            = $searchIndexerName
        searchIndexes                = $searchIndexes
        searchIndexers               = $searchIndexers
        searchAzureOpenAIModel       = $searchAzureOpenAIModel
        searchPublicInternetResults  = $searchPublicInternetResults
        searchServiceApiVersion      = $searchServiceApiVersion
        searchServiceName            = $searchServiceName
        searchServiceProperties      = $searchServiceProperties
        searchSkillSet               = $searchSkillSet
        searchSkillSetName           = $searchSkillSetName
        searchSkillSetSchema         = $searchSkillSetSchema
        searchSkillSets              = $searchSkillSets
        searchVectorIndexName        = $searchVectorIndexName
        searchVectorIndexerName      = $searchVectorIndexerName
        serviceBusNamespaceName      = $serviceBusNamespaceName
        serviceProperties            = $serviceProperties
        sharedDashboardName          = $sharedDashboardName
        siteLogo                     = $siteLogo
        sqlServerName                = $sqlServerName
        storageAccountName           = $storageAccountName
        storageApiVersion            = $storageApiVersion
        storageServiceProperties     = $storageServiceProperties
        subNet                       = $subNet
        subNetName                   = $subNetName
        subscriptionId               = $subscriptionId
        tenantId                     = $tenantId
        userAssignedIdentityName     = $userAssignedIdentityName
        userPrincipalName            = $userPrincipalName
        virtualNetwork               = $virtualNetwork
    }
}

# Function to create a new AI Hub
function New-AIHub {
    param (
        [string]$aiHubName,
        [string]$aiModelName,
        [string]$aiModelType,
        [string]$aiModelVersion,
        [string]$aiServiceName,
        [string]$resourceGroupName,
        [string]$location,
        [string]$appInsightsName,
        [string]$userAssignedIdentityName,
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
            
            $global:resourceCounter += 1
            Write-Host "AI Hub: '$aiHubName' created successfully. ($global:resourceCounter)"
            Write-Log -message "AI Hub: '$aiHubName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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

        #$storageAccountResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
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
            -storageAccountName $storageAccountResourceId `
            -containerRegistryName $containerRegistryResourceId `
            -keyVaultName $keyVaultResourceId `
            -userAssignedIdentityName $userAssignedIdentityResourceId:Enter a comment or description}
#>

        #az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName 2>&1
        #$jsonOutput = az ml workspace create --file $aiProjectFile --resource-group $resourceGroupName --name $aiProjectName --location $location --storage-account $storageAccountResourceId --key-vault $keyVaultResourceId --container-registry $containerRegistryResourceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId 2>&1
            
        #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

        #https://azuremlschemas.azureedge.net/latest/workspace.schema.json

        #$jsonOutput = az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName 2>&1
        #$jsonOutput = az ml workspace create --file $aiProjectFile -g $resourceGroupName --primary-user-assigned-identity $userAssignedIdentityResourceId --kind project --hub-id $aiHubResoureceId

        az ml workspace create --kind project --resource-group $resourceGroupName --name $aiProjectName --hub-id $aiHubResoureceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId --location $location
        #az ml workspace create --kind project --resource-group $resourceGroupName --name $aiProjectName --hub-id $$aiHubResoureceId --storage-account $storageAccountResourceId --key-vault $keyVaultResourceId --container-registry $containerRegistryResourceId --application-insights $appInsightsResourceId --primary-user-assigned-identity $userAssignedIdentityResourceId --location $location

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
                if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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
        Write-Host "AI Service '$aiServiceName' already exists."
        Write-Log -message "AI Service '$aiServiceName' already exists." -logFilePath $global:LogFilePath
    }
}

# Function to create and deploy Api Management service
function New-ApiManagementService {
    param (
        [string]$resourceGroupName,
        [array]$apiManagementService,
        [array]$existingResources
    )

    #https://eastus.api.cognitive.microsoft.com/documentintelligence/documentModels/prebuilt-read:analyze?api-version=2024-07-31-preview&api-key=94a688bb516141839048e01dc680192d
    #https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/rest-api/read.png
    
    $apiManagementServiceName = $apiManagementService.Name

    if ($existingResources -notcontains $apiManagementServiceName) {
        try {
            $ErrorActionPreference = 'Stop'
            $jsonOutput = az apim create -n $apiManagementServiceName --publisher-name $apiManagementService.PublisherName --publisher-email $apiManagementService.PublisherEmail --resource-group $resourceGroupName --no-wait
    
            Write-Host $jsonOutput
            
            $global:resourceCounter += 1
            Write-Host "API Management service '$apiManagementServiceName' created successfully. [$global:resourceCounter]"
            Write-Log -message "API Management service '$apiManagementServiceName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
    
        }
        catch {
            Write-Error "Failed to create API Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to create API Management service '$apiManagementServiceName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_" -logFilePath $global:LogFilePath
        }
    }
    else {
        Write-Host "API Management service '$apiManagementServiceName' already exists."
        Write-Log -message "API Management service '$apiManagementServiceName' already exists." -logFilePath $global:LogFilePath
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
        [string]$storageAccountName,
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
                }
            }
            else {

                # Check if the Function App exists
                $appExists = az functionapp show --name $appServiceName --resource-group $resourceGroupName --query "name" --output tsv

                if (-not $appExists) {
                    # Create a new function app
                    az functionapp create --name $appServiceName --resource-group $resourceGroupName --storage-account $storageAccountName --plan $appService.AppServicePlan --app-insights $appInsightsName --runtime $appService.Runtime --os-type "Windows" --functions-version 4 --output none
                    
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

            Deploy-AppService -appService $appService -resourceGroupName $resourceGroupName -deployZipResources $deployZipResources -appService $appService -deployZipPackage $deployZipPackage
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
                if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
            }
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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
                if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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
                if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
                    if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
                if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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
                if ($errorCode -match "ConflictError" && $global:restoreSoftDeletedResource) {
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
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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

        Set-KeyVaultSecrets -keyVaultName $keyVaultName `
            -resourceGroupName $resourceGroupName
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
        [string]$storageAccountName,
        [string]$keyVaultName,
        [string]$resourceGroupName,
        [string]$workspaceName,
        [string]$location,
        [array]$existingResources
    )

    $storageAccountName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
    $containerRegistryName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName"
    $keyVaultName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
    $appInsightsName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.insights/components/$appInsightsName"
    $userAssignedIdentityName = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$global:userAssignedIdentityName"

    if ($existingResources -notcontains $aiProjectName) {

        try {
            $ErrorActionPreference = 'Stop'
            
            # https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-openai?view=azureml-api-2
            # "While the az ml connection commands can be used to manage both Azure Machine Learning and Azure AI Studio connections, the OpenAI connection is specific to Azure AI Studio."

            <#
            # {            $mlWorkspaceFile = Update-MLWorkspaceFile `
                            -aiProjectName $aiProjectName `
                            -resourceGroupName $resourceGroupName `
                            -appInsightsName $appInsightsName `
                            -keyVaultName $keyVaultName `
                            -location $location `
                            -subscriptionId $subscriptionId `
                            -storageAccountName $storageAccountName `
                            -containerRegistryName $containerRegistryName `
                            -userAssignedIdentityName $userAssignedIdentityName 2>&1:Enter a comment or description}
            #>
            
            #https://learn.microsoft.com/en-us/azure/machine-learning/how-to-manage-workspace-cli?view=azureml-api-2

            #https://azuremlschemas.azureedge.net/latest/workspace.schema.json

            #$jsonOutput = az ml workspace create --file $mlWorkspaceFile --hub-id $aiHubName --resource-group $resourceGroupName --output none 2>&1
            #$jsonOutput = az ml workspace create --file $mlWorkspaceFile -g $resourceGroupName --primary-user-assigned-identity $userAssignedIdentityName --kind project --hub-id $aiHubName --output none 2>&1
            $jsonOutput = az ml workspace create --resource-group $resourceGroupName `
                --application-insights $appInsightsName `
                --description "This configuration specifies a workspace configuration with existing dependent resources" `
                --display-name "AI Studio Project / Machine Learning Workspace" `
                --location $location `
                --name $aiProjectName `
                --key-vault $keyVaultName `
                --storage-account $storageAccountName `
                --tags "Purpose: Azure AI Hub Project or Machine Learning Workspace"`
                --update-dependent-resources `
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
                if ($errorDetails -match "soft-deleted workspace" && $global:restoreSoftDeletedResource) {
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
                Write-Log -message "Machine Learning Workspace '$aiProjectName' created successfullt. [$global:resourceCounter]" -logFilePath $global:LogFilePath

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
                if ($errorCode -match "FlagMustBeSetForRestore" && $global:restoreSoftDeletedResource) {
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
                Write-Log -message "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]" 
            }

            Write-Host "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Azure OpenAI service '$openAIAccountName' created successfully. [$global:resourceCounter]" -logFilePath $global:LogFilePath
        }
        catch {
            # Check if the error is due to soft deletion
            if ($_ -match "has been soft-deleted" && $restoreSoftDeletedResource) {
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
        [array]$apiManagementService,
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
        [string]$storageAccountName,
        [array]$subNet,
        [string]$userAssignedIdentityName,
        [string]$userPrincipalName,
        [array]$virtualNetwork
    )

    # Debug statements to print variable values
    Write-Host "subscriptionId: $subscriptionId"
    Write-Host "resourceGroupName: $resourceGroupName"
    Write-Host "storageAccountName: $storageAccountName"
    Write-Host "appServicePlanName: $appServicePlanName"
    Write-Host "location: $location"
    Write-Host "userPrincipalName: $userPrincipalName"
    Write-Host "searchIndexName: $searchIndexName"
    Write-Host "searchIndexerName: $searchIndexerName"
    Write-Host "searchSkillSetName: $searchSkillSetName"

    # **********************************************************************************************************************
    # Create Storage Account

    New-StorageAccount -storageAccountName $storageAccountName -resourceGroupName $resourceGroupName -existingResources $existingResources

    #$storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv
    #$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

    # **********************************************************************************************************************
    # Create Virtual Network

    New-VirtualNetwork -virtualNetwork $virtualNetwork -resourceGroupName $resourceGroupName -existingResources $existingResources

    # **********************************************************************************************************************
    # Create Subnet

    New-SubNet -subNet $subNet -vnetName $virtualNetwork.Name -resourceGroupName $resourceGroupName -existingResources $existingResources

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
    #New-ApiManagementService -apiManagementService $apiManagementService -resourceGroupName $resourceGroupName -existingResources $existingResources

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

        $storageAccessKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv

        $searchDatasourceConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccessKey;EndpointSuffix=core.windows.net"

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

        # I need to add the identity property to the body hashtable
        <#
 # {        identity    = @{
                odata                = "#Microsoft.Azure.Search.DataUserAssignedIdentity"
                userAssignedIdentity = "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$global:userAssignedIdentityName"
            }:Enter a comment or description}
#>

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
        [string]$searchDatasourceName,
        [string]$searchIndexSchema
    )

    try {

        $content = Get-Content -Path $searchIndexSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $previousResourceBaseName, $resourceBaseName

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

        $resourceBaseName = $global:resourceBaseName

        $content = Get-Content -Path $searchIndexerSchema

        # Replace the placeholder with the actual resource base name
        $updatedContent = $content -replace $previousResourceBaseName, $resourceBaseName

        Set-Content -Path $searchIndexerSchema -Value $updatedContent
    
        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
    
        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$global:searchServiceAPiVersion"
    
        $jsonContent = Get-Content -Path $searchIndexerSchema -Raw | ConvertFrom-Json
    
        $jsonContent.'@odata.context' = $searchIndexerUrl
        $jsonContent.name = $searchIndexerName
        $jsonContent.dataSourceName = $searchDatasourceName
        $jsonContent.targetIndexName = $searchIndexName
        #$jsonContent.skillsetName = $searchSkillSetName
        $jsonContent.targetIndexName = $searchIndexName
    
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
    
        $updatedJsonContent | Set-Content -Path $searchIndexerSchema
    
        # Construct the REST API URL
        $searchServiceUrl = "https://$searchServiceName.search.windows.net/indexers?api-version=$global:searchServiceApiVersion"
    
        # Create the index
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
            $ErrorActionPreference = 'Continue'

            az search service create --name $searchServiceName --resource-group $resourceGroupName --location $location --sku basic --output none
            
            $global:resourceCounter += 1

            Write-Host "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Search Service '$searchServiceName' created successfully. [$global:resourceCounter]"

            $global:searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

            $global:searchServiceProperties.ApiKey = $global:searchServiceApiKey

            $searchManagementUrl = "https://management.azure.com/subscriptions/$global:subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
            $searchManagementUrl += "?api-version=$global:searchServiceApiVersion"

            #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
            # az search service update --name $searchServiceName --resource-group $resourceGroupName --identity SystemAssigned --aad-auth-failure-mode http401WithBearerChallenge --auth-options aadOrApiKey
            #  --identity type=UserAssigned userAssignedIdentities="/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName"
       
            try {
                $ErrorActionPreference = 'Continue'
                
                <#
                # {                $body = @{
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
                                        type                   = "UserAssigned, SystemAssigned"
                                        userAssignedIdentities = @{
                                            "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
                                        }
                                    }
                                }:Enter a comment or description}
                #>
            
                # Convert the body hashtable to JSON
                <#
                # {                $jsonBody = $body | ConvertTo-Json -Depth 10
                    
                                $accessToken = (az account get-access-token --query accessToken -o tsv)
                    
                                $headers = @{
                                    "api-key"       = $searchServiceApiKey
                                    "Authorization" = "Bearer $accessToken"  # Add the authorization header
                                }:Enter a comment or description}
                #>
    
                #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
                #Invoke-RestMethod -Uri $searchManagementUrl -Method Patch -Body $jsonBody -ContentType "application/json" -Headers $headers
                
            }
            catch {
                Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
                Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            }
            
            $dataSources = Get-DataSources -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -dataSourceName $searchDataSourceName
            $dataSourceExists = $dataSources -contains $searchDataSourceName 

            if ($dataSourceExists -eq $false) {
                New-SearchDataSource -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchDataSourceName $searchDataSourceName -storageAccountName $storageAccountName
            }
            else {
                Write-Host "Search Service Data Source '$searchDataSourceName' already exists."
                Write-Log -message "Search Service Data Source '$searchDataSourceName' already exists."
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
                    
                    foreach ($indexer in $global:searchIndexers) {
                        $indexName = $indexer.IndexName
                        $indexerName = $indexer.Name
                        $indexerSchema = $indexer.Schema
                        $indexerSkillSetName = $indexer.SkillSetName

                        $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName
                        $searchIndexerExists = $searchIndexers -contains $indexerName
    
                        if ($searchIndexerExists -eq $false) {
                            New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchIndexerName $indexerName -searchDatasourceName $searchDatasourceName -searchSkillSetName $indexerSkillSetName -searchIndexerSchema $indexerSchema -searchIndexerSchedule $searchIndexerSchedule
                        }
                        else {
                            Write-Host "Search Indexer '$indexer' already exists."
                            Write-Log -message "Search Indexer '$indexer' already exists."
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

        #$global:searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv
        
        $searchManagementUrl = "https://management.azure.com/subscriptions/$global:subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Search/searchServices/$searchServiceName"
        $searchManagementUrl += "?api-version=$global:searchServiceApiVersion"

        try {
            $ErrorActionPreference = 'Continue'

            <#
            # {            $body = @{
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
                                type                   = "UserAssigned, SystemAssigned"
                                userAssignedIdentities = @{
                                    "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentityName" = @{}
                                }
                            }
                        }:Enter a comment or description}
            #>
            
            # Convert the body hashtable to JSON
            <#
            # {            $jsonBody = $body | ConvertTo-Json -Depth 10
                
                        $accessToken = (az account get-access-token --query accessToken -o tsv)
                
                        $headers = @{
                            "api-key"       = $searchServiceApiKey
                            "Authorization" = "Bearer $accessToken"  # Add the authorization header
                        }:Enter a comment or description}
            #>
    
            #THIS IS FAILING BUT SHOULD WORK. COMMENTING OUT UNTIL I CAN FIGURE OUT WHY IT'S NOT.
            # Invoke-RestMethod -Uri $searchManagementUrl -Method Patch -Body $jsonBody -ContentType "application/json" -Headers $headers
                
        }
        catch {
            Write-Error "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
            Write-Log -message "Failed to update Search Service '$searchServiceName' with managed identity '$userAssignedIdentityName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        }
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
                    
                foreach ($indexer in $global:searchIndexers) {
                    $indexName = $indexer.IndexName
                    $indexerName = $indexer.Name
                    $indexerSchema = $indexer.Schema
                    $indexerSkillSetName = $indexer.SkillSetName

                    $searchIndexers = Get-SearchIndexers -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName
                    $searchIndexerExists = $searchIndexers -contains $indexerName
    
                    if ($searchIndexerExists -eq $false) {
                        New-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexName $indexName -searchIndexerName $indexerName -searchDatasourceName $searchDatasourceName -searchSkillSetName $indexerSkillSetName -searchIndexerSchema $indexerSchema -searchIndexerSchedule $searchIndexerSchedule
                    }
                    else {
                        Write-Host "Search Indexer '$indexer' already exists."
                        Write-Log -message "Search Indexer '$indexer' already exists."
                    }

                    Start-SearchIndexer -searchServiceName $searchServiceName -resourceGroupName $resourceGroupName -searchIndexerName $indexerName

                }

                Start-Sleep -Seconds 10
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
        [string]$storageAccountName,
        [string]$location,
        [array]$existingResources
    )

    if ($existingResources -notcontains $storageAccountName) {

        try {
            az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --output none
            
            $global:resourceCounter += 1

            Write-Host "Storage account '$storageAccountName' created successfully. [$global:resourceCounter]"
            Write-Log -message "Storage account '$storageAccountName' created successfully. [$global:resourceCounter]"

            # Retrieve the storage account key
            $global:storageServiceAccountKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" --output tsv
        
            $global:storageServiceProperties.Credentials.AccountKey = $global:storageServiceAccountKey
            
            # Enable CORS
            az storage cors clear --account-name $storageAccountName --services bfqt
            az storage cors add --methods GET POST PUT --origins '*' --allowed-headers '*' --exposed-headers '*' --max-age 200 --services b --account-name $storageAccountName --account-key $storageAccessKey
            
            az storage container create --name $blobStorageContainerName --account-name $storageAccountName --account-key $global:storageServiceAccountKey --output none

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
}

# Function to create a new subnet
function New-SubNet {
    param (
        [string]$resourceGroupName,
        [string]$vnetName,
        [array]$subnet,
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
        [array]$virtualNetwork,
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

    if ($global:appDeploymentOnly -eq $true) {
        # Deploy web app and function app services
        foreach ($appService in $appServices) {
            Deploy-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $global:storageAccountName -deployZipResources $true
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

    if ($appendUniqueSuffix -eq $true) {

        # Find a unique suffix
        $resourceSuffix = Get-UniqueSuffix -resourceSuffix $resourceSuffix -resourceGroupName $resourceGroupName

        New-Resources -aiProjectName $aiProjectName `
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
            -storageAccountName $storageAccountName `
            -subNet $subNet `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -virtualNetwork $virtualNetwork
    }
    else {

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
            -storageAccountName $storageAccountName `
            -subNet $subNet `
            -userAssignedIdentityName $userAssignedIdentityName `
            -userPrincipalName $userPrincipalName `
            -virtualNetwork $virtualNetwork
    }

    # Create new web app and function app services
    foreach ($appService in $appServices) {
        if ($existingResources -notcontains $appService.Name) {
            New-AppService -appService $appService -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName -deployZipResources $false
        }
    }

    $useRBAC = $false

    #**********************************************************************************************************************
    # Create Key Vault

    if ($existingResources -notcontains $keyVaultName) {
        New-KeyVault -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -location $location -useRBAC $useRBAC -userAssignedIdentityName $userAssignedIdentityName -userPrincipalName $userPrincipalName -existingResources $existingResources
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

    $userAssignedIdentityName = $global:userAssignedIdentityName

    # Create a new AI Hub and Model
    New-AIHub -aiHubName $aiHubName -aiModelName $aiModelName -aiModelType $global:aiModelType -aiModelVersion $aiModelVersion -aiServiceName $aiServiceName -appInsightsName $appInsightsName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources -userAssignedIdentityName $userAssignedIdentityName -containerRegistryName $containerRegistryName
    
    # Create a new AI Service
    New-AIService -aiServiceName $aiServiceName -resourceGroupName $resourceGroupName -location $location -existingResources $existingResources

    # The CLI needs to be updated to allow Azure AI Studio projects to be created correctly. 
    # This code will create a new workspace in ML Studio but not in AI Studio. 
    # I am still having this code execute so that the rest of the script doesn't error out. 
    # Once the enture script completes the code will delete the ML workspace.
    # This is admittedly a hack but it is the only way to get the script to work for now.

    # Create AI Studio AI Project / ML Studio Workspace

    New-MachineLearningWorkspace -resourceGroupName $resourceGroupName `
        -subscriptionId $global:subscriptionId `
        -aiHubName $aiHubName `
        -storageAccountName $storageAccountName `
        -containerRegistryName $global:containerRegistryName `
        -keyVaultName $keyVaultName `
        -appInsightsName $appInsightsName `
        -aiProjectName $aiProjectName `
        -userAssignedIdentityName $userAssignedIdentityName `
        -location $location `
        -existingResources $existingResources

    Start-Sleep -Seconds 10

    # Deploy AI Models

    foreach ($aiModel in $global:aiModels) {
        $aiModelName = $aiModel.Name
        $aiModelType = $aiModel.Type
        $aiModelVersion = $aiModel.ModelVersion
        $aiModelApiVersion = $aiModel.ApiVersion
        $aiServiceName = $global:aiServiceName
        $aiModelFormat = $aiModel.Format
        $aiModelSkuName = $aiModel.Sku.Name
        $aiModelSkuCapacity = $aiModel.Sku.Capacity
        
        Deploy-OpenAIModel -aiModelDeploymentName $aiModelName -aiServiceName $aiServiceName -aiModelName $aiModelName -aiModelType $aiModelType -aiModelVersion $aiModelVersion -aiModelApiVersion $aiModelApiVersion -resourceGroupName $resourceGroupName -aiModelFormat $aiModelFormat -aiModelSkuName $aiModelSkuName -aiModelSkuCapacity $aiModelSkuCapacity -existingResources $existingResources
    }

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
        -storageAccountName $storageAccountName `
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

    try {
        $ErrorActionPreference = 'Stop'

        $searchServiceApiKey = az search admin-key show --resource-group $resourceGroupName --service-name $searchServiceName --query "primaryKey" --output tsv

        $searchIndexerUrl = "https://$searchServiceName.search.windows.net/indexers/$searchIndexerName/run?api-version=$global:searchServiceAPiVersion"

        Invoke-RestMethod -Uri $searchIndexerUrl -Method Post -Headers @{ "api-key" = $searchServiceApiKey }

        Write-Host "Search Indexer '$searchIndexerName' ran successfully."
        Write-Log -message "Search Indexer '$searchIndexerName' ran successfully."
    }
    catch {
        Write-Error "Failed to run Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
        Write-Log -message "Failed to run Search Indexer '$searchIndexerName': (Line $($_.InvocationInfo.ScriptLineNumber)) : $_"
    }
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
            $endpoint = "https://$storageAccountName.blob.core.windows.net/$containerName"
            #$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

            <#
 # {            $storageAccountKey = az storage account keys list `
                --resource-group $resourceGroupName `
                --account-name $storageAccountName `
                --query "[0].value" `
                --output tsv:Enter a comment or description}
#>

            $content = @"
name: $serviceName
type: azure_blob
url: $endpoint
container_name: $containerName
account_name: $storageAccountName
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
        [string]$storageAccountName
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
        [string]$location,
        [string]$subscriptionId,
        [string]$storageAccountName,
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
storage_account: $storageAccountName
container_registry: $containerRegistryName
key_vault: $keyVaultName
application_insights: $appInsightsName
#workspace_hub: $aiHubName
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

# Function to update search index files (not currently used)
function Update-SearchIndexFiles {

    $resourceBaseName = $global:resourceBaseName

    $searchIndexFiles = @("search-index-schema-template.json,search-indexer-schema-template.json,vector-search-index-schema-template.json,vector-search-indexer-schema-template.json" )

    foreach ($fileName in $searchIndexFiles) {
        $searchIndexFilePath = $fileName -replace "-template", ""

        $content = Get-Content -Path $fileName

        $updatedContent = $content -replace $previousResourceBaseName, $resourceBaseName

        Set-Content -Path $searchIndexFilePath -Value $updatedContent
    }
}

# Function to update search skill set files
function Update-SearchSkillSetFiles {
    $resourceBaseName = $global:resourceBaseName

    $searchSkillSetFiles = $global:searchSkillSets

    foreach ($searchSkillSetFile in $searchSkillSetFiles) {

        $content = Get-Content -Path $searchSkillSetFile

        $updatedContent = $content -replace $previousResourceBaseName, $resourceBaseName

        Set-Content -Path $searchSkillSetFile -Value $updatedContent
    }
}

# Function to update the config file
function Update-ConfigFile {
    param (
        [string]$configFilePath,
        [string]$resourceBaseName,
        [string]$resourceGroupName,
        [string]$storageAccountName,
        [string]$searchServiceName,
        [string]$searchIndexName,
        [string]$searchIndexerName,
        [string]$searchVectorIndexName,
        [string]$searchVectorIndexerName,
        [string]$openAIAccountName,
        [string]$aiServiceName,
        [string]$functionAppName,
        [string]$siteLogo
    )

    try {
        $storageKey = az storage account keys list --resource-group  $global:resourceGroupName --account-name $global:storageAccountName --query "[0].value" --output tsv
        $startDate = (Get-Date).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $expirationDate = (Get-Date).AddYears(1).Date.AddDays(-1).AddSeconds(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $searchApiKey = az search admin-key show --resource-group $global:resourceGroupName --service-name $global:searchServiceName --query "primaryKey" --output tsv
        $openAIApiKey = az cognitiveservices account keys list --resource-group  $global:resourceGroupName --name $global:openAIAccountName --query "key1" --output tsv
        $aiServiceKey = az cognitiveservices account keys list --resource-group  $global:resourceGroupName --name $aiServiceName --query "key1" --output tsv
        $functionAppKey = az functionapp keys list --resource-group  $global:resourceGroupName --name $functionAppName --query "functionKeys.default" --output tsv
        $functionAppUrl = az functionapp show -g  $global:resourceGroupName -n $functionAppName --query "defaultHostName" --output tsv
        
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

        $storageUrl = "https://$storageAccountName.blob.core.windows.net/content?comp=list&include=metadata&restype=container&$storageSAS"

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
        $config.AZURE_AI_SERVICE_API_KEY = $aiServiceKey
        $config.AZURE_FUNCTION_API_KEY = $functionAppKey
        $config.AZURE_FUNCTION_APP_NAME = $functionAppName
        $config.AZURE_FUNCTION_APP_URL = "https://$functionAppUrl"
        $config.AZURE_KEY_VAULT_NAME = $global:keyVaultName
        $config.AZURE_RESOURCE_BASE_NAME = $global:resourceBaseName
        $config.AZURE_SEARCH_API_KEY = $searchApiKey
        $config.AZURE_SEARCH_API_VERSION = $global:searchServiceApiVersion
        $config.AZURE_SEARCH_INDEX_NAME = $searchIndexName
        $config.AZURE_SEARCH_INDEXER_NAME = $searchIndexerName
        $config.AZURE_SEARCH_SEMANTIC_CONFIG = "vector-profile-srch-index-" + $resourceBaseName + "-semantic-configuration" -join ""
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

        # Loop through the search indexes collection from global:searchIndexes
        foreach ($searchIndex in $global:searchIndexes) {
            $config.SEARCH_INDEXES += $searchIndex
        }

        # Clear existing values in SEARCH_INDEXERS
        $config.SEARCH_INDEXERS = @()

        # Loop through the search indexes collection from global:searchIndexes
        foreach ($searchIndexer in $global:searchIndexers) {
            $config.SEARCH_INDEXERS += $searchIndexer
        }

        # Clear existing values in AI_MODELS
        $config.AI_MODELS = @()

        #$aiServiceApiVersion = Get-LatestApiVersion -resourceProviderNamespace "Microsoft.CognitiveServices" -resourceType "accounts"
        $apiKey = Get-CognitiveServicesApiKey -resourceGroupName $resourceGroupName -cognitiveServiceName $global:aiServiceName

        # Loop through the AI models collection from global:aiModels
        foreach ($aiModel in $global:aiModels) {
            $aiModelName = $aiModel.Name
            $aiModelType = $aiModel.Type
            $aiModelVersion = $aiModel.Version
            $aiModelApiVersion = $aiModel.ApiVersion
            $aiModelFormat = $aiModel.Format
            $aiModelSkuName = $aiModel.Sku.Name
            $aiModelSkuCapacity = $aiModel.Sku.Capacity

            $config.AI_MODELS += @{
                "Name"         = $aiModelName
                "Type"         = $aiModelType
                "ModelVersion" = $aiModelVersion
                "ApiKey"       = $apiKey
                "ApiVersion"   = $aiModelApiVersion
                "Format"       = $aiModelFormat
                "Sku"          = @{
                    "Name"     = $aiModelSkuName
                    "Capacity" = $aiModelSkuCapacity
                }
            }
        }

        #$config.OPEN_AI_KEY = az cognitiveservices account keys list --resource-group $resourceGroupName --name $openAIName --query "key1" --output tsv
    
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

# Initialize the deployment path
$global:deploymentPath = Reset-DeploymentPath

$global:LogFilePath = "$global:deploymentPath/deployment.log"
$global:ConfigFilePath = "$global:deploymentPath/app/frontend/config.json"

Set-Location -Path $global:deploymentPath

# Initialize the existing resources array
$global:existingResources = @()

$global:resourceCounter = 0

# Initialize parameters
$initParams = Initialize-Parameters -parametersFile $parametersFile
#Write-Host "Parameters initialized."
#Write-Log -message "Parameters initialized."

# Alphabetize the parameters object
$parameters = Get-Parameters-Sorted -Parameters $initParams.parameters

# Set the user-assigned identity name
$global:userPrincipalName = $parameters.userPrincipalName

Set-DirectoryPath -targetDirectory $global:deploymentPath

# Start the deployment
Start-Deployment

#**********************************************************************************************************************
# End of script
