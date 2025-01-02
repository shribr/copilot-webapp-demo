# Define the path to the CSS file
$global:cssFilePath1 = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles.css"
$global:cssFilePath2 = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles_alphabetized.css"
$global:jsFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/scripts/script.js"
$global:htmlFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/index.html"
$global:ConfigFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontendconfig.json"
# List of unused CSS definitions
$unusedCssDefinitions = @(
    ".site-logo-custom",
    ".iconify",
    ".iconify-color",
    ".file-size",
    ".chat-response.user",
    ".chat-response.bot",
    ".chat-response",
    ".tab-content",
    ".tab-content.active",
    ".tab",
    ".tab.active",
    ".tab svg",
    ".tab svg #icon-document-tab",
    ".tab.active svg",
    ".tab.active svg #icon-document-tab",
    ".download-chat-results-button",
    ".download-chat-results-container",
    ".action-container",
    ".action-edit",
    ".action-delete",
    ".edit-icon",
    ".bi",
    ".svg-icon",
    ".mud-icon-root",
    ".mud-icon-root.mud-svg-icon",
    ".mud-icon-size-small",
    ".mud-icon-size-medium",
    ".mud-icon-size-large",
    ".mud-icon-default",
    ".mud-disabled .mud-icon-root",
    ".mud-disabled .mud-svg-icon",
    ".mud-disabled .mud-icon-default"
)
#####################################################################################################################

