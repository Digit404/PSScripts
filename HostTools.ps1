<#
.SYNOPSIS
This script contains several PowerShell functions for various tasks.

.DESCRIPTION
The script includes the following functions:
- Move-Cursor: Moves the cursor position on the console.
- Destruct: Retrieves the properties of an input object.
- New-Temp: Generates a temporary file with an optional extension.
- Add-Path: Adds a path to the system or user's PATH environment variable.
- Remove-Path: Removes a path from the system or user's PATH environment variable.
- ColorTest: Displays a color test on the console.
- FakePaste: Simulates a paste operation by sending keystrokes.
- Write-Object: Formats and displays an object's properties.
- Object: Creates a PowerShell object from a string.
#>


<#
.SYNOPSIS
Moves the cursor to a specified position on the console.

.DESCRIPTION
The Move-Cursor function is used to move the cursor to a specified position on the console. It can move the cursor either absolutely or relatively.

.PARAMETER X
The X coordinate of the new cursor position. If not specified, the current X coordinate will be used.

.PARAMETER Y
The Y coordinate of the new cursor position. If not specified, the current Y coordinate will be used.

.PARAMETER Absolute
Specifies that the cursor should be moved to an absolute position on the console. If this switch is not used, the cursor will be moved relatively.

.PARAMETER Relative
This switch doesn't have any effect on the cursor movement. It is included for peace of mind.

.EXAMPLE
Move-Cursor -X 10 -Y 5
Moves the cursor to the absolute position (10, 5) on the console.

.EXAMPLE
Move-Cursor -X 5 -Y 2 -Relative
Moves the cursor relatively by adding 5 to the current X coordinate and 2 to the current Y coordinate.
#>
function Move-Cursor {
    param (
        [Parameter()]
        [AllowNull()]
        [nullable[int]]$X,

        [Parameter()]
        [AllowNull()]
        [nullable[int]]$Y,

        [Parameter()]
        [switch]$Absolute,

        [Parameter()]
        [switch]$Relative # Doesn't do anything but good for peace of mind
    )

    $cursorPos = $Host.UI.RawUI.CursorPosition # Current cursor position
    $pos = New-Object System.Management.Automation.Host.Coordinates

    if ($Absolute) {
        $pos.X = $X ?? $cursorPos.X
        $pos.Y = $Y ?? $cursorPos.Y
    }
    else {
        $pos.X = $X + $cursorPos.X
        $pos.Y = $Y + $cursorPos.Y
    }

    $Host.UI.RawUI.CursorPosition = $pos
}

function Destruct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Object] $InputObject
    )

    $propertiesList = Get-Member -InputObject $InputObject -MemberType Properties

    $properties = $propertiesList.Foreach({
            $InputObject.$($_.Name)
        })

    return $properties
}

<#
.SYNOPSIS
Creates a new temporary file with an optional extension.

.DESCRIPTION
The New-Temp function creates a new temporary file using the GetTempFileName method from the System.IO.Path class. 
It can also add an optional extension to the file.

.PARAMETER Extension
Specifies the extension to be added to the temporary file. If the extension does not start with a dot (.), 
the function automatically adds one.

.EXAMPLE
New-Temp -Extension ".txt"
Creates a new temporary file with the .txt extension.

.EXAMPLE
New-Temp -Extension "csv"
Creates a new temporary file with the .csv extension.

.OUTPUTS
System.String
Returns the path of the newly created temporary file.

#>
function New-Temp {
    [CmdletBinding()]
    param (
        [Alias("Type")]
        [string]$Extension
    )

    $tempFile = [System.IO.Path]::GetTempFileName()

    if ($Extension) {
        if (-not $Extension.StartsWith(".")) {
            $Extension = "." + $Extension
        }

        $tempFile = $tempFile.Split(".")[0]
    }

    return ($tempFile + $Extension)
}

<#
.SYNOPSIS
Adds a path to the system, user, or process environment variable PATH.

.DESCRIPTION
The Add-Path function adds a specified path to the system, user, or process environment variable PATH. It ensures that the path is not already present in the PATH variable and handles empty strings in the PATH variable.

.PARAMETER Path
Specifies the path to be added to the PATH variable. This parameter is mandatory and accepts a string value.

