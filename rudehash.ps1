$Config = ConvertFrom-StringData(Get-Content "$PSScriptRoot/rudehash.properties" -raw)
$Tools = "$Env:USERPROFILE\tools"
$FirstRun = $true

$Coins =
@{
	"ZCL" = [pscustomobject]@{ PoolPage = "zclassic"; WtmPage = "167-zcl-equihash"; Server = "europe.equihash-hub.miningpoolhub.com"; Port = 20575}
	"ZEC" = [pscustomobject]@{ PoolPage = "zcash"; WtmPage = "166-zec-equihash"; Server = "europe.equihash-hub.miningpoolhub.com"; Port = 20570}
	"ZEN" = [pscustomobject]@{ PoolPage = "zencash"; WtmPage = "185-zen-equihash"; Server = "europe.equihash-hub.miningpoolhub.com"; Port = 20594}
}

function CalcProfit ()
{
	# API: https://github.com/miningpoolhub/php-mpos/wiki/API-Reference

	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getpoolstatus&api_key=" + $Config.ApiKey
	$PoolJson = Invoke-WebRequest -Uri $PoolUrl | ConvertFrom-Json
	$Difficulty = $PoolJson.getpoolstatus.data.networkdiff
	#$Difficulty = $PoolJson.getdashboarddata.data.network.difficulty
	#$HashRate = $PoolJson.getdashboarddata.data.personal.hashrate

	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=" + $Config.ApiKey
	$PoolJson = Invoke-WebRequest -Uri $PoolUrl | ConvertFrom-Json
	$PoolWorker = $PoolJson.getuserworkers.data | Where-Object -Property "username" -EQ -Value ($Config.User + "." + $Config.Worker)
	# getpoolstatus shows hashrate in H/s, getuserworkers uses kH/s, lovely!
	$HashRate = $PoolWorker.hashrate * 1000

	#$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=" + $HashRate + "&d=$Difficulty&p=" + $Config.Power + "&cost=" + $Config.ElectricityCost + "&fee=" + $Config.PoolFee + "&commit=Calculate"
	$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=$HashRate&d=$Difficulty&p=0&cost=0&fee=" + $Config.PoolFee + "&commit=Calculate"
	$WtmHtml = Invoke-WebRequest -Uri $WtmUrl
	$WtmObj = $WtmHtml.Content -split "[`r`n]"
	$LineNo = $WtmObj | Select-String -Pattern "Estimated Rewards" | Select-Object -ExpandProperty 'LineNumber'
	return ($WtmObj | Select-Object -Index ($LineNo + 56)).Trim()
}

function RunMiner ()
{
	# restart automatically if the miner crashes
	while (1)
	{
		$Args = "--server " + $Coins[$Config.Coin].Server + " --user " + $Config.User + "." + $Config.Worker + " --pass x --port " + $Coins[$Config.Coin].Port + " --api"

		if ($FirstRun -or $Proc.HasExited)
		{
			$Proc = Start-Process -FilePath "$Tools\zecminer\miner.exe" -ArgumentList $Args -PassThru -NoNewWindow
		}

		$EstProfit = CalcProfit
		#Clear-Host
		Write-Host -ForegroundColor Green -BackgroundColor DarkYellow "Current estimated income / day: $EstProfit"
		Start-Sleep -Seconds 60
		$FirstRun = $false
		#Register-EngineEvent PowerShell.Exiting –Action { Stop-Process $Proc }
		#$MinerStats = Send-Tcp localhost 42000 '{"id":1, "method":"getstat"}\n' 10
	}
}

RunMiner
#Stop-Process $Proc
