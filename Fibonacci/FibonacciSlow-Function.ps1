function FibinacciSlow ([Int]$n) {
    $result = switch ($n) {
        -2 { -1 ; break }
        -1 { 1 ; break }
        0 { 0 ; break }
        1 { 1 ; break }
        2 { 1 ; break }
        Default {
            $Position1 = FibinacciSlow ([Math]::Abs($n) - 1) $memo
            $Position2 = FibinacciSlow ([Math]::Abs($n) - 2) $memo
            $Position1 + $Position2
            break
        }
    }
    if (($n -lt 1) -and ($n % 2 -eq 0)) {
        $result = $result * -1
    }
    return $result
}