.PARAMETER User
Specifies that the path should be added to the user environment variable PATH. This parameter is mutually exclusive with the Machine and Process parameters.

.PARAMETER Machine
Specifies that the path should be added to the machine environment variable PATH. This parameter is mutually exclusive with the User and Process parameters.

.PARAMETER Process
Specifies that the path should be added to the process environment variable PATH. This parameter is mutually exclusive with the User and Machine parameters.

.EXAMPLE
Add-Path -Path "C:\Program Files\MyApp" -User
Adds the path "C:\Program Files\MyApp" to the user environment variable PATH.

.EXAMPLE
Add-Path -Path "C:\Program Files\MyApp" -Machine
Adds the path "C:\Program Files\MyApp" to the machine environment variable PATH.

.EXAMPLE
Add-Path -Path "C:\Program Files\MyApp" -Process
Adds the path "C:\Program Files\MyApp" to the process environment variable PATH.

#>
function Add-Path {
    [CmdletBinding(DefaultParameterSetName = 'User')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Path,

        [Parameter(ParameterSetName = 'User')]
        [Alias("AsUser")]
        [switch]$User,

        [Parameter(ParameterSetName = 'Machine')]
        [Alias("AsMachine")]
        [switch]$Machine,

        [Parameter(ParameterSetName = 'Process')]
        [Alias("Temp", "Temporary")]
        [switch]$Process
    )
    
    $Scope = $PSCmdlet.ParameterSetName

    $Path = Resolve-Path -Path $Path -ErrorAction Stop

    Write-Host "Adding $Path to $Scope PATH..."

    $SystemPath = [Environment]::GetEnvironmentVariable("PATH", $Scope).Split(";")

    if ($SystemPath -contains $Path) {
        throw "$Path already in PATH!"
    }

    # clean up empty strings
    $SystemPath = $SystemPath.Where({ $_ -ne "" })

    $SystemPath += $Path

    $NewPath = $SystemPath -join ";"

    [Environment]::SetEnvironmentVariable("PATH", $NewPath, $Scope)
}

<#
.SYNOPSIS
Removes a specified path from the system or user PATH environment variable.

.DESCRIPTION
The Remove-Path function removes a specified path from the system or user PATH environment variable. It provides three parameter sets to specify the scope of the removal: User, Machine, and Process.

.PARAMETER Path
Specifies the path to be removed from the PATH environment variable.

.PARAMETER User
Specifies that the path should be removed from the user-level PATH environment variable.

.PARAMETER Machine
Specifies that the path should be removed from the machine-level PATH environment variable.

.PARAMETER Process
Specifies that the path should be removed from the current process-level PATH environment variable.

.EXAMPLE
Remove-Path -Path "C:\Program Files\MyApp" -User
Removes "C:\Program Files\MyApp" from the user-level PATH environment variable.

.EXAMPLE
Remove-Path -Path "C:\Program Files\MyApp" -Machine
Removes "C:\Program Files\MyApp" from the machine-level PATH environment variable.

.EXAMPLE
Remove-Path -Path "C:\Program Files\MyApp" -Process
Removes "C:\Program Files\MyApp" from the current process-level PATH environment variable.
#>
function Remove-Path {
    [CmdletBinding(DefaultParameterSetName = 'User')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Path,

        [Parameter(ParameterSetName = 'User')]
        [Alias("AsUser")]
        [switch]$User,

        [Parameter(ParameterSetName = 'Machine')]
        [Alias("AsMachine")]
        [switch]$Machine,

        [Parameter(ParameterSetName = 'Process')]
        [Alias("Temp", "Temporary")]
        [switch]$Process
    )
    
    $Scope = $PSCmdlet.ParameterSetName

    $Path = Resolve-Path $Path -ErrorAction Stop

    Write-Host "Removing $Path from $Scope PATH..."

    $SystemPath = [Environment]::GetEnvironmentVariable("PATH", $Scope).Split(";")
    
    $PathInPath = $SystemPath.Where({ $_ -eq $Path })

    $SystemPath = $SystemPath.Where({ $_ -ne $Path -and $_ -ne "" })

    if (-not $PathInPath) {
        throw "$Path not in PATH!"
    }

    $NewPath = $SystemPath -join ";"

    [Environment]::SetEnvironmentVariable("PATH", $NewPath, $Scope)
}

