function Get-AgeInYears {
    param (
        [datetime]$BirthdayDate
    )
    
    [PSCustomObject]@{
        Years = (New-TimeSpan -End $BirthdayDate).Days / -365.25
    }
}