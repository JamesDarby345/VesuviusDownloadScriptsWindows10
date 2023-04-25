$null = $continueRunning = $true

# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Function to display a system tray notification
function Show-PopupNotification {
    param(
        [string]$Title = 'PowerShell Notification',
        [string]$Message = 'Script has finished executing.',
        [int]$Duration = 200000
    )

    # Create a new NotifyIcon object
    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipTitle = $Title
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.Visible = $true

    # Show the notification and remove it after the specified duration
    $notifyIcon.ShowBalloonTip($Duration)
    Start-Sleep -Milliseconds $Duration
    $notifyIcon.Dispose()
}


trap {
    Write-Host "Interrupt received. Stopping script..."
    $jobEnd = Get-Date
    Write-Host "Job duration: $(($jobEnd - $jobStart).TotalSeconds) seconds"
    $continueRunning = $false
    continue
}

function DownloadFile {
    param(
        [string]$url,
        [string]$outputFile,
        [hashtable]$headers,
        [System.Threading.Semaphore]$semaphore
    )

    $null = $semaphore.WaitOne()

    try {
        Invoke-WebRequest -Uri $url -Headers $headers -OutFile $outputFile
        Write-Host "Downloaded file: $outputFile"
    } catch {
        Write-Host "Error downloading file: $outputFile - StatusCode: $($_.Exception.Response.StatusCode)"
    } finally {
        $null = $semaphore.Release()
    }
}

$user = "<VesuciusUsernameHere>"
$password = "<VesuviusPasswordHere>"
$pair = "${user}:${password}"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$headers = @{ Authorization = $basicAuthValue }
$jobStart = Get-Date

$ranges = @(@{'start'=00000; 'end'=00010}, @{'start'=06000; 'end'=07250}, @{'start'=13000; 'end'=13010})  #this sets the range of .tif files to download, add as many ranges as you want
$overwriteExistingFiles = $false  # Set to $true to download and overwrite existing files

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outputFolder = Join-Path -Path $scriptPath -ChildPath "../fullScrollData"
 
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

$runspacePool = [RunspaceFactory]::CreateRunspacePool()
$null = $runspacePool.SetMaxRunspaces(200) # Set the max number of concurrent runspaces
$null = $runspacePool.Open()

$runspaces = New-Object System.Collections.ArrayList
$semaphore = New-Object System.Threading.Semaphore -ArgumentList 50, 50

foreach ($range in $ranges) {
    Write-Output $range
    $start = $range['start']
    $end = $range['end']
    foreach ($i in $start..$end) {
        if (-not $continueRunning) {
            break
        }

        $url = "http://dl.ash2txt.org/full-scrolls/Scroll1.volpkg/volumes/20230205180739/{0:D5}.tif" -f $i
        $outputFile = Join-Path -Path $outputFolder -ChildPath ("{0:D5}.tif" -f $i)

        if (-not $overwriteExistingFiles -and (Test-Path $outputFile)) {
            Write-Host "File $outputFile already exists, skipping download."
            continue
        }

        $powershell = [powershell]::Create().AddScript($function:DownloadFile).AddArgument($url).AddArgument($outputFile).AddArgument($headers).AddArgument($semaphore)
        $powershell.RunspacePool = $runspacePool

        $runspace = New-Object -TypeName PSObject -Property @{
            Runspace = $powershell.BeginInvoke()
            PowerShell = $powershell
        }
        
        $null = $runspaces.Add($runspace)
    }
}

foreach ($runspace in $runspaces) {
    if (-not $continueRunning) {
        break
    }

    $runSpace.PowerShell.EndInvoke($runSpace.Runspace)
    $runSpace.PowerShell.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()

if (-not $continueRunning) {
    Write-Host "Script stopped."
}

$jobEnd = Get-Date
Write-Host "Job duration: $(($jobEnd  - $jobStart).TotalSeconds) seconds"

Show-PopupNotification -Title "Script Finished" -Message "Your PowerShell script has finished executing."