<#
.SYNOPSIS
    Performs a color test by displaying all possible combinations of foreground and background colors.

.DESCRIPTION
    The ColorTest function displays all possible combinations of foreground and background colors in the console.
    It uses the GetValues method of the ConsoleColor enumeration to retrieve all available colors.
    For each background color, it iterates through all foreground colors and displays the color combination using Write-Host.

.EXAMPLE
    ColorTest
    Displays all possible combinations of foreground and background colors in the console.

.NOTES
    Author: [Your Name]
    Date: [Current Date]
#>
function ColorTest {
    $colors = [enum]::GetValues([System.ConsoleColor])
    foreach ($color in $colors) {
        $spaceString = " " * ($color.ToString().Length + 1)
        Write-Host "$spaceString" -ForegroundColor $color -BackgroundColor $color -NoNewLine
    }
    Write-Host
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host
    }
}

<#
.SYNOPSIS
    Simulates a paste operation by sending keystrokes to the active window.

.DESCRIPTION
    The FakePaste function simulates a paste operation by sending the specified value as keystrokes to the active window.

.PARAMETER Value
    Specifies the value to be pasted. This parameter is mandatory and accepts input from the pipeline.

.EXAMPLE
    PS C:\> "Hello, World!" | FakePaste
    Sends the string "Hello, World!" as keystrokes to the active window.

.NOTES
    This function requires the System.Windows.Forms assembly to be loaded.
#>
function FakePaste {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Value
    )
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [System.Windows.Forms.SendKeys]::SendWait($Value)
}

<#
.SYNOPSIS
Writes the properties of an object to the console.

.DESCRIPTION
The Write-Object function writes the properties of an object to the console using the Format-List cmdlet. It can be used to display specific properties or all properties of an object.

.PARAMETER InputObject
Specifies the object whose properties will be written to the console. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER All
Indicates whether all properties of the object should be displayed. By default, only the default properties are displayed.

.EXAMPLE
$object = Get-Process
$object | Write-Object

This example retrieves a process object using the Get-Process cmdlet and pipes it to the Write-Object function. The properties of the process object are displayed on the console.

.EXAMPLE
$object = Get-Process
$object | Write-Object -All

This example retrieves a process object using the Get-Process cmdlet and pipes it to the Write-Object function with the -All parameter. All properties of the process object are displayed on the console.

#>
function Write-Object {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Object")]
        [object]$InputObject,

        [switch]$All
    )

    $formatListParams = @{
        InputObject = $InputObject
    }

    if ($All) {
        $formatListParams['Property'] = '*'
    }

    Format-List @formatListParams
}

<#
.SYNOPSIS
Creates a custom PowerShell object.

.DESCRIPTION
The Object function creates a custom PowerShell object using the input object provided.

.PARAMETER InputObject
Specifies the input object to be used for creating the custom PowerShell object.

.EXAMPLE
$myObject = Object @{
    Name = "John"
    Age = 30
}

This example creates a custom PowerShell object named $myObject with properties Name and Age.

.INPUTS
[string]
The function accepts a string as the input object.

.OUTPUTS
[psobject]
The function returns a custom PowerShell object.

#>
function Object {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string] $InputObject
    )

    $object = New-Object psobject -Property $InputObject
    return $object
}

$BoxChars = @{
    Corner     = @{
        TopLeft     = '┌'
        TopRight    = '┐'
        BottomLeft  = '└'
        BottomRight = '┘'
        Rounded     = @{
            TopLeft     = '╭'
            TopRight    = '╮'
            BottomLeft  = '╰'
            BottomRight = '╯'
        }
    
    }
    Horizontal = '─'
    Vertical   = '│'
    Cap        = @{
        Left   = '╴'
        Right  = '╶'
        Top    = '╵'
        Bottom = '╷'
    }
}

<#
.SYNOPSIS
Draws a box with text in the console.

.DESCRIPTION
The DrawBox function draws a box with text inside it in the console. The box can have a label, customizable colors, padding, margins, and more.

