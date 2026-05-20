Describe "Set-RepositoryArchiveStatus" {
	BeforeAll {
		$script:RepoName = "test-repo"
		$script:Owner = "test-owner"
		$script:Token = "fake-token"
		$script:MockApiUrl  = "http://127.0.0.1:3000"
		. "$PSScriptRoot/../action.ps1"
	}
	
	BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
		It "unit: Set-RepositoryArchiveStatus succeeds with HTTP 200 and archived false" {
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
	}

	Context "Failure Cases" {
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
	}

	Context "HTTP Failure Cases" {
		It "unit: Set-RepositoryArchiveStatus fails with HTTP 404" {
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
	}

	Context "Parameter Validation Failure Cases" {
		It "unit: Set-RepositoryArchiveStatus fails with empty RepoName" {
			Set-RepositoryArchiveStatus -RepoName "" -Token $Token -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
		}
	
		It "unit: Set-RepositoryArchiveStatus fails with empty Token" {
			Set-RepositoryArchiveStatus -RepoName $RepoName -Token "" -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
		}
	
		It "unit: Set-RepositoryArchiveStatus fails with empty Owner" {
			Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner ""
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo-name, token, and owner must be provided."
		}	
	}

	Context "Exception Failure Cases" {
		It "unit: Set-RepositoryArchiveStatus fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			Set-RepositoryArchiveStatus -RepoName $RepoName -Token $Token -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Where-Object { $_ -match "^error-message=Error: Failed to unarchive repository $Owner/$RepoName\. Exception:" } |
				Should -Not -BeNullOrEmpty
		}	
	}
}
