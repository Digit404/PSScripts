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
    elseif ($InputObject -is [System.Object[]]) {
        # convert array of objects to byte array
        $ByteArray = @()
        foreach ($item in $InputObject) {
            if ($item -is [byte]) {
                $ByteArray += $item
            }
            else {
                Write-Host "Write-Bytes: Invalid item type. Please provide a byte array." -ForegroundColor Red
                return
            }
        }
    }
    else {
        $type = $InputObject.GetType().Name
        Write-Host "Write-Bytes: Invalid input type: $type Please provide a string or byte array." -ForegroundColor Red
        return
    }

    # print the ruler
    $ruler = " " * (4 + $SectionSpacing)

    foreach ($i in 0..($lineLength - 1)) {
        $ruler += ("{0:X2}" -f $i) + " "
    }

    $ruler += (" " * ($SectionSpacing - 1))
    $ruler += "ASCII" + ("-" * ($lineLength * $LetterSpacing - 5))
    Write-Host $ruler -ForegroundColor Black -BackgroundColor $TableColor -NoNewline
    Write-Host ""

    $offset = 0

    for ($i = 0; $i -lt $ByteArray.Length; $i += $lineLength) {
        # print the offset
        $formattedOffset = "{0:X4}" -f $offset
        Write-Host -NoNewline "$formattedOffset" -ForegroundColor Black -BackgroundColor $TableColor
        $line = " " * $SectionSpacing

        # print the hexadecimal values
        for ($j = 0; $j -lt $lineLength; $j++) {
            if (($i + $j) -lt $ByteArray.Length) {
                $byte = $ByteArray[$i + $j]
                $formattedByte = "{0:X2}" -f $byte
                $line += "$formattedByte "
            }
            else {
                $line += "   "
            }
        }

        # align ASCII output column
        $line += (" " * ($SectionSpacing - 1))
        Write-Host $line -NoNewline

        $spaces = " " * ($LetterSpacing - 1)

        # print the ASCII representation
        for ($j = 0; $j -lt $lineLength; $j++) {
            if (($i + $j) -lt $ByteArray.Length) {
                $byte = $ByteArray[$i + $j]
                if (IsPrintable $byte) {
                    [char]$char = [char]$byte
                    Write-Host -NoNewline "$char"
                }
                elseif ($byte -eq 10) {
                    Write-Host "↲" -NoNewline -ForegroundColor DarkGray
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

function XOR {
    param(
        [byte[]] $A,
        [byte[]] $B
    )
    if ($A.Length -ne $B.Length) {
        throw "Byte arrays must match in length."
    }
    $out = New-Object byte[] $A.Length
    for ($i = 0; $i -lt $A.Length; $i++) {
        $out[$i] = $A[$i] -bxor $B[$i]
    }
    return $out
}

function PackInt {
    param (
        [int]$inputInt
    )
    return , [System.BitConverter]::GetBytes([System.Net.IPAddress]::HostToNetworkOrder($inputInt))
}

function UnpackInt {
    param (
        [byte[]]$inputBytes
    )
    return [System.Net.IPAddress]::NetworkToHostOrder([System.BitConverter]::ToInt32($inputBytes, 0))
}

function UnpackInt16 {
    param (
        [byte[]]$inputBytes
    )
    return [System.Net.IPAddress]::NetworkToHostOrder([System.BitConverter]::ToInt16($inputBytes, 0))
}

function PackString {
    param (
        $inputString
    )
    # magic comma
    return , [System.Text.Encoding]::UTF8.GetBytes($inputString)
}

function UnpackString {
    param (
        [byte[]]$inputBytes
    )
    return [System.Text.Encoding]::UTF8.GetString($inputBytes)
}

function ByteSlice {
    param (
        [byte[]]$data,
        [int]$start,
        [int]$length
    )
    $slice = New-Object byte[] $length

    [System.Array]::Copy($data, $start, $slice, 0, $length)
    
    return , $slice
}