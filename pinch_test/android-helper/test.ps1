$ErrorActionPreference = "Stop"

$helperRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pinchRoot = Split-Path -Parent $helperRoot
$jdkHome = Get-ChildItem (Join-Path $pinchRoot ".tooling\jdk") -Directory | Select-Object -First 1 -ExpandProperty FullName
$javac = Join-Path $jdkHome "bin\javac.exe"
$java = Join-Path $jdkHome "bin\java.exe"
$testClasses = Join-Path $helperRoot "build\test-classes"

New-Item -ItemType Directory -Force -Path $testClasses | Out-Null
$sources = @(
    (Join-Path $helperRoot "src\main\java\com\cocbot\pinchtest\PinchPlan.java"),
    (Join-Path $helperRoot "src\test\java\com\cocbot\pinchtest\PinchPlanTest.java")
)

& $javac -encoding UTF-8 -d $testClasses $sources
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $java -ea -cp $testClasses com.cocbot.pinchtest.PinchPlanTest
exit $LASTEXITCODE
