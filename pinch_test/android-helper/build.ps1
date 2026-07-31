$ErrorActionPreference = "Stop"

$helperRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pinchRoot = Split-Path -Parent $helperRoot
$toolRoot = Join-Path $pinchRoot ".tooling"
$bundledJdk = Get-ChildItem (Join-Path $toolRoot "jdk") -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$androidStudioJdk = "C:\Program Files\Android\Android Studio\jbr"
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\javac.exe"))) {
    $jdkHome = $env:JAVA_HOME
} elseif (Test-Path (Join-Path $androidStudioJdk "bin\javac.exe")) {
    $jdkHome = $androidStudioJdk
} elseif ($bundledJdk) {
    $jdkHome = $bundledJdk
} else {
    throw "A JDK with javac.exe is required. Install Android Studio or set JAVA_HOME."
}

$sdkRootCandidates = @(
    $env:ANDROID_SDK_ROOT,
    $env:ANDROID_HOME,
    (Join-Path $env:LOCALAPPDATA "Android\Sdk"),
    (Join-Path $toolRoot "android-sdk")
)
$sdkRoot = $sdkRootCandidates | Where-Object {
    $_ -and (Test-Path (Join-Path $_ "platforms\android-36.1\android.jar"))
} | Select-Object -First 1
if (!$sdkRoot) {
    throw "Android API 36.1 is missing. Install it from Android Studio's SDK Manager."
}
$buildTools = Join-Path $sdkRoot "build-tools\36.0.0"
$androidJar = Join-Path $sdkRoot "platforms\android-36.1\android.jar"
$targetManifest = Join-Path $helperRoot "target\AndroidManifest.xml"
$instrumentationManifest = Join-Path $helperRoot "instrumentation\AndroidManifest.xml"
$mainSourceRoot = Join-Path $helperRoot "src\main\java"
$buildRoot = Join-Path $helperRoot "build\apk"
$classesRoot = Join-Path $buildRoot "classes"
$dexRoot = Join-Path $buildRoot "dex"
$distRoot = Join-Path $pinchRoot "dist"
$signingRoot = Join-Path $helperRoot ".signing"
$keystore = Join-Path $signingRoot "debug.keystore"

if (!(Test-Path $targetManifest)) {
    throw "Target manifest is missing: $targetManifest"
}
if (!(Test-Path $instrumentationManifest)) {
    throw "Instrumentation manifest is missing: $instrumentationManifest"
}
if (!(Test-Path $androidJar)) {
    throw "Android API 36.1 is missing at $androidJar."
}
if (!(Test-Path (Join-Path $buildTools "aapt.exe"))) {
    throw "Android Build-Tools 36.0.0 is missing at $buildTools."
}

$resolvedHelperRoot = (Resolve-Path $helperRoot).Path
$resolvedBuildRoot = [System.IO.Path]::GetFullPath($buildRoot)
if (!$resolvedBuildRoot.StartsWith(
    $resolvedHelperRoot + "\",
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing to clean a build path outside android-helper."
}
if (Test-Path $buildRoot) {
    Remove-Item -LiteralPath $buildRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $classesRoot, $dexRoot, $distRoot, $signingRoot | Out-Null

$javac = Join-Path $jdkHome "bin\javac.exe"
$jar = Join-Path $jdkHome "bin\jar.exe"
$keytool = Join-Path $jdkHome "bin\keytool.exe"
$d8 = Join-Path $buildTools "d8.bat"
$aapt = Join-Path $buildTools "aapt.exe"
$zipalign = Join-Path $buildTools "zipalign.exe"
$apksigner = Join-Path $buildTools "apksigner.bat"

$androidCompileJar = Join-Path $buildRoot "android.jar"
$classesJar = Join-Path $buildRoot "pinch-classes.jar"
Copy-Item -LiteralPath $androidJar -Destination $androidCompileJar

$sources = Get-ChildItem $mainSourceRoot -Recurse -Filter *.java | Select-Object -ExpandProperty FullName
& $javac -encoding UTF-8 --release 8 -classpath $androidCompileJar -d $classesRoot $sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (!(Test-Path (Join-Path $classesRoot "com\cocbot\pinchtest\PinchInstrumentation.class"))) {
    throw "javac did not produce PinchInstrumentation.class."
}

& $jar --create --file $classesJar -C $classesRoot .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$env:JAVA_HOME = $jdkHome
& $d8 --min-api 18 --lib $androidCompileJar --output $dexRoot $classesJar
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$targetUnsigned = Join-Path $buildRoot "pinch-target-unsigned.apk"
$targetAligned = Join-Path $buildRoot "pinch-target-aligned.apk"
$instrumentationUnsigned = Join-Path $buildRoot "pinch-instrumentation-unsigned.apk"
$instrumentationAligned = Join-Path $buildRoot "pinch-instrumentation-aligned.apk"

& $aapt package -f -M $targetManifest -I $androidCompileJar -F $targetUnsigned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Push-Location $dexRoot
try {
    & $aapt add $targetUnsigned "classes.dex"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

& $aapt package -f -M $instrumentationManifest -I $androidCompileJar -F $instrumentationUnsigned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Push-Location $dexRoot
try {
    & $aapt add $instrumentationUnsigned "classes.dex"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

& $zipalign -f 4 $targetUnsigned $targetAligned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $zipalign -f 4 $instrumentationUnsigned $instrumentationAligned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (!(Test-Path $keystore)) {
    & $keytool -genkeypair -keystore $keystore -storepass android -keypass android -alias pinchtest -dname "CN=Pinch Test, O=Local Development, C=US" -keyalg RSA -keysize 2048 -validity 10000
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$targetApk = Join-Path $distRoot "pinch-target.apk"
$instrumentationApk = Join-Path $distRoot "pinch-instrumentation.apk"
& $apksigner sign --v4-signing-enabled false --ks $keystore --ks-key-alias pinchtest --ks-pass pass:android --key-pass pass:android --out $targetApk $targetAligned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $apksigner sign --v4-signing-enabled false --ks $keystore --ks-key-alias pinchtest --ks-pass pass:android --key-pass pass:android --out $instrumentationApk $instrumentationAligned
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $apksigner verify --verbose $targetApk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $apksigner verify --verbose $instrumentationApk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Built $targetApk"
Write-Host "Built $instrumentationApk"
