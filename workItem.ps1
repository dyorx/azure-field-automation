$organization = "ORG"
$project = "PROJECT"
$personalAccessToken = "TOKEN"

# Encode your personal access token
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)"))

# Define the API URL for querying work items
$apiUrl = "<https://dev.azure.com/$organization/$project/_apis/wit/wiql?api-version=6.0>"

# Define your WIQL query (This example lists all work items, you can customize it as per your need)
$query = @"
{
  "query": "SELECT [System.Id] FROM workitems"
}
"@

# Invoke the REST API to get the list of work items
$response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $query -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

# Function to fetch work items in batches
Function Get-WorkItemsInBatches {
    Param (
        [Parameter(Mandatory = $true)]
        [string[]]$Ids
    )

    $batchSize = 200
    $workItemsDetails = @()

    for ($i = 0; $i -lt $Ids.Count; $i += $batchSize) {
        $batchIds = $Ids[$i..([Math]::Min($i + $batchSize - 1, $Ids.Count - 1))]
        $idsQuery = $batchIds -join ","
        
        # Define the API URL for getting work items by IDs
        $workItemsUrl = "<https://dev.azure.com/$organization/$project/_apis/wit/workitems?ids=$idsQuery&expand=all&api-version=6.0>"
        
        # Get detailed information about work items
        $workItems = Invoke-RestMethod -Uri $workItemsUrl -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
        
        # Collect work item details
        $workItems.value | ForEach-Object {
            $createdDate = [datetime]$_.fields.'System.CreatedDate'
            $changedDate = [datetime]$_.fields.'System.ChangedDate'
            $currentDate = Get-Date
            $age = ($currentDate - $createdDate).Days

            $workItemsDetails += New-Object PSObject -Property @{
                ID          = $_.id
                Title       = $_.fields.'System.Title'
                State       = $_.fields.'System.State'
                CreatedDate = $createdDate
                ChangedDate = $changedDate
                AgeInDays   = $age
            }
        }
    }
    return $workItemsDetails
}

# Check if the response has work item references
if ($response.workItems) {
    # Get IDs of work items to fetch detailed information
    $ids = $response.workItems.id
    
    # Fetch work items in batches and collect details
    $workItemsDetails = Get-WorkItemsInBatches -Ids $ids
    
    # Print the work items in a table format
    $workItemsDetails | Format-Table -Property ID, Title, State, CreatedDate, ChangedDate, AgeInDays -AutoSize
}
else {
    Write-Output "No work items found."
}fiel
