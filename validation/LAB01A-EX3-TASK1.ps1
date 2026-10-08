<#
 CloudLabs validation | LAB01A-EX3-TASK1
 Deploy the Agent to a Private Compute Engine VM
 Lab: Day 1 - Jingle Awakens (Developer)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - Jingle's completed code is in gs://<vault>/app/jingle (TODOs done)
   - VM jingle-workshop RUNNING as jingle-sa, tag jingle,
     KB_BUCKET = the vault, KB_FILE = north-pole-data.json
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
    $vault = Get-Vault
    $code = if ($vault) { (gcloud storage cat "gs://$vault/app/jingle/agent.py" --project $projectname 2>$null | Out-String) } else { "" }
    if (-not $code.Trim()) {
        $message = New-Result "Failed" "Jingle's code was not found in Santa's Knowledge Vault. Upload your jingle folder to gs://$vault/app/jingle."
    }
    elseif ($code -match 'tools\s*=\s*\[\s*\]' -or $code -match 'instruction\s*=\s*""') {
        $message = New-Result "Failed" "Jingle's code still has unfinished TODOs: give Jingle an instruction and its tool, then upload it again."
    }
    elseif (-not $vm) {
        $message = New-Result "Failed" "Jingle's workshop VM '$vmName' was not found."
    }
    elseif ($vm.status -ne "RUNNING") {
        $message = New-Result "Failed" "Jingle's workshop VM is $($vm.status). It must be RUNNING."
    }
    elseif (@($vm.serviceAccounts)[0].email -ne $jingleSa) {
        $message = New-Result "Failed" "Jingle's workshop runs as '$(@($vm.serviceAccounts)[0].email)'. Jingle must use its own identity."
    }
    elseif (@($vm.tags.items) -notcontains "jingle") {
        $message = New-Result "Failed" "The workshop is missing the network tag that lets it through the sleigh gate (IAP)."
    }
    else {
        $meta = @{}
        foreach ($i in @($vm.metadata.items)) { if ($i.key) { $meta[$i.key] = $i.value } }
        Write-Host "Vault: $vault | KB_BUCKET: $($meta['KB_BUCKET']) | KB_FILE: $($meta['KB_FILE'])"
        if ($meta["KB_BUCKET"] -ne $vault) {
            $message = New-Result "Failed" "The workshop does not point at Santa's Knowledge Vault. Check the KB_BUCKET setting."
        }
        elseif ($meta["KB_FILE"] -ne $dataFile) {
            $message = New-Result "Failed" "The workshop does not point at the North Pole data file. Check the KB_FILE setting."
        }
        else {
            $message = New-Result "Succeeded" "Jingle is awake in its private workshop, running as its own identity and reading Santa's Knowledge Vault."
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
