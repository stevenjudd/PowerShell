# logic initially from @IrwinStrachan 
# https://twitter.com/IrwinStrachan/status/1344176660183179265?s=20
function FibinacciFast ([Int]$n, [hashtable]$memo = @{}) {
    if ($memo.Keys -contains $n) {
        return $memo[$n]
    }
    $result = switch ($n) {
        -2 { -1 ; break }
        -1 { 1 ; break }
        0 { 0 ; break }
        1 { 1 ; break }
        2 { 1 ; break }
        Default {
            $Position1 = FibinacciFast ([Math]::Abs($n) - 1) $memo
            $Position2 = FibinacciFast ([Math]::Abs($n) - 2) $memo
            $memo.Add($n, $Position1 + $Position2)
            $memo[$n]
            break
        }
    }
    if (($n -lt 1) -and ($n % 2 -eq 0)) {
        $result = $result * -1
    }
    return $result
}