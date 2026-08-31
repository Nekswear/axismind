# build_release.ps1
# Скрипт для автоматического увеличения версии и сборки release
#
# Использование:
#   .\build_release.ps1              - интерактивный режим (с подсказками)
#   .\build_release.ps1 patch        - увеличить patch (1.0.0 -> 1.0.1)
#   .\build_release.ps1 minor        - увеличить minor (1.0.0 -> 1.1.0)
#   .\build_release.ps1 major        - увеличить major (1.0.0 -> 2.0.0)
#
# ⚠️ ВНИМАНИЕ: Все Firebase-ключи вынесены в --dart-define.
#    Перед сборкой убедитесь, что переменные окружения FIREBASE_* заданы,
#    или передайте их вручную. См. README.md для полного списка.

param(
    [ValidateSet('major', 'minor', 'patch', '')]
    [string]$Level = ''
)

$pubspecPath = "pubspec.yaml"
$versionInfoPath = "lib/core/version_info.dart"
$projectRoot = Get-Location

Write-Host "=== AxisMind Release Builder ===" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot" -ForegroundColor Gray

# --- 0. Интерактивный выбор уровня версии ---
if (-not $Level) {
    Write-Host "`nWhat type of changes did you make?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] PATCH  (1.0.0 -> 1.0.1)  - Bug fixes, small tweaks" -ForegroundColor Green
    Write-Host "       Examples: fixed a typo, changed a color, fixed a crash,"
    Write-Host "       improved performance, updated text"
    Write-Host ""
    Write-Host "  [2] MINOR  (1.0.0 -> 1.1.0)  - New features, new screens" -ForegroundColor Cyan
    Write-Host "       Examples: added a settings screen, new meditation mode,"
    Write-Host "       new statistics chart, new language support"
    Write-Host ""
    Write-Host "  [3] MAJOR  (1.0.0 -> 2.0.0)  - Big redesign, breaking changes" -ForegroundColor Magenta
    Write-Host "       Examples: completely new UI, changed database format,"
    Write-Host "       removed old features, major architecture change"
    Write-Host ""
    Write-Host "  [Q] Quit - cancel build" -ForegroundColor Gray
    Write-Host ""

    $choice = (Read-Host "Enter your choice (1, 2, 3, or Q)").Trim()

    switch ($choice) {
        '1' { $Level = 'patch' }
        '2' { $Level = 'minor' }
        '3' { $Level = 'major' }
        { $_ -eq 'q' -or $_ -eq 'Q' } { Write-Host "`nCancelled." -ForegroundColor Gray; exit 0 }
        default {
            Write-Host "`nInvalid choice. Using default: patch" -ForegroundColor Yellow
            $Level = 'patch'
        }
    }

    Write-Host "`nSelected: $Level" -ForegroundColor White
}

# --- 1. Читаем текущую версию из pubspec.yaml ---
Write-Host "`n[1/7] Reading current version from pubspec.yaml..." -ForegroundColor Yellow

