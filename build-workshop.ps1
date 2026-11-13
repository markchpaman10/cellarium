param(
 [string]$Runtime = 'C:\Program Files\LOVE',
 [string]$Destination = (Join-Path $PSScriptRoot '..\..\outputs\Cellarium-Cell-Workshop')
)
$ErrorActionPreference='Stop'
$Destination=[System.IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force $Destination | Out-Null
Copy-Item (Join-Path $Runtime '*.dll') $Destination
Copy-Item (Join-Path $Runtime 'license.txt') (Join-Path $Destination 'runtime-license.txt')
Copy-Item (Join-Path $Runtime 'readme.txt') (Join-Path $Destination 'runtime-readme.txt')
$archive=Join-Path $Destination 'Cellarium-Cell-Workshop.love'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream=[System.IO.File]::Create($archive)
$zip=[System.IO.Compression.ZipArchive]::new($stream,[System.IO.Compression.ZipArchiveMode]::Create)
try {
 foreach($file in Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*.lua') {
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$file.Name,[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
 }
} finally { $zip.Dispose();$stream.Dispose() }
$executable=Join-Path $Destination 'Cellarium-Cell-Workshop.exe'
$output=[System.IO.File]::Create($executable)
try {
 foreach($path in @((Join-Path $Runtime 'love.exe'),$archive)) {
  $inputStream=[System.IO.File]::OpenRead($path)
  try { $inputStream.CopyTo($output) } finally { $inputStream.Dispose() }
 }
} finally { $output.Dispose() }
foreach($name in @('README.md','DESKTOP-IMPLEMENTATION.md','desktop-test-results.txt','anatomy-test-results.txt','ANATOMY-REPORT.md','RECONSTRUCTION-REPORT.md','reconstruction-test-results.txt','CELL-WORKSHOP-REPORT.md','workshop-test-results.txt')) { $path=Join-Path $PSScriptRoot $name;if(Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $Destination } }
$docs=Join-Path $PSScriptRoot 'docs'
if(Test-Path -LiteralPath $docs) { Copy-Item -LiteralPath $docs -Destination $Destination -Recurse -Force }
Get-FileHash -Algorithm SHA256 $executable,$archive | Format-Table -AutoSize
