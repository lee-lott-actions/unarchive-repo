BeforeAll {
	$script:RepoName = "test-repo"
	$script:Owner = "test-owner"
	$script:Token = "fake-token"

	. "$PSScriptRoot/../action.ps1"
}

Describe "Set-RepositoryArchiveStatus" {
	BeforeEach {
		$env:GITHUB_OUTPUT = [System.IO.Path]::GetTempFileName()
	}

	AfterEach {
		if (Test-Path $env:GITHUB_OUTPUT) {
			# Optional: show output like the bats teardown did
			# Get-Content $env:GITHUB_OUTPUT | Out-Host
			Remove-Item $env:GITHUB_OUTPUT -Force
		}
	}

	It "succeeds with HTTP 200 and archived false" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"archived": false}'
			}
		}

		Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=success"
	}

	It "fails with HTTP 404" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 404
				Content    = '{"message": "Repository not found"}'
			}
		}

		Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to unarchive repository $Owner/$RepoName\. HTTP Status:" } |
			Should -Not -BeNullOrEmpty
	}

	It "fails when archived is true" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"archived": true}'
			}
		}

		Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to unarchive repository $Owner/$RepoName\. HTTP Status:" } |
			Should -Not -BeNullOrEmpty
	}

	It "fails with empty repo_name" {
		Set-RepositoryArchiveStatus -RepoName "" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
	}

	It "fails with empty token" {
		Set-RepositoryArchiveStatus -RepoName $RepoName -Token "" -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
	}

	It "fails with empty owner" {
		Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner ""

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
	}

	It "writes result=failure and error-message on exception (catch block)" {
		Mock Invoke-WebRequest { throw "API Error" }

		Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to unarchive repository $Owner/$RepoName\. Exception:" } |
			Should -Not -BeNullOrEmpty
	}
}