# logic initially from @IISResetMe
# https://twitter.com/IISResetMe/status/1344395975020990472?s=20
function FibonacciCounter {
    param (
        [Parameter(Mandatory)]
        [int]$n
    )
    if ($n -eq 0) {
        return 0
    }
    elseif ($n -gt 0) {
        $t, $h = 0, 1 -as [bigint[]]
        while (--$n) {
            $t, $h = $h, ($t + $h)
        }
    }
    else {
        $t, $h = 0, -1 -as [bigint[]]
        while (++$n) {
            $t, $h = $h, ($t - $h)
        }
        $h = $h * -1
    }

    return $h
}