.PARAMETER Text
The text to display inside the box.

.PARAMETER Label
The label text to display at the top of the box.

.PARAMETER Width
The width of the box in characters.

.PARAMETER Height
The height of the box in characters.

.PARAMETER Padding
The padding inside the box in characters.

.PARAMETER PaddingX
The horizontal padding inside the box in characters.

.PARAMETER PaddingY
The vertical padding inside the box in characters.

.PARAMETER MarginX
The horizontal margin outside the box in characters.

.PARAMETER MarginY
The vertical margin outside the box in characters.

.PARAMETER BorderColor
The color of the box border. Default is Gray.

.PARAMETER TextColor
The color of the text inside the box. Default is Gray.

.PARAMETER AutoMargin
Automatically centers the box horizontally in the console window.

.PARAMETER Justify
Justifies the text inside the box.

.PARAMETER Rounded
Draws the box with rounded corners.

.EXAMPLE
DrawBox -Text "Hello, World!" -Width 20 -Height 5 -BorderColor Green

Draws a green box with the text "Hello, World!" centered inside.

.EXAMPLE
DrawBox -Text "This is a very long line of text that will wrap inside the box." -Width 30 -AutoMargin -Rounded -BorderColor DarkCyan -TextColor Yellow

Draws a rounded box with a dark cyan border and yellow text that is automatically centered in the console. The text wraps inside the box.

.NOTES
This function uses characters from the BoxChars hashtable to draw the box.
#>
function DrawBox {
    param (
        [string]$Text,
        [string]$Label,
        [int]$Width,
        [int]$Height,
        [int]$Padding,
        [int]$PaddingX,
        [int]$PaddingY,
        [int]$MarginX,
        [int]$MarginY,
        [System.ConsoleColor]$BorderColor,
        [System.ConsoleColor]$TextColor,
        [switch]$AutoMargin,
        [switch]$Justify,
        [switch]$Rounded
    )

    # Add extra chars to label
    if ($Label) {
        $Label = "$($BoxChars.Cap.Left)$Label$($BoxChars.Cap.Right)"
    }

    if (!$BorderColor) {
        $BorderColor = 'Gray'
    }

    if (!$TextColor) {
        $TextColor = 'Gray'
    }

    # Calculate padding
    if (!$PaddingX) {
        $PaddingX = $Padding
    }

    if (!$PaddingY) {
        $PaddingY = $Padding
    }

    # Adjust width and height to fit text
    if ($Text) {
        $SplitText = $Text -split "`n"

        $MaxLength = 0

        for ($i = 0; $i -lt $SplitText.Length; $i++) {
            $SplitText[$i] = (" " * $PaddingX) + $SplitText[$i] + (" " * $PaddingX)
            $MaxLength = [Math]::Max($MaxLength, $SplitText[$i].Length)
        }
        if (!$Width) {
            $Width = $MaxLength
        }
        if (!$Height) {
            $Height = $SplitText.Length + ($PaddingY * 2)
        }
        
        if (!$Justify) {
            for ($i = 0; $i -lt $SplitText.Length; $i++) {
                $LengthDiff = ($MaxLength - $SplitText[$i].Length) / 2
                $SplitText[$i] = (" " * $LengthDiff) + $SplitText[$i]
            }
        }
    }

    if ($Label.Length % 2 -ne 0 -xor $Width % 2 -ne 0) {
        $Label += $BoxChars.Horizontal
    }

    # Make sure width is not less than label
    if ($Width -lt $label.Length) {
        $Width = $Label.Length
    }

    if ($AutoMargin) {
        $MarginX = $Host.UI.RawUI.BufferSize.Width / 2 - $Width / 2
    }

    # Generate padding if height is larger than text height
    if ($Height -gt $SplitText.Length) {
        [double]$PaddingY = ($Height - $SplitText.Length) / 2
    }

    $Corner = if ($Rounded) {
        $BoxChars.Corner.Rounded
    }
    else {
        $BoxChars.Corner
    }

    $LabelPos = $Width / 2 - $Label.Length / 2

    Write-Host ("`n" * $MarginY) -NoNewline

    Write-Host (" " * $MarginX) -NoNewline
    Write-Host $Corner.TopLeft -ForegroundColor $BorderColor -NoNewline
    Write-Host ([string]$BoxChars.Horizontal * [Math]::Floor($LabelPos)) -ForegroundColor $BorderColor -NoNewline
    Write-Host $Label -ForegroundColor $BorderColor -NoNewline
    Write-Host ([string]$BoxChars.Horizontal * [Math]::Ceiling($LabelPos)) -ForegroundColor $BorderColor -NoNewline
    Write-Host $Corner.TopRight -ForegroundColor $BorderColor

    for ($i = 0; $i -lt $Height; $i++) {
        Write-Host (" " * $MarginX) -NoNewline
        Write-Host $BoxChars.Vertical -ForegroundColor $BorderColor -NoNewline
        if ($i -lt [Math]::Floor($PaddingY) -or $i -ge [Math]::Floor($Height - $PaddingY)) {
            Write-Host (" " * $Width) -NoNewline
        }
        else {
            for ($j = 0; $j -lt $Width; $j++) {
                # Use null coaslescing if available, but stupid PowerShell 5.1 doesn't recognize
                $char = if ($SplitText[[Math]::floor($i - $PaddingY)][$j]) {
                    $SplitText[[Math]::floor($i - $PaddingY)][$j]
                }
                else {
                    " "
                }

                Write-Host $char -ForegroundColor $TextColor -NoNewline
            }
        }
        Write-Host $BoxChars.Vertical -ForegroundColor $BorderColor
    }

    Write-Host (" " * $MarginX) -NoNewline
    Write-Host $Corner.BottomLeft -ForegroundColor $BorderColor -NoNewline
    Write-Host ([string]$BoxChars.Horizontal * $Width) -ForegroundColor $BorderColor -NoNewline
    Write-Host $Corner.BottomRight -ForegroundColor $BorderColor

    Write-Host ("`n" * $MarginY) -NoNewline
}

