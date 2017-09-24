param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$sitecoreRepositoryFolder  
)

Function Get-7z
{
    param(
        [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
        [Parameter(Mandatory=$true)][string]$installPath,
        [Parameter(Mandatory=$true)][string]$nugetFullPath
        )

        $zipFileLocation = "$installPath\packages\7-Zip.x64\tools\7z.exe"
        $zipFileLocation = $zipFileLocation.Replace("\\","\")
        if (!(Test-Path -Path $zipFileLocation))
        {
            $nugetArgs = ' install 7-Zip.x64 -ExcludeVersion -o "' + $installPath + '\packages" -Source "' + $NugetFeed + '"'
            $nugetCommand = "& '$nugetFullPath'" + $nugetArgs
            Write-Host "Installing 7-Zip.x64 nuget package to $installPath\packages ..." -ForegroundColor Green
            Invoke-Expression $nugetCommand -Verbose | Out-Null
            Write-Host "Done installing 7-Zip.x64 nuget package to $installPath\packages ..." -ForegroundColor Green
        }
        return $zipFileLocation
}

Function UnZipFiles 
{
    param(
        [Parameter(Mandatory=$true)][string]$installPath,
        [Parameter(Mandatory=$true)][string]$ArchivePath,  
        [Parameter(Mandatory=$true)][string]$TargetPath, 
        [switch]$SuppressOutput,
        [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
        [Parameter(Mandatory=$true)][string]$nugetFullPath,
        [switch]$doNotDeleteTargetPath
      )
      $deleteTargetPath = $true
      if($doNotDeleteTargetPath)
      {
          $deleteTargetPath = $false
      }
    
    if (!(Test-Path -Path $ArchivePath))
    {
      Write-Log -Message "The archive to extract was not found: $ArchivePath" -Level "Error"
    }
      
    if(($deleteTargetPath -eq $true) -and (Test-Path -Path $TargetPath ))
    {
      $child_items = ([array] (Get-ChildItem -Path $TargetPath -Recurse -Force))
          if ($child_items) 
          {
              #$null = $child_items | Remove-Item -Force -Recurse | Out-Nul
              foreach($child_item in $child_items)
              {
                  if(Test-Path -Path $child_item)
                  {
                      $null = Remove-Item $child_item -Force -Recurse | Out-Null
                  }       
              }
  
  
          }
          if(Test-Path -Path $TargetPath)
          {
              $null = Remove-Item $TargetPath -Force -Recurse | Out-Null
          }
    }
    
    if (!(Test-Path -Path $TargetPath))
    {
      New-Item -Path $TargetPath -ItemType directory | Out-Null
    }
    
    [string]$pathTo7z = $(Get-7z -installPath $installPath -nugetFullPath $nugetFullPath -NugetFeed $NugetFeed)
    $unzipargs = ' x "' + $ArchivePath + '" -o"' + $TargetPath + '" -y'
    $unzipcommand = "& '$pathTo7z'" + $unzipargs
  
    #Write-Log "$unzipcommand"
  
    if ($SuppressOutput)
    {
      # Write-Log -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
      Invoke-Expression $unzipcommand | Out-Null
      # Write-Log -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
    }
    else
    {
        Invoke-Expression $unzipcommand | Out-Null
    }  
  }

Clear-Host

$workingFolder = [System.IO.Path]::Combine($env:TEMP, [System.IO.DirectoryInfo]::new($sitecoreRepositoryFolder).Name)

if (!(Test-Path -Path $workingFolder))
{
    New-Item $workingFolder -type directory -Force | Out-Null
}

#$root = Split-Path -Parent $MyInvocation.MyCommand.Path

#Set-location -Path $root

if (!(Test-Path -Path "$workingFolder\nuget.exe" -PathType Leaf))
{
    $sourceNugetExe = "http://nuget.org/nuget.exe"
    Invoke-WebRequest $sourceNugetExe -OutFile "$workingFolder\nuget.exe"
}

if ((Test-Path -Path "$workingFolder\nuget.exe"))
{
    $nugetArgs = ' update -self -PreRelease'
    $nugetCommand = "& '"+"$workingFolder\nuget.exe"+"'" + $nugetArgs
    Invoke-Expression $nugetCommand -Verbose | Out-Null
    
}
if ((Test-Path -Path "$workingFolder\nuget.exe.old"))
{
    Remove-Item -Path "$workingFolder\nuget.exe.old" -Force
}

$nugetExecutable = $workingFolder + "\nuget.exe"

Get-ChildItem -Path $sitecoreRepositoryFolder -Filter "*.zip" | ForEach-Object {
    $sitecorezipFileNameOnly = $_.Name    
    $FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
    $archivePath = "$sitecoreRepositoryFolder$sitecorezipFileNameOnly"
    $targetDirectory = "$workingFolder\$FileNameNoExtension\"

    $SitecoreVersionWithRev = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(".zip","").Trim()

    $nugetExecutable = $workingFolder + "\nuget.exe"

    Write-Host $SitecoreVersionWithRev

    UnZipFiles -installPath $workingFolder `
        -ArchivePath $archivePath `
        -TargetPath $targetDirectory `
        -SuppressOutput `
        -nugetFullPath $nugetExecutable `
        -NugetFeed $NugetFeed

    $fileFilter = "(Sitecore.*\.(dll|exe)|maengine\.exe|XConnectSearchIndexer.exe)$"

    $xconnectServer = "Sitecore XConnect Server $SitecoreVersionWithRev\Website\bin"
    $MarketingAutomationService = "Sitecore Marketing Automation Service $SitecoreVersionWithRev\"
    $xconnectIndexingService = "Sitecore XConnect Index Service $SitecoreVersionWithRev\"
    $sitecorePlatform = "$FileNameNoExtension\Website\bin\"

    $directoriesToSearch = @("$targetDirectory$xconnectServer","$targetDirectory$MarketingAutomationService","$targetDirectory$xconnectIndexingService","$targetDirectory$sitecorePlatform")

    foreach($directoryToSearch in $directoriesToSearch)
    {
        if(Test-Path -Path $directoryToSearch)
        {
            $newTargetDirectory = $directoryToSearch
            $newTargetDirectoryInfo = [System.IO.DirectoryInfo]::new($newTargetDirectory)
            $newTargetDirectoryInfoName = $newTargetDirectoryInfo.Name
            if($newTargetDirectoryInfoName.ToLowerInvariant() -eq "bin")
            {
                $newTargetDirectoryInfoName = $newTargetDirectoryInfo.Parent.Name
            }

            if($newTargetDirectoryInfoName.ToLowerInvariant() -eq "website")
            {
                $newTargetDirectoryInfoName = $newTargetDirectoryInfo.Parent.Parent.Name
            }
            $assemblies=Get-ChildItem $newTargetDirectory | Where-Object {$_.Name.ToLower().EndsWith("dll")} | ForEach-Object {
                $assemblyName = [Reflection.AssemblyName]::GetAssemblyName($_.FullName)
                try {
                    $_ | Add-Member NoteProperty FileVersion ($_.VersionInfo.FileVersion)
                    $_ | Add-Member NoteProperty AssemblyVersion ($assemblyName.Version.ToString())
                    $_ | Add-Member NoteProperty AssemblyFullName ($assemblyName.FullName)
                    $_ | Add-Member NoteProperty AssemblyFileName ($_.Name)
                } catch {}
                $_
            }

            $nl = [Environment]::NewLine
            #BOF wrong sitecore references report definition
            $reportwrongSitecoreReferenceFileName = "wrong Sitecore references $newTargetDirectoryInfoName.txt"
            $reportwrongSitecoreReferenceFullFileName = [System.IO.Path]::Combine($sitecoreRepositoryFolder,$reportwrongSitecoreReferenceFileName)
            if(Test-Path -$reportwrongSitecoreReferenceFullFileName)
            {
                Remove-Item -Path $reportwrongSitecoreReferenceFullFileName -Force
            }
            #EOF wrong sitecore references report definition

            $wrongReferencesReportLine = ""
            Get-ChildItem $newTargetDirectory -rec | Where-Object {$_.Name -match $fileFilter} | ForEach-Object {
                $original = [io.path]::GetFileName($_.FullName)
                $bytes   = [System.IO.File]::ReadAllBytes($_.FullName)
                $loaded  = [System.Reflection.Assembly]::Load($bytes)
                
                # Check for correct referenced Sitecore version
                $loaded.GetReferencedAssemblies() | ForEach-Object {
                    if($_.FullName.ToLower().StartsWith("sitecore"))
                    {
                        $matchValue = $_.Name
                        $assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName) -match "$matchValue.dll"
                        if($assembly -ne $null)
                        {
                            if($_.Version -ne $assembly.AssemblyVersion)
                            {
                                if([string]::IsNullOrEmpty($wrongReferencesReportLine))
                                {
                                    $wrongReferencesReportLine = "Assembly with wrong reference, Wrong referenced assembly, wrong referenced version, correct referenced version$nl"
                                }
                                $wrongSitecoreReferenceName = $_.Name
                                $wrongSitecoreReferenceVersion = $_.Version
                                $wrongSitecoreReferenceOriginal = $original
                                $wrongSitecoreReferenceShouldBe = $assembly.AssemblyVersion
                                $wrongReferencesReportLine = $wrongReferencesReportLine + "$wrongSitecoreReferenceOriginal, $wrongSitecoreReferenceName, $wrongSitecoreReferenceVersion, $wrongSitecoreReferenceShouldBe$nl"
                            }
                        }
                    }
                    if($loaded -ne $null)
                    {
                        $loaded = $null
                    }
                }
            }
            if(![string]::IsNullOrEmpty($wrongReferencesReportLine))
            {
                $wrongReferencesReportLine | Out-File -FilePath $reportwrongSitecoreReferenceFullFileName -Enc "UTF8"
            }
        }
    }

    $workingFolderPackage = [System.IO.Path]::Combine($workingFolder, "packages")

    if(Test-Path -Path $workingFolderPackage)
    {
        Remove-Item -Path $workingFolderPackage -Recurse -Force 
    }

    if(Test-Path -Path $targetDirectory)
    {
        Remove-Item -Path $targetDirectory -Recurse -Force 
    }

    if(Test-Path -Path $nugetExecutable)
    {
        Remove-Item $nugetExecutable -Force
    }

    if(Test-Path -Path $workingFolder)
    {
        Remove-Item -Path $workingFolder -Recurse -Force 
    }
}