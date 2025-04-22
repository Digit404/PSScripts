class Script {
    static [System.Collections.ArrayList]$scripts = @()
    [string]$Name
    [string]$Description

    Script([string]$name, [string]$description) {
        $this.Name = $name
        $this.Description = $description

        [Script]::scripts.Add($this)
    }
}

[void][Script]::scripts.Clear()  # Clear the scripts array before adding new scripts

[Script]::new("MediaTools.ps1", "A collection of PowerShell functions for downloading, converting, compressing, and updating media files using yt-dlp and FFmpeg.")  | Out-Null
[Script]::new("HostTools.ps1", "A PowerShell script with various utility functions to enhance system interaction and scripting efficiency.")  | Out-Null
[Script]::new("PSProfile.ps1", "Useful PowerShell profile with a better prompt.")  | Out-Null
[Script]::new("VHSify.ps1", "Converts a specified video file into a VHS-like video. Requires FFmpeg.")  | Out-Null
[Script]::new("Lisp.ps1", "A simple set of functions to turn PowerShell into a Lisp-like language.")  | Out-Null
[Script]::new("BitTools.ps1", "A collection of PowerShell functions for manipulating and displaying binary data.")  | Out-Null

Write-Host "Here is a list of scripts available:"

Write-Host ([Script]::scripts | Format-Table | Out-String) -ForegroundColor Blue

Write-Host "You can run any of these scripts using the powershell command ""iwr scripts.rebitwise.com/{script name}.ps1 | iex""`n"