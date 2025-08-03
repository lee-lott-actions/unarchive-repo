# Unarchive Repository Action

This GitHub Action unarchives a specified GitHub repository using the GitHub API. It returns the result of the unarchive attempt, indicating success or failure, along with an error message if the operation fails.

## Features
- Unarchives a GitHub repository by making a PATCH request to the GitHub API.
- Verifies the repository's unarchived status in the API response.
- Outputs the result of the unarchive attempt (`success` or `failure`) and an error message if applicable.
- Requires a GitHub token with repository write access for authentication.

## Inputs
| Name        | Description                                              | Required | Default |
|-------------|----------------------------------------------------------|----------|---------|
| `repo-name` | The name of the repository to unarchive.                | Yes      | N/A     |
| `token`     | GitHub token with repository write access.              | Yes      | N/A     |
| `owner`     | The owner of the repository (user or organization).     | Yes      | N/A     |

## Outputs
| Name           | Description                                             |
|----------------|---------------------------------------------------------|
| `result`       | Result of the unarchive attempt ("success" or "failure"). |
| `error-message`| Error message if the unarchive attempt fails.           |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/unarchive-repo.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: Unarchive Repository
   on:
     workflow_dispatch:
       inputs:
         repo-name:
           description: 'Name of the repository to unarchive'
           required: true
   jobs:
     unarchive-repo:
       runs-on: ubuntu-latest
       steps:
         - name: Unarchive Repository
           id: unarchive
           uses: lee-lott-actions/unarchive-repo@v1.0.0
           with:
             repo-name: ${{ github.event.inputs.repo-name }}
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
         - name: Print Result
           run: |
             if [[ "${{ steps.unarchive.outputs.result }}" == "success" ]]; then
               echo "Repository ${{ github.repository_owner }}/${{ github.event.inputs.repo-name }} successfully unarchived."
             else
               echo "Error: ${{ steps.unarchive.outputs.error-message }}"
               exit 1
             fi