function Find-Mud-Css-Definitions-In-File() {
    param (
        [string]$filePath = $global:jsFilePath
    )

    # Read the content of the file
    $fileContent = Get-Content -Path $filePath -Raw

    # Create a regex pattern to match MudBlazor CSS definitions
    $pattern = "mud-[^}]*\{[^}]*\}"
    $matchesFound = [regex]::Matches($fileContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Output the matches
    $matchesFound | ForEach-Object { Write-Output "$_.Value`n" }
}

#Find-Mud-Css-Definitions-In-File

function Remove-Mud-Css-Definitions() {
    param (
        [string]$cssFilePath
    )

    # Read the content of the CSS file
    $cssContent = Get-Content -Path $cssFilePath -Raw

    # Create a regex pattern to match MudBlazor CSS definitions
    $pattern = "\.mud-[^}]*\{[^}]*\}"
    $cssContent = [regex]::Replace($cssContent, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Write the updated content back to the CSS file
    Set-Content -Path $cssFilePath -Value $cssContent

    Write-Output "MudBlazor CSS definitions have been removed."
}

#####################################################################################################################

function Sort-Css-Definitions() {
    param (
        [string]$cssFilePath = $global:cssFilePath2
    )

    # Read the content of the CSS file
    $cssContent = Get-Content -Path $cssFilePath -Raw

    # Extract the CSS definitions and sort them alphabetically
    $cssDefinitions = [regex]::Matches($cssContent, '\.[^{]+{[^}]*}', 'Multiline') | ForEach-Object { $_.Value.Trim() }
    $sortedCssDefinitions = $cssDefinitions | Sort-Object

    # Replace the original CSS definitions with the sorted ones
    $sortedCssContent = $sortedCssDefinitions -join "`n"

    # Write the updated content back to the CSS file
    Set-Content -Path $cssFilePath -Value $sortedCssContent

    Write-Output "CSS definitions have been sorted alphabetically."
}

function Sort-Css-Definitions-With-Line-Breaks() {
    param (
        [string]$cssFilePath = $global:cssFilePath2
    )

    $cssContent = Get-Content -Path $cssFilePath
    $sortedCss = $cssContent -split '}' | ForEach-Object {
        $_.Trim() + "`n`n}"
    }

    $sortedCss | Set-Content -Path $cssFilePath
}

#######################################################################################################################

function Diff-Css-Files() {

    # Read the content of the CSS files
    $cssContent1 = Get-Content -Path $cssFilePath1 -Raw
    $cssContent2 = Get-Content -Path $cssFilePath2 -Raw

    # Compare the content of the CSS files
    $diff = Compare-Object -ReferenceObject $cssContent1 -DifferenceObject $cssContent2

    # Output the differences
    $diff | ForEach-Object {
        Write-Output "Difference: $($_.InputObject)"
    }
}

function Find-Missing-Css-Definitions() {
    # Define the paths to the CSS files
    $originalCssFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles.css"
    $alphabetizedCssFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles_alphabetized.css"

    # Read the content of the CSS files
    $originalCssContent = Get-Content -Path $originalCssFilePath -Raw
    $alphabetizedCssContent = Get-Content -Path $alphabetizedCssFilePath -Raw

    # Extract the CSS selectors from the content with line numbers
    $originalCssSelectors = [regex]::Matches($originalCssContent, '^[^{}]+(?=\s*\{)', 'Multiline') | ForEach-Object { 
        [PSCustomObject]@{ Selector = $_.Value.Trim(); LineNumber = ($originalCssContent.Substring(0, $_.Index) -split "`n").Count }
    }
    $alphabetizedCssSelectors = [regex]::Matches($alphabetizedCssContent, '^[^{}]+(?=\s*\{)', 'Multiline') | ForEach-Object { 
        $_.Value.Trim() 
    }

    # Find the selectors that exist in the original CSS but not in the alphabetized CSS
    $missingSelectors = $originalCssSelectors | Where-Object { $_.Selector -notin $alphabetizedCssSelectors }

    # Output the missing selectors with line numbers
    $missingSelectors | ForEach-Object { Write-Output "Selector: $($_.Selector), Line Number: $($_.LineNumber)" }

    $totalMissingSelectors = $missingSelectors.Count

    Write-Output "Total missing selectors: $totalMissingSelectors"
}

function Find-Missing-Css-Definitions-With-Blocks() {
    # Define the paths to the CSS files
    $originalCssFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles.css"
    $alphabetizedCssFilePath = "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/app/frontend/css/styles_alphabetized.css"

    # Read the content of the CSS files
    $originalCssContent = Get-Content -Path $originalCssFilePath -Raw
    $alphabetizedCssContent = Get-Content -Path $alphabetizedCssFilePath -Raw

    # Extract the CSS blocks from the content
    $originalCssBlocks = [regex]::Matches($originalCssContent, '([^{}]+\{[^}]+\})', 'Multiline') | ForEach-Object { 
        [PSCustomObject]@{ Block = $_.Value.Trim(); LineNumber = ($originalCssContent.Substring(0, $_.Index) -split "`n").Count }
    }
    $alphabetizedCssBlocks = [regex]::Matches($alphabetizedCssContent, '([^{}]+\{[^}]+\})', 'Multiline') | ForEach-Object { 
        $_.Value.Trim() 
    }

    # Find the blocks that exist in the original CSS but not in the alphabetized CSS
    $missingBlocks = $originalCssBlocks | Where-Object { $_.Block -notin $alphabetizedCssBlocks }

    # Output the missing blocks with line numbers
    $missingBlocks | ForEach-Object { Write-Output "$($_.Block)" }

    $totalMissingBlocks = $missingBlocks.Count

    Write-Output "Total missing blocks: $totalMissingBlocks"
}

function Find-Css-Definitions-With-Underscore {
    param (
        [string]$filePath
    )

    if (-Not (Test-Path $filePath)) {
        Write-Error "File not found: $filePath"
        return
    }

    $cssContent = Get-Content $filePath
    $definitionsWithUnderscore = @()

    foreach ($line in $cssContent) {
        if ($line -match '[_]') {
            $definitionsWithUnderscore += $line
        }
    }

    return $definitionsWithUnderscore
}

function Replace-Underscores-In-File() {
    param (
        [string]$filePathToProcess = $global:cssFilePath1
    )

    if (-Not (Test-Path $filePathToProcess)) {
        Write-Error "File not found: $filePathToProcess"
        return
    }

    $results = Find-Css-Definitions-With-Underscore -filePath $filePathToProcess

    if ($results.Count -eq 0) {
        Write-Output "No definitions containing an underscore were found."
    }
    else {
        Write-Output "Definitions containing an underscore:"
        $results | ForEach-Object { Write-Output $_ }
    }

    # Read the content of the file
    $fileContent = Get-Content -Path $filePathToProcess -Raw

    # Iterate over each item in the $results collection
    foreach ($item in $results) {
        # Replace underscores with hyphens
        $fileContent = $fileContent -replace $item, ($item -replace '_', '-')
    }

    # Write the updated content back to the file
    Set-Content -Path $filePathToProcess -Value $fileContent

}

function Find-Duplicate-Css-Definitions() {
    param (
        [string]$cssFilePath = $global:cssFilePath1
    )

    if (-Not (Test-Path $cssFilePath)) {
        Write-Error "File not found: $cssFilePath"
        return
    }

    # Read the content of the CSS file
    $cssContent = Get-Content -Path $cssFilePath -Raw

    # Extract the CSS selectors from the content
    $cssSelectors = [regex]::Matches($cssContent, '^[^{}]+(?=\s*\{)', 'Multiline') | ForEach-Object { 
        $_.Value.Trim() 
    }

    # Find duplicate selectors
    $duplicateSelectors = $cssSelectors | Group-Object | Where-Object { $_.Count -gt 1 }

    if ($duplicateSelectors.Count -eq 0) {
        Write-Output "No duplicate CSS definitions found."
    }
    else {
        Write-Output "Duplicate CSS definitions found:"
        $duplicateSelectors | ForEach-Object { 
            Write-Output "Selector: $($_.Name), Count: $($_.Count)"
        }
    }
}

function Remove-Duplicate-Css-Definitions() {
    param (
        [string]$cssFilePath = $global:cssFilePath1
    )

    if (-Not (Test-Path $cssFilePath)) {
        Write-Error "File not found: $cssFilePath"
        return
    }

    # Read the content of the CSS file
    $cssContent = Get-Content -Path $cssFilePath -Raw

    # Extract the CSS blocks from the content
    $cssBlocks = [regex]::Matches($cssContent, '([^{}]+\{[^}]+\})', 'Multiline') | ForEach-Object { 
        [PSCustomObject]@{ Block = $_.Value.Trim(); Selector = ($_.Value.Trim() -split '\{')[0].Trim() }
    }

    # Find unique selectors and keep the first occurrence, ignoring those that start with "@"
    $uniqueSelectors = @{}
    $uniqueCssBlocks = @()

    foreach ($block in $cssBlocks) {
        if ($block.Selector -notmatch '^@' -and -not $uniqueSelectors.ContainsKey($block.Selector)) {
            $uniqueSelectors[$block.Selector] = $true
            $uniqueCssBlocks += $block.Block
        }
    }

    # Write the unique CSS blocks back to the file
    $uniqueCssContent = $uniqueCssBlocks -join "`n`n"
    Set-Content -Path $cssFilePath -Value $uniqueCssContent

    Write-Output "Duplicate CSS definitions removed."
}

function Add-Missing-Fields {
    param (
        [PSCustomObject]$source,
        [ref]$target
    )

    foreach ($property in $source.PSObject.Properties) {
        Write-Output "Processing property: $($property.Name)"
        if (-not $target.Value.PSObject.Properties.Match($property.Name)) {
            if ($property.Value -is [PSCustomObject]) {
                $target.Value | Add-Member -MemberType NoteProperty -Name $property.Name -Value ([PSCustomObject]@{})
            }
            elseif ($property.Value -is [System.Collections.IEnumerable] -and -not ($property.Value -is [string])) {
                $target.Value | Add-Member -MemberType NoteProperty -Name $property.Name -Value @()
            }
            else {
                $target.Value | Add-Member -MemberType NoteProperty -Name $property.Name -Value $null
            }
        }

        if ($property.Value -is [PSCustomObject]) {
            if (-not $target.Value.$($property.Name)) {
                $target.Value.$($property.Name) = [PSCustomObject]@{}
            }
            Add-Missing-Fields $property.Value ([ref]$target.Value.$($property.Name))
        }
        elseif ($property.Value -is [System.Collections.IEnumerable] -and -not ($property.Value -is [string])) {
            if (-not $target.Value.$($property.Name)) {
                $target.Value.$($property.Name) = @()
            }
            for ($i = 0; $i -lt $property.Value.Count; $i++) {
                if ($property.Value[$i] -is [PSCustomObject]) {
                    if ($i -ge $target.Value.$($property.Name).Count) {
                        $target.Value.$($property.Name) += [PSCustomObject]@{}
                    }
                    Add-Missing-Fields $property.Value[$i] ([ref]$target.Value.$($property.Name)[$i])
                }
                else {
                    if ($i -ge $target.Value.$($property.Name).Count) {
                        $target.Value.$($property.Name) += $property.Value[$i]
                    }
                }
            }
        }
        else {
            $target.Value.$($property.Name) = $property.Value
        }
    }
}

function Update-Json-Fields {
    param (
        [string]$sourceJsonFilePath,
        [string]$targetJsonFilePath
    )

    if (-Not (Test-Path $sourceJsonFilePath)) {
        Write-Error "Source file not found: $sourceJsonFilePath"
        return
    }

    if (-Not (Test-Path $targetJsonFilePath)) {
        Write-Error "Target file not found: $targetJsonFilePath"
        return
    }

    # Read the content of the JSON files
    $sourceJsonContent = Get-Content -Path $sourceJsonFilePath -Raw | ConvertFrom-Json
    $targetJsonContent = Get-Content -Path $targetJsonFilePath -Raw | ConvertFrom-Json

    Add-Missing-Fields $sourceJsonContent ([ref]$targetJsonContent)

    # Convert the updated target JSON content back to JSON format
    $updatedTargetJsonContent = $targetJsonContent | ConvertTo-Json -Depth 10

    # Write the updated JSON content back to the target file
    Set-Content -Path $targetJsonFilePath -Value $updatedTargetJsonContent

    Write-Output "Target JSON file updated with missing fields from source JSON file."
}

function Get-SelectorsFromCss {
    param (
        [string]$cssFilePath
    )

    if (-Not (Test-Path $cssFilePath)) {
        Write-Error "CSS file not found: $cssFilePath"
        return @()
    }

    $cssContent = Get-Content -Path $cssFilePath -Raw
    $regex = [regex]::Matches($cssContent, '(?<!#)\.([a-zA-Z_-][a-zA-Z0-9_-]*)\s*\{|(?<!#)\#([a-zA-Z_-][a-zA-Z0-9_-]*)\s*\{')
    $selectors = $regex | ForEach-Object {
        if ($_.Groups[1].Value) {
            $_.Groups[1].Value
        }
        elseif ($_.Groups[2].Value) {
            $_.Groups[2].Value
        }
    }

    return $selectors
}

function Get-SelectorsFromHtmlJsJson {
    param (
        [string[]]$filePaths,
        [string]$jsonFilePath
    )

    $selectors = @()

    foreach ($filePath in $filePaths) {
        if (-Not (Test-Path $filePath)) {
            Write-Error "File not found: $filePath"
            continue
        }

        $content = Get-Content -Path $filePath -Raw
        $regex = [regex]::Matches($content, '\b([a-zA-Z_-][a-zA-Z0-9_-]*)\b')
        $selectors += $regex | ForEach-Object {
            $_.Groups[1].Value
        }
    }

    if (Test-Path $jsonFilePath) {
        $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
        $jsonSelectors = $jsonContent | ConvertTo-Json -Depth 10 | Select-String -Pattern '\b([a-zA-Z_-][a-zA-Z0-9_-]*)\b'
        $jsonSelectors.Matches | ForEach-Object {
            $selectors += $_.Groups[1].Value
        }
    }

    return $selectors
}

function Verify-Selectors {
    param (
        [string[]]$selectors,
        [string[]]$htmlJsFilePaths,
        [string]$jsonFilePath
    )

    $usedSelectors = Get-SelectorsFromHtmlJsJson -filePaths $htmlJsFilePaths -jsonFilePath $jsonFilePath
    $verifiedUnusedSelectors = $selectors | Where-Object { $_ -notin $usedSelectors }

    return $verifiedUnusedSelectors
}

function Find-UnusedCssDefinitions {
    param (
        [string]$cssFilePath,
        [string[]]$htmlJsFilePaths,
        [string]$jsonFilePath
    )

    $cssSelectors = Get-SelectorsFromCss -cssFilePath $cssFilePath
    $usedSelectors = Get-SelectorsFromHtmlJsJson -filePaths $htmlJsFilePaths -jsonFilePath $jsonFilePath

    $unusedSelectors = $cssSelectors | Where-Object { $_ -notin $usedSelectors }

    if ($unusedSelectors.Count -eq 0) {
        Write-Output "No unused CSS definitions found."
    }
    else {
        Write-Output "Initial unused CSS definitions found:"
        $unusedSelectors | ForEach-Object { Write-Output $_ }

        # Verify the unused selectors
        $verifiedUnusedSelectors = Verify-Selectors -selectors $unusedSelectors -htmlJsFilePaths $htmlJsFilePaths -jsonFilePath $jsonFilePath

        if ($verifiedUnusedSelectors.Count -eq 0) {
            Write-Output "No unused CSS definitions found after verification."
        }
        else {
            $classSelectors = $verifiedUnusedSelectors | Where-Object { $_ -notmatch '^#' } | Sort-Object
            $idSelectors = $verifiedUnusedSelectors | Where-Object { $_ -match '^#' } | Sort-Object

            Write-Output "Verified unused CSS definitions found:"
            Write-Output "Class Selectors (Total: $($classSelectors.Count)):"
            $classSelectors | ForEach-Object { Write-Output $_ }

            Write-Output "ID Selectors (Total: $($idSelectors.Count)):"
            $idSelectors | ForEach-Object { Write-Output $_ }

            # Call the Remove-Unused-Css-Definitions function
            Remove-Unused-Css-Definitions -cssFilePath $cssFilePath -unusedCssDefinitions $verifiedUnusedSelectors
        }
    }
}

function Remove-Unused-Css-Definitions {
    param (
        [string]$cssFilePath,
        [string[]]$unusedCssDefinitions
    )

    # Read the content of the CSS file
    $cssContent = Get-Content -Path $cssFilePath -Raw

    # Loop through each unused CSS definition and remove it from the content
    foreach ($definition in $unusedCssDefinitions) {
        # Create a regex pattern to match the CSS definition and its content
        $pattern = "(\.|#)" + [regex]::Escape($definition) + "\s*\{[^}]*\}"
        $cssContent = [regex]::Replace($cssContent, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    # Write the updated content back to the CSS file
    Set-Content -Path $cssFilePath -Value $cssContent

    Write-Output "Unused CSS definitions have been removed."
}

# Example usage
$cssFilePath = $global:cssFilePath1
$htmlJsFilePaths = @($global:jsFilePath, $global:htmlFilePath)
$jsonFilePath = $global:jsonFilePath
Find-UnusedCssDefinitions -cssFilePath $cssFilePath -htmlJsFilePaths $htmlJsFilePaths -jsonFilePath $jsonFilePath

#Update-Json-Fields -sourceJsonFilePath "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/parameters.json" -targetJsonFilePath "/Users/amischreiber/source/repos/copilot-webapp-demo/src/deployment/parameters.backup.json"