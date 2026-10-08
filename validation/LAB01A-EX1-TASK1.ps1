<#
 CloudLabs validation | LAB01A-EX1-TASK1
 Prepare the Lab Environment
 Lab: Day 1 - Jingle Awakens (Developer)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - services on, North Pole data loaded into Santa's Knowledge Vault,
     jingle-sa can read the vault, use Gemini and write logs (safe to run again)
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

    $repo = "https://raw.githubusercontent.com/fardeena-spektra/GCP-DEMO-AI-NEW/refs/heads/main/assets"
    $failed = @()

    Write-Host "[1/5] Turning on Service Usage, then the North Pole services"
    gcloud services enable serviceusage.googleapis.com --project $projectname --quiet 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) { $failed += "Service Usage API" }
    $apis = @("aiplatform.googleapis.com", "compute.googleapis.com", "iap.googleapis.com", "storage.googleapis.com",
              "logging.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com")
    gcloud services enable $apis --project $projectname --async --quiet 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) { $failed += "lab APIs" }

    Write-Host "[2/5] Santa's Knowledge Vault"
    $vault = Get-Vault
    if (-not $vault) {
        $message = New-Result "Failed" "Santa's Knowledge Vault (santas-knowledge-vault-*) was not found. The lab deployment may still be running."
    }
    else {
        Write-Host "      gs://$vault"
        Write-Host "[3/5] Loading the North Pole data"
        $local = Join-Path ([IO.Path]::GetTempPath()) $dataFile
        Invoke-WebRequest -UseBasicParsing -Uri "$repo/$dataFile" -OutFile $local
        gcloud storage cp $local "gs://$vault/$dataFile" --project $projectname --quiet 2>&1 | Write-Host
        if ($LASTEXITCODE -ne 0) { $failed += "upload $dataFile" }

        Write-Host "[4/5] Jingle may read this vault only"
        gcloud storage buckets add-iam-policy-binding "gs://$vault" --member "serviceAccount:$jingleSa" --role "roles/storage.objectViewer" --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $failed += "vault read for jingle-sa" }

        Write-Host "[5/5] Jingle may use Gemini and write logs"
        foreach ($role in @("roles/aiplatform.user", "roles/logging.logWriter")) {
            gcloud projects add-iam-policy-binding $projectname --member "serviceAccount:$jingleSa" --role $role --condition=None --quiet 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed += $role }
        }

        if ($failed.Count -gt 0) {
            $message = New-Result "Failed" ("The North Pole is not ready yet: " + ($failed -join ", ") + ". Please validate again in a minute.")
        }
        else {
            $message = New-Result "Succeeded" "The North Pole Command Center is ready: services on, North Pole data loaded into gs://$vault, Jingle's permissions set."
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