$content = Get-Content $pubspecPath -Raw
$versionMatch = [regex]::Match($content, 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')

if (-not $versionMatch.Success) {
    Write-Host "ERROR: Could not find version string in pubspec.yaml" -ForegroundColor Red
    exit 1
}

$major = [int]$versionMatch.Groups[1].Value
$minor = [int]$versionMatch.Groups[2].Value
$patch = [int]$versionMatch.Groups[3].Value
$build = [int]$versionMatch.Groups[4].Value

Write-Host "  Current version: $major.$minor.$patch+$build" -ForegroundColor White

# --- 2. Увеличиваем версию ---
Write-Host "`n[2/7] Incrementing $Level version..." -ForegroundColor Yellow

switch ($Level) {
    'major' {
        $major++
        $minor = 0
        $patch = 0
    }
    'minor' {
        $minor++
        $patch = 0
    }
    'patch' {
        $patch++
    }
}
$build++

$newVersion = "$major.$minor.$patch+$build"
$newVersionDisplay = "$major.$minor.$patch"

Write-Host "  New version: $newVersion" -ForegroundColor Green

# --- 3. Обновляем pubspec.yaml ---
Write-Host "`n[3/7] Updating pubspec.yaml..." -ForegroundColor Yellow

$newContent = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
Set-Content $pubspecPath -Value $newContent -NoNewline

Write-Host "  pubspec.yaml updated successfully" -ForegroundColor Green

# --- 4. Обновляем version_info.dart ---
Write-Host "`n[4/7] Updating lib/core/version_info.dart..." -ForegroundColor Yellow

$versionInfoContent = Get-Content $versionInfoPath -Raw
$versionInfoContent = $versionInfoContent -replace "static const String version = '[\d.]+'", "static const String version = '$newVersionDisplay'"
$versionInfoContent = $versionInfoContent -replace "static const int buildNumber = \d+", "static const int buildNumber = $build"
Set-Content $versionInfoPath -Value $versionInfoContent -NoNewline

Write-Host "  version_info.dart updated successfully" -ForegroundColor Green

# --- 5. Формируем --dart-define из переменных окружения ---
Write-Host "`n[5/7] Resolving --dart-define values..." -ForegroundColor Yellow

# Список всех required dart-defines для Firebase
$firebaseDefines = @(
    'FIREBASE_ANDROID_API_KEY',
    'FIREBASE_ANDROID_APP_ID',
    'FIREBASE_IOS_API_KEY',
    'FIREBASE_IOS_APP_ID',
    'FIREBASE_WEB_API_KEY',
    'FIREBASE_WEB_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
    'FIREBASE_AUTH_DOMAIN',
    'FIREBASE_STORAGE_BUCKET',
    'FIREBASE_IOS_BUNDLE_ID',
    'FIREBASE_VAPID_KEY',
    'GOOGLE_SIGNIN_CLIENT_ID'
)

$dartDefineArgs = @()
$missingVars = @()

foreach ($define in $firebaseDefines) {
    $value = [Environment]::GetEnvironmentVariable($define)
    if ([string]::IsNullOrEmpty($value)) {
        $missingVars += $define
    } else {
        $dartDefineArgs += "--dart-define=$define=$value"
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "  WARNING: Missing environment variables:" -ForegroundColor Yellow
    foreach ($var in $missingVars) {
        Write-Host "    - $var" -ForegroundColor Yellow
    }
    Write-Host "  Build will FAIL if these are required at compile time." -ForegroundColor Yellow
    Write-Host "  Set them before running this script, e.g.:" -ForegroundColor Gray
    Write-Host "    `$env:FIREBASE_PROJECT_ID = 'axismind-app-295e3'" -ForegroundColor Gray
}

$dartDefineString = if ($dartDefineArgs.Count -gt 0) { "--release $($dartDefineArgs -join ' ')" } else { "--release" }

# --- 6. Сборка проекта ---
Write-Host "`n[6/7] Building Windows release..." -ForegroundColor Yellow

# Fix for CMake 4.x compatibility: Firebase SDK uses cmake_minimum_required(VERSION 3.5)
# which is no longer supported by CMake 4.x without this policy flag.
$env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
Write-Host "  Set CMAKE_POLICY_VERSION_MINIMUM=3.5 (CMake 4.x compatibility)" -ForegroundColor Gray

# Clean previous build artifacts to avoid stale file issues
$buildDir = "$projectRoot\build\windows"
if (Test-Path $buildDir) {
    Write-Host "  Cleaning previous build artifacts..." -ForegroundColor Gray
    Remove-Item -Path $buildDir -Recurse -Force
}

$buildCommand = "flutter build windows $dartDefineString"
Write-Host "  Running: $buildCommand" -ForegroundColor Gray

$buildOutput = Invoke-Expression $buildCommand 2>&1
$buildSuccess = $LASTEXITCODE -eq 0

if (-not $buildSuccess) {
    Write-Host "`nBUILD FAILED!" -ForegroundColor Red
    Write-Host $buildOutput -ForegroundColor Red
    exit 1
}

Write-Host "  Build completed successfully!" -ForegroundColor Green

# --- 7. Копируем с версией в имени ---
$sourceDir = "$projectRoot\build\windows\x64\runner\Release"
$outputDir = "$projectRoot\release_builds"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$exeName = "AxisMind_v$newVersionDisplay.exe"
$zipName = "AxisMind_v$newVersionDisplay.zip"

Write-Host "`n=== Build Summary ===" -ForegroundColor Cyan
Write-Host "  Version:        $newVersion" -ForegroundColor White
Write-Host "  Executable:     $sourceDir\axismind.exe" -ForegroundColor White
Write-Host "  Output folder:  $outputDir" -ForegroundColor White

# Копируем .exe с версией в имени
Copy-Item "$sourceDir\axismind.exe" "$outputDir\$exeName" -Force
Write-Host "  Copied:         $outputDir\$exeName" -ForegroundColor Green

# Создаём ZIP-архив со всеми файлами для portable-версии
Write-Host "`nCreating portable ZIP archive..." -ForegroundColor Yellow
Compress-Archive -Path "$sourceDir\*" -DestinationPath "$outputDir\$zipName" -Force
Write-Host "  Created:        $outputDir\$zipName" -ForegroundColor Green

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "New version $newVersion is ready!" -ForegroundColor Green
Write-Host "Output files:" -ForegroundColor White
Write-Host "  - $outputDir\$exeName" -ForegroundColor Gray
Write-Host "  - $outputDir\$zipName" -ForegroundColor Gray
Write-Host "To install on another PC, extract the ZIP or copy the Release folder." -ForegroundColor Gray
