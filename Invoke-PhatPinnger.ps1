Param(
    [Parameter(Position=0,mandatory=$true)]
    [string]$ComputerName
)

$Buffer = 0
$BufferBonus = 1
$RunningTest = $True
$PingCounter = 0

Write-Host "Starting Bandwith test for: $ComputerName"

While($RunningTest){ 
    Write-Progress -Activity "Pings: $PingCounter" -Status "Buffer: $Buffer" -PercentComplete $($Buffer/65535*100) -Id 1
    If(Test-Connection -ComputerName $ComputerName -BufferSize $Buffer -Count 1 -Quiet){
        $Buffer += $BufferBonus 
        $BufferBonus += 1
        $PingCounter += 1
        if($Buffer -gt 65501){
            $Buffer = 65500
            $BufferBonus = 0
        }ElseIf($Buffer -eq 65500){
            $RunningTest = $False
        }
    }else{
        Write-Warning "Pactet Loss Detected $BufferBonus"
        If($BufferBonus -ne 1){
            $Buffer -= $BufferBonus 
            $BufferBonus = 0
        }else{
            $RunningTest = $False
        }
    }
}
Write-Progress -Activity "Pings: $PingCounter" -Status "Buffer: $Buffer" -Completed -Id 1
Write-Host "Test completed with $PingCounter sucessful PING's"
if($Buffer -ge 65500){
    Write-Host -ForegroundColor Green "Max Buffer size of $Buffer Bytes verified"
}else{
    Write-Host -ForegroundColor Red "Buffer size topped out at $Buffer of 65530 Bytes"
}

$Payload = 0
$StartTime = Get-Date
While($PingCounter -gt 0){
    If(Test-Connection -ComputerName $ComputerName -BufferSize $Buffer -Count 1 -Quiet){
        $Payload += $Buffer
        $PingCounter -= 1
    }ElseIf($Buffer -gt 2){
        $Buffer -= 1
    }else{
        Write-Warning "Connection Unstable. Unable to determine connection speed"
    }
}
$RunTime = New-TimeSpan -Start $StartTime -End $(get-date)
$Speed = [MATH]::Round($($Payload * 8 / $RunTime.TotalSeconds ) / 10000) / 100
Write-Host -ForegroundColor Green "Speed: $Speed MBPS"