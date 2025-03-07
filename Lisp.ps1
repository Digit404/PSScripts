function def {
    param(
        [Parameter(Mandatory = $true)]
        [string]$name,

        [Parameter(Mandatory = $true)]
        [ScriptBlock]$script
    )

    $literalPath = "Function:\script:$($name)"
    Set-Item -LiteralPath $literalPath -Value $script -Force
}

def - {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a - $b
}

def + {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a + $b
}

def * {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a * $b
}

def / {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a / $b
}

def % {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a % $b
}

def = {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a -eq $b
}

def != {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a -ne $b
}

def lt {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a -lt $b
}

def gt {
    param (
        [Parameter(Mandatory = $true)]
        [int]$a,
        [Parameter(Mandatory = $true)]
        [int]$b
    )

    $a -gt $b
}

def and {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$a,
        [Parameter(Mandatory = $true)]
        [bool]$b
    )

    $a -and $b
}

def or {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$a,
        [Parameter(Mandatory = $true)]
        [bool]$b
    )

    $a -or $b
}

def not {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$a
    )

    -not $a
}

def cond {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$condition,
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$then,
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$else
    )

    if ($condition) {
        & $then
    }
    else {
        & $else
    }
}

def lambda {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$script
    )
    [ScriptBlock]::Create($script.ToString())
}

def cons {
    param (
        [Parameter(Mandatory = $true)]
        $head,

        [Parameter(Mandatory = $true)]
        $tail
    )

    , $head + $tail
}
 
def list {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        $items
    )

    $items
}

def atom {
    param (
        [Parameter(Mandatory = $true)]
        $value
    )

    $value -isnot [System.Collections.IEnumerable] 
}

# instead of def you can use "set" or "assign" and call functions like &$functionName
# for vars you can just use "set" or "assign"

Set-Alias assign Set-Variable
Set-Alias let Set-Variable
Set-Alias defun def