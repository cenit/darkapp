#!/usr/bin/env pwsh

# Copyright 2019, Stefano Sinigardi

$number_of_build_workers = 8
$vcpkg_fork = ""
$darknet_share_dir_outside_vcpkg = "..\darknet_cenit\share\darknet"
$install_prefix = "-DCMAKE_INSTALL_PREFIX=.."

$CMAKE_EXE = Get-Command cmake | Select-Object -ExpandProperty Definition
$NINJA_EXE = Get-Command ninja | Select-Object -ExpandProperty Definition

if (-Not $CMAKE_EXE) {
  throw "Could not find CMake, please install it"
}
else {
  Write-Host "Using CMake from ${CMAKE_EXE}"
}

if (-Not $NINJA_EXE) {
  throw "Could not find Ninja, please install it"
}
else {
  Write-Host "Using Ninja from ${NINJA_EXE}"
}

function getProgramFiles32bit() {
  $out = ${env:PROGRAMFILES(X86)}
  if ($null -eq $out) {
    $out = ${env:PROGRAMFILES}
  }

  if ($null -eq $out) {
    throw "Could not find [Program Files 32-bit]"
  }

  return $out
}

function getLatestVisualStudioWithDesktopWorkloadPath() {
  $programFiles = getProgramFiles32bit
  $vswhereExe = "$programFiles\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhereExe) {
    $output = & $vswhereExe -products * -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -format xml
    [xml]$asXml = $output
    foreach ($instance in $asXml.instances.instance) {
      $installationPath = $instance.InstallationPath -replace "\\$" # Remove potential trailing backslash
    }
    if (!$installationPath) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also partial installations" -ForegroundColor Yellow
      $output = & $vswhereExe -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationPath = $instance.InstallationPath -replace "\\$" # Remove potential trailing backslash
      }
    }
    if (!$installationPath) {
      Throw "Could not locate any installation of Visual Studio"
    }
  }
  else {
    Throw "Could not locate vswhere at $vswhereExe"
  }
  return $installationPath
}


function getLatestVisualStudioWithDesktopWorkloadVersion() {
  $programFiles = getProgramFiles32bit
  $vswhereExe = "$programFiles\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhereExe) {
    $output = & $vswhereExe -products * -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -format xml
    [xml]$asXml = $output
    foreach ($instance in $asXml.instances.instance) {
      $installationVersion = $instance.InstallationVersion
    }
    if (!$installationVersion) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also partial installations" -ForegroundColor Yellow
      $output = & $vswhereExe -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationVersion = $instance.installationVersion
      }
    }
    if (!$installationVersion) {
      Throw "Could not locate any installation of Visual Studio"
    }
  }
  else {
    Throw "Could not locate vswhere at $vswhereExe"
  }
  return $installationVersion
}


if ((Test-Path env:VCPKG_ROOT$vcpkg_fork)) {
  $vcpkg_path = "$env:VCPKG_ROOT$vcpkg_fork"
  Write-Host "Found vcpkg in VCPKG_ROOT"$vcpkg_fork": $vcpkg_path"
}
elseif ((Test-Path "${env:WORKSPACE}\vcpkg$vcpkg_fork")) {
  $vcpkg_path = "${env:WORKSPACE}\vcpkg$vcpkg_fork"
  $env:VCPKG_ROOT = "${env:WORKSPACE}\vcpkg$vcpkg_fork"
  Write-Host "Found vcpkg in WORKSPACE\vcpkg"$vcpkg_fork": $vcpkg_path"
}
else {
  Throw "darkapp could not find vcpkg!"
}

if ($null -eq $env:VCPKG_DEFAULT_TRIPLET) {
  Write-Host "No default triplet has been set-up for vcpkg. Defaulting to x64-windows" -ForegroundColor Yellow
  $vcpkg_triplet = "x64-windows"
}
else {
  $vcpkg_triplet = $env:VCPKG_DEFAULT_TRIPLET
}

if ($vcpkg_triplet -Match "x86") {
  Throw "darkapp is supported only in x64 builds!"
}

if ($null -eq (Get-Command "cl.exe" -ErrorAction SilentlyContinue)) {
  $vsfound = getLatestVisualStudioWithDesktopWorkloadPath
  Write-Host "Found VS in ${vsfound}"
  Push-Location "${vsfound}\Common7\Tools"
  cmd.exe /c "VsDevCmd.bat -arch=x64 & set" |
  ForEach-Object {
    if ($_ -match "=") {
      $v = $_.split("="); Set-Item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
    }
  }
  Pop-Location
  Write-Host "Visual Studio Command Prompt variables set" -ForegroundColor Yellow
}

$tokens = getLatestVisualStudioWithDesktopWorkloadVersion
$tokens = $tokens.split('.')
$generator = "Ninja"
Write-Host "Setting up environment to use CMake generator: $generator" -ForegroundColor Yellow

if ($null -eq (Get-Command "nvcc.exe" -ErrorAction SilentlyContinue)) {
  if (Test-Path env:CUDA_PATH) {
    $env:PATH += ";${env:CUDA_PATH}\bin"
    Write-Host "Found cuda in ${env:CUDA_PATH}" -ForegroundColor Yellow
  }
  else {
    Write-Host "Unable to find CUDA, if necessary please install it or define a CUDA_PATH env variable pointing to the install folder" -ForegroundColor Yellow
  }
}

if (Test-Path env:CUDA_PATH) {
  if (-Not(Test-Path env:CUDA_TOOLKIT_ROOT_DIR)) {
    $env:CUDA_TOOLKIT_ROOT_DIR = "${env:CUDA_PATH}"
    Write-Host "Added missing env variable CUDA_TOOLKIT_ROOT_DIR" -ForegroundColor Yellow
  }
  if (-Not(Test-Path env:CUDACXX)) {
    $env:CUDACXX = "${env:CUDA_PATH}\bin\nvcc.exe"
    Write-Host "Added missing env variable CUDACXX" -ForegroundColor Yellow
  }
}

if ($darknet_share_dir_outside_vcpkg) {
  $cmake_args = "-G `"$generator`" `"-DCMAKE_TOOLCHAIN_FILE=$vcpkg_path\scripts\buildsystems\vcpkg.cmake`" `"-DVCPKG_TARGET_TRIPLET=$vcpkg_triplet`" `"-DCMAKE_BUILD_TYPE=Release`" ${install_prefix} `"-DDarknet_DIR=$darknet_share_dir_outside_vcpkg`" .."
}
else {
  $cmake_args = "-G `"$generator`" `"-DCMAKE_TOOLCHAIN_FILE=$vcpkg_path\scripts\buildsystems\vcpkg.cmake`" `"-DVCPKG_TARGET_TRIPLET=$vcpkg_triplet`" `"-DCMAKE_BUILD_TYPE=Release`" ${install_prefix} .."
}

Write-Host "CMake args: $cmake_args"
New-Item -Path .\build_win_release -ItemType directory -Force
Set-Location build_win_release
Start-Process -NoNewWindow -Wait -FilePath $CMAKE_EXE -ArgumentList $cmake_args
Start-Process -NoNewWindow -Wait -FilePath $CMAKE_EXE -ArgumentList "--build . --config Release --parallel ${number_of_build_workers}"
Set-Location ..