# wrapper function for SetEnvironmentVariable
function Set-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value,

        [Parameter()]
        [string] $Scope = "Process"
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
}

<#
.SYNOPSIS
Opens the target location of a shortcut file.

.DESCRIPTION
The Open-Shortcut function opens the target location of a specified shortcut file (.lnk) using the Windows Script Host object model. It resolves the full path of the shortcut file, retrieves the target path from the shortcut object, and then sets the current location to the target path.

.PARAMETER ShortcutPath
The path to the shortcut file (.lnk). This parameter is mandatory and must be provided.

.EXAMPLE
Open-Shortcut C:\Users\MyUser\Desktop\MyShortcut.lnk

Opens the target location of the 'MyShortcut.lnk' file on the desktop.

.EXAMPLE
Get-ChildItem *.lnk | Open-Shortcut

Opens the target locations of all shortcut files in the current directory.

.NOTES
The function releases the COM object used to create the shortcut object to avoid potential memory leaks.
#>
function Open-Shortcut {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$ShortcutPath
    )
	
    if (-not (Test-Path $ShortcutPath)) {
        Write-Warning "$ShortcutPath does not exist."
        return
    }

    $ShortcutPath = Resolve-Path $ShortcutPath
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $targetPath = $shortcut.TargetPath
	
    Set-Location $targetPath

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
}

<#
.SYNOPSIS
Refreshes the Windows font cache by stopping the Font Cache Service, clearing the font cache files, and restarting the service.

.DESCRIPTION
The RefreshFontCache function stops the Windows Font Cache Service, deletes all font cache files from the local app data folder, and then restarts the service. This can help resolve font-related issues on Windows systems.

.EXAMPLE
RefreshFontCache

This command will refresh the Windows font cache by executing the steps described above.

.NOTES
Requires administrative privileges to stop and start services.
#>
function RefreshFontCache {
    [CmdletBinding()]
    param ()
    
    # Refreshing the font cache
    Write-Host "Stopping the Windows Font Cache Service..." -ForegroundColor Yellow
    Stop-Service -Name "FontCache" -Force

    Write-Host "Clearing the font cache files..." -ForegroundColor Yellow
    $fontCachePath = "$env:LocalAppData\FontCache"
    if (Test-Path -Path $fontCachePath) {
        Remove-Item -Path "$fontCachePath\*" -Force -Recurse
    }

    Write-Host "Starting the Windows Font Cache Service..." -ForegroundColor Yellow
    Start-Service -Name "FontCache"
    
    Write-Host "Font cache refreshed successfully!" -ForegroundColor Green
}

