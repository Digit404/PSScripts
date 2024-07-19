# Here is a part of my powershell profile made to be compatible with 7+ and 5.0
# Terminal Icons
if (!(Get-Module -ListAvailable -Name Terminal-Icons)) {
	Install-Module -Name Terminal-Icons -Repository PSGallery
}
Import-Module Terminal-Icons

# Escape characters and color codes
$ESC = [char]27

$Colors = @{
	DARKBLACK   = "$ESC[30m"
	DARKRED     = "$ESC[31m"
	DARKGREEN   = "$ESC[32m"
	DARKYELLOW  = "$ESC[33m"
	DARKBLUE    = "$ESC[34m"
	DARKMAGENTA = "$ESC[35m"
	DARKCYAN    = "$ESC[36m"
	DARKWHITE   = "$ESC[37m"
	BLACK       = "$ESC[90m"
	RED         = "$ESC[91m"
	GREEN       = "$ESC[92m"
	YELLOW      = "$ESC[93m"
	BLUE        = "$ESC[94m"
	MAGENTA     = "$ESC[95m"
	CYAN        = "$ESC[96m"
	WHITE       = "$ESC[97m"
}

# Put your preferred name here
$CustomName = ""

$Name = If ($CustomName) { $CustomName } Else { $env:USERNAME }

# Better, more colorful prompt
function prompt {
	$homeDir = $env:userprofile
	$currentDir = $PWD.Path

	if ($currentDir.StartsWith($homeDir)) {
		$currentDir = "~" + $currentDir.Substring($homeDir.Length)
	}

	# Uncomment the following line to print time on prompt, requires HostTools.ps1 to be sourced in the profile
	# Write-Time

	Set-PSReadLineOption -PromptText "> "

	"$Name $($Colors.Yellow)$currentDir $($Colors.Reset)$('>' * ($nestedPromptLevel + 1)) "
	return ""
}

function Write-Time {
 # Requires HostTools.ps1 to be sourced in the profile
	$TermialWidth = $Host.UI.RawUI.BufferSize.Width

	Move-Cursor -X ($TermialWidth - 5) -Absolute
	Write-Host (Get-Date -Format "HH:mm") -ForegroundColor DarkGray -NoNewline
	Write-Host "`r" -NoNewline
}

New-Alias new "New-Object"