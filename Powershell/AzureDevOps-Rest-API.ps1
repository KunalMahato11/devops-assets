param (
    [Parameter(Mandatory = $true)]
    [System.String]
    $OrgName,

    [Parameter(Mandatory = $true)]
    [System.String]
    $ProjectName
)

function Retry-Command
{
    param (
    [Parameter(Mandatory=$true)][string]$command, 
    [Parameter(Mandatory=$true)][hashtable]$args, 
    [Parameter(Mandatory=$false)][int]$retries = 5, 
    [Parameter(Mandatory=$false)][int]$secondsDelay = 2
    )
    
    # Setting ErrorAction to Stop is important. This ensures any errors that occur in the command are 
    # treated as terminating errors, and will be caught by the catch block.
    $args.ErrorAction = "Stop"
    
    $retrycount = 0
    $completed = $false

    while (-not $completed) {
        try {
            & $command @args
            Write-Verbose ("Command [{0}] succeeded." -f $command)
            $completed = $true
        } catch {
            if ($retrycount -ge $retries) {
                Write-Verbose ("Command [{0}] failed the maximum number of {1} times." -f $command, $retrycount)
                throw
            } else {
                Write-Verbose ("Command [{0}] failed. Retrying in {1} seconds." -f $command, $secondsDelay)
                Start-Sleep $secondsDelay
                $retrycount++
            }
        }
    }
}


Write-Host "##[section]Parameters:";
Write-Host "##[section]Organization Name: $OrgName";
Write-Host "##[section]Project Name: $ProjectName";


# Local Testing
$PersonalAccessToken = "<PAT>";
$PersonalAccessToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"));
$Headers = @{ authorization = "Basic $PersonalAccessToken"}

# Using Pipeline
$PersonalAccessToken = $env:SYSTEM_ACCESSTOKEN
$Headers = @{ authorization = "Bearer $PersonalAccessToken"}

$API_URL = "https://dev.azure.com/$OrgName/$ProjectName/<api-path>";


$GetCallArgs = @{
    Uri = $API_URL
    Method = "Get"
    Headers = $Headers
    ContentType = "application/json"
}

# API Call with retry
$Response = Retry-Command -Command "Invoke-RestMethod" -args $GetCallArgs

# API Call without retry
$Response = Invoke-RestMethod -Uri $API_URL -Method Get -Headers $Headers -ContentType "application/json"