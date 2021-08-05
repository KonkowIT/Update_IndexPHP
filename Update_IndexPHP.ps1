Add-Type -Path "$(${env:ProgramFiles(x86)})\WinSCP\WinSCPnet.dll" -ErrorAction Stop
$index = "C:\SN_Scripts\ArchiveManager\index.php"

function Get-WinScpChildItem ($WinScpSession, $BasePath) {
    $Directory = $WinScpSession.ListDirectory($BasePath)
    $MyCollection = @()

    foreach ($DirectoryEntry in $Directory.Files) {
    
        if (($DirectoryEntry.Name -ne '.') -and ($DirectoryEntry.Name -ne '..')) {
            $TempObject = New-Object System.Object
            
            if ($DirectoryEntry.IsDirectory) {
                $SavePath = $BasePath

                if ($BasePath -eq '/') {
                    $BasePath += "$($DirectoryEntry.Name)"
                }
                else {
                    $BasePath += "/$($DirectoryEntry.Name)"
                }
    
                $TempObject | Add-Member -MemberType NoteProperty -name 'Name' -Value $BasePath
                $TempObject | Add-Member -MemberType NoteProperty -name 'IsDirectory' -Value $true
                $MyCollection += $TempObject
                $MyCollection += Get-WinScpChildItem $WinScpSession $BasePath
                $BasePath = $SavePath
            }
            else {
                $TempObject | Add-Member -MemberType NoteProperty -name 'Name' -Value "$BasePath/$DirectoryEntry"
                $TempObject | Add-Member -MemberType NoteProperty -name 'IsDirectory' -Value $false
                $MyCollection += $TempObject
            }
        }
    }
    
    return $MyCollection
}

$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol   = [WinSCP.Protocol]::ftp
    HostName   = "***"
    PortNumber = 1
    UserName   = "***"
    Password   = "***"
}

$session = New-Object WinSCP.Session
$session.Open($sessionOptions)
$transferOptions = New-Object WinSCP.TransferOptions
$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
$transferOptions.OverwriteMode = [WinSCP.OverwriteMode]::Overwrite

$a = Get-WinSCPChildItem -WinScpSession $session -BasePath "/www/public/LedCameras/archive"
$b = ($a | ? { $_.IsDirectory -eq $true }).Name

Foreach ($dir in $b) {
    $r = $session.PutFiles($index, "$dir/", $False, $transferOptions)

    if ($r.IsSuccess -eq $True) {
        "Transfer '$(Split-path -leaf $index)' to '$dir' completed succesfully" 
    }
    else {
        "ERROR: $($r.Failures)"
    }
}

$session.Dispose()

pause