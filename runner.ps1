Param(
  [Parameter(Mandatory=$True,Position=1)][string]$recordPath,
  [Parameter(Position=2)][string]$targetPath
)

if (!$targetPath) {
    $targetPath = Join-Path $recordPath "target"
   New-Item $targetPath -ItemType directory
}

$path = @{'Record' = $recordPath; 'Destination' = $targetPath}

$queue = New-Object 'System.Collections.Generic.Queue[string]'
$renames = New-Object 'System.Collections.Generic.List[string]'

$previousSong = ""


function MaintainQueue() {
    $currentSongDetected = (Get-Process -Name "spotify" -ErrorAction SilentlyContinue | where {$_.MainWindowTitle.Length -gt 7}).MainWindowTitle
        
    if ($global:previousSong -ne $currentSongDetected)
    {
       $global:queue.Enqueue($currentSongDetected)
      
       $global:previousSong = $currentSongDetected
    }
}

function GetNewestRecordedFilePath() {
    $newestFile = (Get-ChildItem -Filter "*.mp3" $path.Record | Sort-Object -Property CreationTime -Descending | Select-Object -first 1).FullName
    return $newestFile
}

function MoveFile ($source, $dest){
    Move-Item $source $dest -ErrorAction SilentlyContinue
    return $?
}

function UpdateScreen() {
    clear
    echo "Queue:"
    echo $global:queue | Format-List

    echo ""
    echo "Renames:"
    echo $global:renames | Format-List

    sleep 1
}

while($true){
    MaintainQueue

    $newestRecordedFilePath = GetNewestRecordedFilePath
    $newestInQueue = $global:queue.Peek()   

    if ($newestRecordedFilePath -and $newestInQueue){
        $targetPath = Join-Path $global:path.Destination ($newestInQueue + ".mp3")
        
        $moveSucceeded = MoveFile $newestRecordedFilePath $targetPath
        if ($moveSucceeded){
            $global:renames.Add("$newestRecordedFilePath --> $($global:queue.Peek())")
            $global:queue.DeQueue()
        }
    }
    UpdateScreen
}