<#
.SYNOPSIS
Converts various input types (null, byte array, numeric types, file paths, and strings) to a byte array.

.DESCRIPTION
The Get-Bytes function takes an input and converts it into a byte array. It handles:
- Null input by returning null.
- Byte arrays by returning them directly.
- Numeric types by converting them to byte arrays using the appropriate method.
- File paths by reading the file contents into a byte array.
- Strings by encoding them as UTF-8 byte arrays.

.PARAMETER InputData
The input data to be converted into a byte array. This can be null, a byte array, a numeric type, a file path, or a string.

.EXAMPLE
$bytes = Get-Bytes -InputData $null

This command returns null since the input data is null.

.EXAMPLE
$bytes = Get-Bytes -InputData "Hello, World!"

This command converts the string "Hello, World!" into a UTF-8 byte array and returns it.

.EXAMPLE
$bytes = Get-Bytes -InputData 12345

This command converts the integer 12345 into a byte array and returns it.

.EXAMPLE
$bytes = Get-Bytes -InputData "C:\path\to\file.txt"

This command reads the contents of the specified file into a byte array and returns it.

.NOTES
Make sure the necessary permissions are in place to access files if providing a file path.
#>
function Get-Bytes {
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$InputData
    )
    
    if ($null -eq $InputData) {
        # If the input is null, return null
        return $null
    }
    elseif ($InputData -is [byte[]]) {
        # InputData is already a byte array, return it as-is
        return $InputData
    }
    elseif ($InputData -is [System.ValueType]) {
        # InputData is a numeric type, convert it to a byte array
        $bytes = [BitConverter]::GetBytes($InputData)
        return $bytes
    }
    elseif (Test-Path $InputData -PathType Leaf) {
        # InputData is a file path
        try {
            $bytes = [System.IO.File]::ReadAllBytes($InputData)
            return $bytes
        }
        catch {
            Write-Error "Failed to read file: $_"
            return $null
        }
    }
    else {
        # InputData is not a file path nor numeric type, convert string to byte array
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputData)
        return $bytes
    }
}

<#
.SYNOPSIS
Displays the structure of a specified directory, showing files and subdirectories with tree-like formatting and color coding based on file types.

.DESCRIPTION
The Show-FileStructure function recursively lists the contents of a directory in a tree-like format. Files and directories are color-coded based on their type:
- Directories: DarkCyan
- Root directory: Blue
- Files: DarkYellow (with different colors for specific file types)

.PARAMETER Path
Specifies the path of the directory to display. Defaults to the current working directory ($PWD).

.PARAMETER Prefix
Used internally to format the tree structure. Default is an empty string.

.PARAMETER Exclude
Specifies an array of paths to exclude from the output. Default is an empty array.

.PARAMETER IsLast
Used internally to identify if the current item is the last in its parent directory. Switch parameter.

.PARAMETER IsSubDir
Used internally to specify if the current item is a subdirectory. Switch parameter.

.EXAMPLE
Show-FileStructure -Path "C:\MyDirectory"

