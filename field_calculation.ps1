# Variables
$organization = "YourOrganization"
$project = "YourProjectName"
$personalAccessToken = "YourPersonalAccessToken"
$filterCriteria = "System.State eq 'New' and System.WorkItemType eq 'Task'"
$customFieldToUpdate = "YourCustomFieldToUpdate"

# Construct the URL for querying work items
$url = "https://dev.azure.com/$organization/$project/_apis/wit/workitems?api-version=6.0&`$filter=$filterCriteria"

# Create headers with Personal Access Token
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)"))
    ContentType = "application/json"
}

# Send GET request to Azure DevOps API to retrieve work items
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

# Process each work item
foreach ($workItem in $response.value) {
    # Get create date from work item (replace with actual field name)
    $createDate = Get-Date $workItem.fields."System.CreatedDate" -Format "yyyy-MM-dd"
    
    # Get current date
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    # Calculate date difference
    $daysDifference = (New-TimeSpan -Start $createDate -End $currentDate).Days

    # Update custom field with calculated value
    $workItemToUpdate = @{
        id = $workItem.id
        fields = @{
            "YourCustomFieldToUpdate" = $daysDifference
        }
    }

    # Construct URL for updating work item
    $updateUrl = "https://dev.azure.com/$organization/$project/_apis/wit/workitems/$($workItem.id)?api-version=6.0"

    # Send PATCH request to update work item
    $response = Invoke-RestMethod -Uri $updateUrl -Headers $headers -Method Patch -Body (ConvertTo-Json -InputObject $workItemToUpdate)
}
