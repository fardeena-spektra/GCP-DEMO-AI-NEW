<#
 CloudLabs validation | LAB01A-EX3-TASK2
 Verify Grounded Responses from the Deployed Agent
 Lab: Day 1 - Jingle Awakens (Developer)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - Jingle's log shows at least 3 grounded lookups in the last 60 minutes
     (north-pole-data.json, version 2026-12, matches > 0)
#>
param(
    [string]$DeploymentId,
    [string]$projectname
)

$vmName  = "jingle-workshop"
$jingleSa = "jingle-sa@$projectname.iam.gserviceaccount.com"
$dataFile = "north-pole-data.json"
$dataVer  = "2026-12"
$zone    = ""
$message = $null

function New-Result([string]$Status, [string]$Message) {
    @{ Status = $Status; Message = $Message } | ConvertTo-Json
}

# Santa's Knowledge Vault bucket (santas-knowledge-vault-<deploymentId>)
function Get-Vault {
    $b = @(gcloud storage buckets list --project $projectname --format="value(name)" --filter="name~^santas-knowledge-vault-" 2>$null) | Where-Object { $_ }
    if ($DeploymentId -and ($b -contains "santas-knowledge-vault-$DeploymentId")) { return "santas-knowledge-vault-$DeploymentId" }
    return ($b | Select-Object -First 1)
}

# Jingle's workshop VM as JSON (any zone), or $null. Sets $script:zone.
function Get-Workshop {
    $json = gcloud compute instances list --project $projectname --filter="name=$vmName" --format="json" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { return $null }
    $list = @($json | Out-String | ConvertFrom-Json)
    if ($list.Count -eq 0 -or -not $list[0]) { return $null }
    $script:zone = ($list[0].zone -split "/")[-1]
    Write-Host "Found $vmName in zone $script:zone (status $($list[0].status))"
    return $list[0]
}

# Jingle's log lines in Cloud Logging (log name "jingle"). No quotes in the filter on purpose.
function Get-JingleLogs([string]$Message, [int]$Minutes = 60) {
    $filter = "logName:jingle AND jsonPayload.message=$Message"
    $json = gcloud logging read $filter --project $projectname --freshness "$($Minutes)m" --limit 50 --order desc --format json 2>$null | Out-String
    Write-Host "Log query: $filter (last $Minutes min)"
    if (-not $json.Trim()) { return @() }
    return @($json | ConvertFrom-Json)
}


try {
    if (-not $projectname) { throw "The projectname parameter is empty. Map it to GET-GCP-PROJECT." }
    Write-Host "Project: $projectname | DeploymentId: $DeploymentId"
    gcloud config set project $projectname --quiet 2>$null | Out-Null

    $vm = Get-Workshop
    if (-not $vm) {
        $message = New-Result "Failed" "Jingle's workshop VM '$vmName' was not found. Complete the Santa's Vault challenge first."
    }
    else {
        $lookups = @(Get-JingleLogs -Message "KB_LOOKUP" -Minutes 60)
        $good = @($lookups | Where-Object { $_.jsonPayload.file -eq $dataFile -and $_.jsonPayload.kb_version -eq $dataVer -and [int]$_.jsonPayload.matches -gt 0 })
        Write-Host "KB_LOOKUP: $($lookups.Count) | grounded lookups: $($good.Count)"
        if ($lookups.Count -eq 0) {
            $message = New-Result "Failed" "No answers from Jingle's deployed workshop in the last 60 minutes. Ask Jingle the customer questions through the sleigh gate, wait 1 minute, then validate again."
        }
        elseif ($good.Count -lt 3) {
            $message = New-Result "Failed" "Jingle answered from the vault only $($good.Count) time(s). Ask all four customer questions, wait 1 minute, then validate again."
        }
        else {
            $message = New-Result "Succeeded" "Jingle answered $($good.Count) customer questions from Santa's Knowledge Vault (version $dataVer). Elf Developer badge earned!"
        }
    }
}
catch {
    Write-Host "`nERROR:"
    Write-Host $_
    $message = New-Result "Failed" "The elves could not finish the check. Please wait a minute and validate again. Details: $_"
}

Write-Host "`n=== FINAL RESPONSE ==="
Write-Host $message

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body       = $message
})
