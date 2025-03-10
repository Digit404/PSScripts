# Here is a part of my powershell profile made to be compatible with 7+ and 5.0
# Terminal Icons
if (!(Get-Module -ListAvailable -Name Terminal-Icons)) {
	Install-Module -Name Terminal-Icons -Repository PSGallery
}
Import-Module Terminal-Icons

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

	Set-PSReadLineOption -PromptText "> " -ContinuationPrompt "    "

	Write-Host $Name -NoNewline
	Write-Host " " -NoNewline
	Write-Host $currentDir -NoNewline -ForegroundColor DarkYellow
	Write-Host " " -NoNewline
	return "> "
}

function Write-Time {
 # Requires HostTools.ps1 to be sourced in the profile
	$TermialWidth = $Host.UI.RawUI.BufferSize.Width

	Move-Cursor -X ($TermialWidth - 5) -Absolute
	Write-Host (Get-Date -Format "HH:mm") -ForegroundColor DarkGray -NoNewline
	Write-Host "`r" -NoNewline
}

function Explore { Invoke-Item . }

New-Alias new "New-Object"

# Default Keybindings that aren't set in some versions of PSReadLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Escape' -ScriptBlock { ClearLine }
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+RightArrow' -Function SelectForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Shift+LeftArrow' -Function SelectBackwardWord

Remove-PSReadLineKeyHandler -Chord 'Ctrl+a'
Remove-PSReadLineKeyHandler -Chord 'Ctrl+A'
Set-PSReadLineKeyHandler -Chord 'Ctrl+A' -Function SelectAll
Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -Function SelectAll