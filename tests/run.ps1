# Build the bridge in test mode with the csc.exe that ships with Windows
# and run it against a fake Discord. Needs Python 3.
#
#   powershell -ExecutionPolicy Bypass -File tests\run.ps1

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$src = Join-Path $here '..\DiscordRPC\DrpcBridge.cs'
$work = Join-Path ([IO.Path]::GetTempPath()) ("drpc-tests-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$control = Join-Path $work 'control'
$log = Join-Path $work 'log.jsonl'
$port = 46300

# skip the "get Python from the Store" stubs in WindowsApps
$python = Get-Command python3, python, py -CommandType Application -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1 -ExpandProperty Source
if (-not $python) { throw 'Python 3 is needed for the fake Discord.' }

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }

$status = 0
$server = $null
try {
    # the same build drpc.m does, warnings as errors
    & $csc /nologo /warnaserror /target:library /optimize+ /r:System.Core.dll "/out:$work\bridge.dll" $src
    if ($LASTEXITCODE -ne 0) { throw 'The bridge does not compile.' }
    & $csc /nologo /define:DRPC_TCP_TEST /r:System.Core.dll "/out:$work\tests.exe" $src (Join-Path $here 'BridgeTests.cs')
    if ($LASTEXITCODE -ne 0) { throw 'The tests do not compile.' }

    & "$work\tests.exe" $port $control offline
    if ($LASTEXITCODE -ne 0) { $status = 1 }

    Set-Content -Path $control -Value '' -NoNewline
    $server = Start-Process -FilePath $python -ArgumentList @("`"$here\fake_discord.py`"", $port, "`"$log`"", "`"$control`"") -PassThru -NoNewWindow
    Start-Sleep -Milliseconds 800

    & "$work\tests.exe" $port $control main
    if ($LASTEXITCODE -ne 0) { $status = 1 }
    & "$work\tests.exe" $port $control badid
    if ($LASTEXITCODE -ne 0) { $status = 1 }

    Set-Content -Path $control -Value 'quit' -NoNewline
    $server.WaitForExit(5000) | Out-Null

    & $python (Join-Path $here 'check_log.py') $log
    if ($LASTEXITCODE -ne 0) { $status = 1 }
}
finally {
    if ($server -and -not $server.HasExited) { $server.Kill() }
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
exit $status
