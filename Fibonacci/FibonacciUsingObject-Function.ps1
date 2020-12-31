# trying to create a version that uses an object instead of a hashtable
# does NOT work as implemented
function FibinacciUsingObject {
    param (
        [parameter(ValueFromPipeline)]
        [int]$Position,
        [int]$Sequence
    )

    begin {
        if (-not $memo) {
            $script:memo = [System.Collections.Generic.List[object]]::new()
        }
    }
    process {
        if ($Position -le 0) {
            return 0
        }
        elseif ($Position -le 2) {
            return 1
        }
        $memo.Add([PSCustomObject]@{
                Position = $Position
                Sequence = $(FibinacciUsingObject ($Position - 1) $memo) + $(FibinacciUsingObject ($Position - 2) $memo)
            })
        # $memo.Add($Position, $(FibinacciFaster ($Position - 1) $memo) + $(FibinacciFaster ($Position - 2) $memo))
        return $memo[$Position]
    } #end process
    end {}
}