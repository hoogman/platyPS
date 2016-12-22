# script to create the final package in out\platyPS

param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = "Debug"
)

# build .dll
# msbuild is part of .NET Framework, we can try to get it from well-known location.
if (-not (Get-Command -Name msbuild -ErrorAction Ignore)) {
    Write-Warning "Appending probable msbuild path"
    $env:path += ";${env:SystemRoot}\Microsoft.Net\Framework\v4.0.30319"
}

msbuild Markdown.MAML.sln /p:Configuration=$Configuration
$assemblyPath = (Resolve-Path "src\Markdown.MAML\bin\$Configuration\Markdown.MAML.dll").Path

# copy artifacts
New-Item -Type Directory out -ErrorAction SilentlyContinue > $null
Copy-Item -Rec -Force src\platyPS out
if (-not (Test-Path out\platyPS\Markdown.MAML.dll) -or 
    (Get-ChildItem out\platyPS\Markdown.MAML.dll).LastWriteTime -lt (Get-ChildItem $assemblyPath).LastWriteTime)
{
    Copy-Item $assemblyPath out\platyPS
} else {
    Write-Host -Foreground Yellow 'Skip Markdown.MAML.dll copying'
}

# copy schema file and docs
Copy-Item .\platyPS.schema.md out\platyPS
New-Item -Type Directory out\platyPS\docs -ErrorAction SilentlyContinue > $null
Copy-Item .\docs\* out\platyPS\docs\

# copy template files
New-Item -Type Directory out\platyPS\templates -ErrorAction SilentlyContinue > $null
Copy-Item .\templates\* out\platyps\templates\

# put the right module version
if ($env:APPVEYOR_REPO_TAG_NAME)
{
    $manifest = cat -raw out\platyPS\platyPS.psd1
    $manifest = $manifest -replace "ModuleVersion = '0.0.1'", "ModuleVersion = '$($env:APPVEYOR_REPO_TAG_NAME)'"
    Set-Content -Value $manifest -Path out\platyPS\platyPS.psd1 -Encoding Ascii
}

# dogfooding: generate help for the module
Remove-Module platyPS -ErrorAction SilentlyContinue
Import-Module $pwd\out\platyPS
#New-ExternalHelp docs -OutputPath out\platyPS\en-US -Force

# reload module, to apply generated help
Import-Module $pwd\out\platyPS -Force
