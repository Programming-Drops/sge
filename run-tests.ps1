param(
  [string]$FpcPath = "D:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestOutputDir = Join-Path $ProjectRoot "bin\tests"
$TestRunner = Join-Path $ProjectRoot "tests\test_runner.lpr"
$TestExe = Join-Path $TestOutputDir "test_runner.exe"

if (-not (Test-Path $FpcPath)) {
  throw "Compilador FPC nao encontrado em: $FpcPath"
}

if (-not (Test-Path $TestRunner)) {
  throw "Runner de testes nao encontrado em: $TestRunner"
}

New-Item -ItemType Directory -Force -Path $TestOutputDir | Out-Null

& $FpcPath `
  -MObjFPC `
  "-Fu$(Join-Path $ProjectRoot 'src\units')" `
  "-Fu$(Join-Path $ProjectRoot 'tests')" `
  "-FE$TestOutputDir" `
  "-FU$TestOutputDir" `
  $TestRunner

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& $TestExe
exit $LASTEXITCODE
