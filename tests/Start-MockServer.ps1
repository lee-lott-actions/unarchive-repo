param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        $path   = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $statusCode = 200
        $responseJson = $null

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PATCH /repos/:owner/:repo
        elseif ($method -eq "PATCH" -and $path -match '^/repos/([^/]+)/([^/]+)$') {
            $owner = $Matches[1]
            $repo  = $Matches[2]

            Write-Host ("Mock intercepted: PATCH /repos/{0}/{1}" -f $owner, $repo) -ForegroundColor Cyan
            Write-Host "Request headers: $($request.Headers | Out-String)"

            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()

            Write-Host "Request body: $requestBody"

            $bodyObj = $null
            try { $bodyObj = $requestBody | ConvertFrom-Json } catch { $bodyObj = $null }

            $archived = $null
            if ($null -ne $bodyObj) { $archived = $bodyObj.archived }

            # Validate request body: archived must be boolean
            # (In PowerShell booleans are [bool]; ConvertFrom-Json will produce a [bool] for true/false)
            if ($archived -isnot [bool]) {
                $statusCode = 422
                $responseJson = @{ message = "Invalid archived status" } | ConvertTo-Json -Compress
            }
            # Simulate repository existence check
            elseif ($owner -eq 'invalid-owner' -or $repo -eq 'invalid-repo') {
                $statusCode = 404
                $responseJson = @{ message = "Repository not found" } | ConvertTo-Json -Compress
            }
            else {
                # Simulate successful archive/unarchive
                $statusCode = 200
                $responseJson = @{ archived = $archived } | ConvertTo-Json -Compress
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json -Compress
        }

        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}