This command displays the structure of "C:\MyDirectory" with files and subdirectories in a tree-like formatted output.
#>
function Show-FileStructure {
    param (
        [string]$Path = $PWD,
        [string]$Prefix = "",
        [string[]]$Exclude = @(),
        [switch]$IsLast,
        [switch]$IsSubDir
    )

    $FolderColor = "DarkCyan"
    $RootColor = "Blue"
    $FileColor = "DarkYellow"
    $LineColor = "White"

    $item = Get-Item $Path

    # Function to determine color based on file extension
    function Get-ItemColor($item) {
        if ($item.PSIsContainer) { $FolderColor }
        else {
            $Extension = $item.Extension.ToLower()
            switch -Regex ($Extension) {
                # Executables
                '^\.?(exe|bat|cmd|ps1|sh|app)$' { "Red" }
                
                # Media
                '^\.?(mp3|wav|flac|ogg|mp4|avi|mkv|mov|wmv|jpg|jpeg|png|gif|bmp|svg|webp)$' { "Magenta" }
                
                # Documents
                '^\.?(doc|docx|pdf|txt|md|rtf|csv|xlsx|xls|pptx|ppt)$' { "White" }
                
                # Archives
                '^\.?(zip|rar|7z|tar|gz)$' { "DarkGray" }
                
                # Code files
                '^\.?(py|js|html|css|cpp|c|java|go|rb|php)$' { "Green" }
                
                # Config files
                '^\.?(json|xml|yaml|yml|ini|conf)$' { "Cyan" }
                
                # Default
                default { $FileColor }
            }
        }
    }

    # Display the current item
    if (!$IsSubDir) {
        Write-Host "$($item.Name)" -ForegroundColor $RootColor
    }
    else {
        $symbol = if ($IsLast) { "└─" } else { "├─" }
        Write-Host "$Prefix$symbol " -NoNewline -ForegroundColor $LineColor
        Write-Host "$($item.Name)" -ForegroundColor (Get-ItemColor $item)
    }

    # If it's a directory, process its contents
    if ($item.PSIsContainer) {

        $excludedFolders = @()

        if ($Exclude) {
            foreach ($ex in @($Exclude)) {
                $resolvedPath = Resolve-Path $ex
                $normalizedPath = [System.IO.Path]::GetFullPath($resolvedPath).TrimEnd('\').ToLower()
                $excludedFolders += $normalizedPath
            }
        }

        $children = Get-ChildItem $item.FullName | Sort-Object { $_.PSIsContainer } -Descending
        $childCount = $children.Count

        for ($i = 0; $i -lt $childCount; $i++) {
            $child = $children[$i]
            $childName = [System.IO.Path]::GetFullPath($child.FullName).TrimEnd('\').ToLower()

            if ($excludedFolders -contains $childName) {
                continue
            }

            $newPrefix = if (!$IsSubDir) { "" } elseif ($IsLast) { "$Prefix   " } else { "$Prefix│  " }
            $isLastChild = ($i -eq $childCount - 1)

            Show-FileStructure -Path $child.FullName -Prefix $newPrefix -IsLast:$isLastChild -IsSubDir -Exclude $excludedFolders
        }
    }
}

<#
.SYNOPSIS
Converts ConsoleColor values to ANSI escape codes for use in terminal output.

.DESCRIPTION
The Get-ColorEscapeCode function converts ConsoleColor values to ANSI escape codes for use in terminal output. It maps ConsoleColor values to their corresponding ANSI escape codes for foreground and background colors.

.PARAMETER Color
Specifies the ConsoleColor value to convert to an ANSI escape code.

.PARAMETER Background
Indicates whether the ANSI escape code should be for the background color. Default is false.

.EXAMPLE
Get-ColorEscapeCode -Color DarkGreen

This command returns the ANSI escape code for the DarkGreen ConsoleColor value.
#>
function Get-ColorEscapeCode {
    param (
        [Parameter(Mandatory)]
        [System.ConsoleColor]$Color,
        [Parameter(Alias = 'Bg')]
        [Switch]$Background
    )

    $baseCode = if ($Background) { 40 } else { 30 }

    switch ($Color) {
        'Black'       { return "`e[$($baseCode)m" }
        'DarkBlue'    { return "`e[$($baseCode + 4)m" }
        'DarkGreen'   { return "`e[$($baseCode + 2)m" }
        'DarkCyan'    { return "`e[$($baseCode + 6)m" }
        'DarkRed'     { return "`e[$($baseCode + 1)m" }
        'DarkMagenta' { return "`e[$($baseCode + 5)m" }
        'DarkYellow'  { return "`e[$($baseCode + 3)m" }
        'Gray'        { return "`e[$($baseCode + 7)m" }
        'DarkGray'    { return "`e[$($baseCode + 60)m" }
        'Blue'        { return "`e[$($baseCode + 64)m" }
        'Green'       { return "`e[$($baseCode + 62)m" }
        'Cyan'        { return "`e[$($baseCode + 66)m" }
        'Red'         { return "`e[$($baseCode + 61)m" }
        'Magenta'     { return "`e[$($baseCode + 65)m" }
        'Yellow'      { return "`e[$($baseCode + 63)m" }
        'White'       { return "`e[$($baseCode + 67)m" }
        default       { return "`e[0m" } # Reset
    }
}

<#
.SYNOPSIS
Displays a byte array or string in a formatted table with hexadecimal and ASCII representation.

.DESCRIPTION
The `Write-Bytes` function takes an input object, either a string or a byte array, and displays its contents
in a formatted table. Each line of the table shows the byte offset, hexadecimal representation, and ASCII
representation of the input data. Non-printable characters in the ASCII column are represented as dots.

.PARAMETER InputObject
The input data which can be a string or a byte array. If a string is provided, it is converted to a UTF-8 byte array.

.PARAMETER SectionSpacing
Specifies the number of spaces between the columns in the output table. Default is 4.

.PARAMETER LineLength
Determines the number of bytes displayed per row in the table. Default is 8.

.PARAMETER TableColor
Sets the foreground color for the table headings. Default is 'White'.
#>
function Write-Bytes {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Object")]
        $InputObject,
        [int]$SectionSpacing = 4,
        [int]$LineLength = 16,
        [int]$LetterSpacing = 1,
        [System.ConsoleColor]$TableColor = 'White'
    )

    # function to determine if a character is printable
    function IsPrintable {
        param (
            [byte]$char
        )
        return ($char -gt 31 -and $char -lt 127)
    }

    if ($InputObject -is [string]) {
        # convert string to byte array
        $ByteArray = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
    }
    elseif ($InputObject -is [byte[]]) {
        $ByteArray = $InputObject
    }
    else {
        Write-Host "Write-Bytes: Invalid input type. Please provide a string or byte array." -ForegroundColor Red
        return
    }

    # print the ruler
    Write-Host (" " * (4 + $SectionSpacing)) -NoNewline -ForegroundColor Black -BackgroundColor $TableColor

    foreach ($i in 0..($lineLength - 1)) {
        Write-Host -NoNewline (("{0:X2}" -f $i) + " ") -ForegroundColor Black -BackgroundColor $TableColor
    }

    Write-Host -NoNewline (" " * ($SectionSpacing - 1)) -ForegroundColor Black -BackgroundColor $TableColor
    Write-Host "ASCII" -ForegroundColor Black -BackgroundColor $TableColor -NoNewline
    Write-Host ("-" * ($lineLength * $LetterSpacing - 5)) -ForegroundColor Black -BackgroundColor $TableColor -NoNewline
    Write-Host

    [int]$offset = 0

    for ($i = 0; $i -lt $ByteArray.Length; $i += $lineLength) {
        # print the offset
        $formattedOffset = "{0:X4}" -f $offset
        Write-Host -NoNewline "$formattedOffset" -ForegroundColor Black -BackgroundColor $TableColor
        Write-Host -NoNewline (" " * $SectionSpacing)

        # print the hexadecimal values
        for ($j = 0; $j -lt $lineLength; $j++) {
            if (($i + $j) -lt $ByteArray.Length) {
                $byte = $ByteArray[$i + $j]
                $formattedByte = "{0:X2}" -f $byte
                Write-Host -NoNewline "$formattedByte "
            }
            else {
                Write-Host -NoNewline "   "
            }
        }

        # align ASCII output column
        Write-Host -NoNewline (" " * ($SectionSpacing - 1))

        $spaces = " " * ($LetterSpacing - 1)

        # print the ASCII representation
        for ($j = 0; $j -lt $lineLength; $j++) {
            if (($i + $j) -lt $ByteArray.Length) {
                $byte = $ByteArray[$i + $j]
                if (IsPrintable $byte) {
                    [char]$char = [char]$byte
                    Write-Host -NoNewline "$char"
                }
                else {
                    Write-Host -NoNewline "." -ForegroundColor DarkGray
                }
                Write-Host -NoNewline $spaces
            }
            else {
                Write-Host -NoNewline (" " + $spaces)
            }
        }

        Write-Host ""

        $offset += $lineLength
    }
}