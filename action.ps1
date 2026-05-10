function Set-RepositoryArchiveStatus {
	param(
		[string]$RepoName,
		[string]$Token,
		[string]$Owner
	)

	# Validate required inputs
	if ([string]::IsNullOrEmpty($RepoName) -or
		[string]::IsNullOrEmpty($Token) -or
		[string]::IsNullOrEmpty($Owner)) {

		Write-Host "Error: Missing required parameters"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: repo-name, token, and owner must be provided."
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		return
	}

	Write-Host "Attempting to unarchive repository $Owner/$RepoName"

	# Use MOCK_API if set, otherwise default to GitHub API
	$apiBaseUrl = $env:MOCK_API
	if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }

	$uri = "$apiBaseUrl/repos/$Owner/$RepoName"

	$headers = @{
		Authorization = "Bearer $Token"
		Accept = "application/vnd.github+json"
		"X-GitHub-Api-Version" = "2026-03-10"
		"Content-Type" = "application/json"
	}

	$body = @{ archived = $false } | ConvertTo-Json -Compress

	try {
		$response = Invoke-WebRequest -Uri $uri -Method Patch -Headers $headers -Body $body

		if($response.StatusCode -ne 200) {
			$errorMsg = "Error: Failed to unarchive repository $Owner/$RepoName. HTTP Status: $($response.StatusCode)."
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Write-Host $errorMsg	
			return
		}
		
		$isArchived = $null
		try {
			if (-not [string]::IsNullOrEmpty($response.Content)) {
				$json = $response.Content | ConvertFrom-Json
				$isArchived = $json.archived
			}
		} catch {
			$isArchived = $null
		}

		$isUnarchived = ($isArchived -eq $false -or "$isArchived" -eq "false")
			
		if(-not $isUnarchived) {
			$errorMsg = "Error: Failed to unarchive repository $Owner/$RepoName. HTTP Status: $($response.StatusCode). IsUnarchived Status: $isUnarchived."
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Write-Host $errorMsg
			return
		}
				
		Write-Host "Repository $Owner/$RepoName successfully unarchived"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
	} catch {
		$errorMsg = "Error: Failed to unarchive repository $Owner/$RepoName. Exception: $($_.Exception.Message)"		
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
	}	
}
