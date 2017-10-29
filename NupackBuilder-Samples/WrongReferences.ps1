param
(
    [Parameter(Mandatory=$true,helpmessage="The zip file to analyze")][ValidateNotNullOrEmpty()][string]$sitecoreZipFile,
    [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
    [Parameter(Mandatory=$false,helpmessage="Folder to save reports in")][string]$reportoutputfolder = ""
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

Function Set-ExitCode {
    param(
        [Parameter(Mandatory = $true, helpmessage = "The value to set the exit code to")]
        [ValidateNotNullOrEmpty()]
        [string]$ErrorCode
    )

    $arguments = " /c exit $errorCode"
    $command = "cmd.exe" + $arguments
    Invoke-Expression $command
}

Function Invoke-Robocopy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,helpmessage="The arguments for Robocopy")]
        [ValidateNotNullOrEmpty()]
        [string]$RobocopyArgs,
        [Parameter(Mandatory=$false,helpmessage="Verbosity string.")]
        [string]$Verbosity = "quiet"
    )

	$command = "robocopy.exe" + $robocopyArgs
    if(($Verbosity.ToLower() -eq "normal") -or ($Verbosity.ToLower() -eq "detailed"))
    {
        Write-Host "calling robocopy with the command : $command"
	}
    Invoke-Expression $command | out-null
	
	# Check exit code
	If (($LASTEXITCODE -eq 0)) {
		$RoboCopyMessage = "ROBOCOPY EXITCODE: $LASTEXITCODE, Succeeded"
        if(($Verbosity.ToLower() -eq "normal") -or ($Verbosity.ToLower() -eq "detailed"))
        {            
		    Write-Host $RoboCopyMessage -ForegroundColor Green
        }
		Set-ExitCode -ErrorCode "0"
	} elseif (($LASTEXITCODE -gt 0) -and ($LASTEXITCODE -lt 16)) {
		$RoboCopyMessage = "ROBOCOPY EXITCODE: $LASTEXITCODE, Warning"
        if(($Verbosity.ToLower() -eq "normal") -or ($Verbosity.ToLower() -eq "detailed"))
        {
		    Write-Host $RoboCopyMessage -ForegroundColor Yellow
        }
		Set-ExitCode -ErrorCode "0"
	} elseif ($LASTEXITCODE -eq 16) {
		$RoboCopyMessage = "ROBOCOPY EXITCODE: $LASTEXITCODE, Error"
		Write-Host $RoboCopyMessage -ForegroundColor Red
		Set-ExitCode -ErrorCode "-1"
	} else {
		$RoboCopyMessage = "Robocopy did not run"
		Write-Host $RoboCopyMessage -ForegroundColor Red
		Set-ExitCode -ErrorCode "-1"
	}
}

Function Remove-PathToLongDirectory {
    [CmdletBinding()]
	param(
        [ValidateNotNullOrEmpty()]
        [alias("directory")]
		[string]$Path
	)

	# create a temporary (empty) directory
    $parent = [System.IO.Path]::GetTempPath()
	[string] $name = [System.Guid]::NewGuid()
	$tempDirectory = New-Item -ItemType Directory -Path (Join-Path $parent $name)

	$tempDirectoryFullName = $tempDirectory.FullName
    $datestamp = get-date -Format yyyyMMddHHmmss
    $logfile = "$env:TEMP\robocopy_$datestamp.log"

    if(Test-Path $logfile) {
        Remove-Item -Path "$logfile" -Force | out-null
    }

	$robocopyArgs = " `"$tempDirectoryFullName`" `"$Path`" /MIR /R:3 /W:3 /MT:32 /NFL /NDL /NJH /NJS /nc /ns /np /LOG:`"$logfile`""
	Invoke-Robocopy -robocopyArgs $robocopyArgs
    if(Test-Path $logfile) { Remove-Item -Path "$logfile" -Force }
    if(Test-Path $Path) { Remove-Item $Path -Force -Recurse }
    if(Test-Path $tempDirectory) { Remove-Item $tempDirectory -Force -Recurse }
}

Function Get-PublicKeyToken
{
    param(
        [byte[]] $bytePublicKeyToken
    )
    [string]$pbt = ""
    if($bytePublicKeyToken -ne $null)
    {
        for ([int] $i=0;$i -le $bytePublicKeyToken.GetLength(0);$i++)
        {
            if($i -ne $null -and $bytePublicKeyToken -ne $null)
            { 
                $tempByte = $bytePublicKeyToken[$i]
                if ($tempByte -ne $null)
                {
                    $pbt += [string]::format("{0:x2}", $bytePublicKeyToken[$i])
                }
            }
        }
    }
    if([string]::IsNullOrEmpty($pbt))
    {
        $pbt = "null"
    }
    return $pbt
}

Function Get-MonoCecil
{
    param(
        [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
        [Parameter(Mandatory=$true)][string]$installPath,
        [Parameter(Mandatory=$true)][string]$nugetFullPath
        )

        $MonoCecilLocation = "$installPath\packages\Mono.Cecil\lib\net45\Mono.Cecil.dll"
        $MonoCecilLocation = $MonoCecilLocation.Replace("\\","\")
        if (!(Test-Path -Path $MonoCecilLocation))
        {
            $nugetArgs = ' install Mono.Cecil -ExcludeVersion -o "' + $installPath + '\packages" -Source "' + $NugetFeed + '"'
            $nugetCommand = "& '$nugetFullPath'" + $nugetArgs
            Write-Host "Installing Mono.Cecil nuget package to $installPath\packages ..." -ForegroundColor Green
            Invoke-Expression $nugetCommand -Verbose | Out-Null
            Write-Host "Done installing Mono.Cecil nuget package to $installPath\packages ..." -ForegroundColor Green
        }
        return $MonoCecilLocation
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
      Write-Error -Message "The archive to extract was not found: $ArchivePath"
      exit(-1)
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
  
    #Write-Host "$unzipcommand"
  
    if ($SuppressOutput)
    {
      # Write-Host -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
      Invoke-Expression $unzipcommand | Out-Null
      # Write-Host -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
    }
    else
    {
        Invoke-Expression $unzipcommand | Out-Null
    }  
  }

Clear-Host

if(!(Test-Path -Path $sitecoreZipFile))
{
    Write-Error "The zip file does not exist at : $sitecoreZipFile"
    exit -1
}
$zipFileInfo = [System.IO.FileInfo]::new($sitecoreZipFile)

$sitecoreRepositoryFolder = $zipFileInfo.DirectoryName

$workingFolder = [System.IO.Path]::Combine($env:TEMP, [System.IO.DirectoryInfo]::new($sitecoreRepositoryFolder).Name)

if([string]::IsNullOrEmpty($reportoutputfolder))
{
    $reportoutputfolder = $sitecoreRepositoryFolder
}
elseif (!([System.IO.Directory]::Exists($reportoutputfolder))) {
    $reportoutputfolder = $sitecoreRepositoryFolder
}

if (!(Test-Path -Path $workingFolder))
{
    New-Item $workingFolder -type directory -Force | Out-Null
}

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

$nugetExecutable = [System.IO.Path]::Combine($workingFolder,"nuget.exe")
$sitecorezipFileNameOnly = [System.IO.Path]::GetFileName($sitecoreZipFile)
$FileNameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
$archivePath = $sitecoreZipFile
$targetDirectory = [System.IO.Path]::Combine($workingFolder,$FileNameNoExtension)
$SitecoreVersionWithRev = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(".zip","").Trim()

$MonoCecil = Get-MonoCecil -installPath $workingFolder -nugetFullPath $nugetExecutable -NugetFeed $NugetFeed

$MonoCecilBytes = [System.IO.File]::ReadAllBytes($MonoCecil)
$MonoCecilLoaded  = [System.Reflection.Assembly]::Load($MonoCecilBytes)


Write-Host $SitecoreVersionWithRev

UnZipFiles -installPath $workingFolder `
    -ArchivePath $archivePath `
    -TargetPath $targetDirectory `
    -SuppressOutput `
    -nugetFullPath $nugetExecutable `
    -NugetFeed $NugetFeed

$fileFilter = "(Sitecore.*\.(dll|exe)|maengine\.exe|XConnectSearchIndexer.exe)$"

$xconnectServer = [System.IO.Path]::Combine($targetDirectory, "Sitecore XConnect Server $SitecoreVersionWithRev","Website","bin")
$MarketingAutomationService = [System.IO.Path]::Combine($targetDirectory, "Sitecore Marketing Automation Service $SitecoreVersionWithRev")
$xconnectIndexingService = [System.IO.Path]::Combine($targetDirectory, "Sitecore XConnect Index Service $SitecoreVersionWithRev")
$sitecorePlatform = [System.IO.Path]::Combine($targetDirectory, "$FileNameNoExtension","Website","bin")

$directoriesToSearch = @($xconnectServer,$MarketingAutomationService,$xconnectIndexingService,$sitecorePlatform)

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
            $assemblyDefinition = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($_.FullName)
            $assemblyNameReference = [Mono.Cecil.AssemblyNameReference]::Parse($assemblyDefinition.FullName)
            [byte[]] $assemblybytePublicKeyToken = $assemblyNameReference.PublicKeyToken
            $publicKeyToken = Get-PublicKeyToken -bytePublicKeyToken $assemblybytePublicKeyToken
            
            $cultureName = ""
            if ([string]::IsNullOrEmpty($assemblyNameReference.Culture)) 
            { 
                $cultureName = "neutral" 
            }
            else
            {
                $cultureName = $assemblyNameReference.Culture
            }
            $_ | Add-Member NoteProperty FileVersion ($_.VersionInfo.FileVersion)
            $_ | Add-Member NoteProperty AssemblyVersion ($assemblyNameReference.Version.ToString())
            $_ | Add-Member NoteProperty AssemblyFullName ($assemblyNameReference.FullName)
            $_ | Add-Member NoteProperty AssemblyFileName ($_.Name)
            $_ | Add-Member NoteProperty PublicKeyToken ($publicKeyToken)
            $_ | Add-Member NoteProperty CultureName ($cultureName)
            $_
        }

        $nl = [Environment]::NewLine
        
        #BOF wrong sitecore references report definition
        $reportwrongSitecoreReferenceFileName = "wrong Sitecore references $newTargetDirectoryInfoName.csv"
        $reportwrongSitecoreReferenceFullFileName = [System.IO.Path]::Combine($reportoutputfolder,$reportwrongSitecoreReferenceFileName)
        if(Test-Path -$reportwrongSitecoreReferenceFullFileName)
        {
            Remove-Item -Path $reportwrongSitecoreReferenceFullFileName -Force
        }
        #EOF wrong sitecore references report definition

        #BOF wrong 3rd party references from Sitecore report definition
        $reportwrongThirdPartyReferenecesInSitecoreAssemblies = "wrong 3rd party references in Sitecore assemblies $newTargetDirectoryInfoName.csv"
        $reportwrongThirdPartyReferenecesInSitecoreAssembliesFullFileName = [System.IO.Path]::Combine($reportoutputfolder,$reportwrongThirdPartyReferenecesInSitecoreAssemblies)
        if(Test-Path -$reportwrongThirdPartyReferenecesInSitecoreAssembliesFullFileName)
        {
            Remove-Item -Path $reportwrongThirdPartyReferenecesInSitecoreAssembliesFullFileName -Force
        }
        #BOF wrong 3rd party references from Sitecore report definition

        #BOF might require assembly bining redirect in web.config or app.config
        $reportwrongThirdPartyReferenecesInThirdPartyAssemblies = "consider assembly binding redirect in $newTargetDirectoryInfoName.csv"
        $reportwrongThirdPartyReferenecesInThirdPartyAssembliesFullFileName = [System.IO.Path]::Combine($reportoutputfolder,$reportwrongThirdPartyReferenecesInThirdPartyAssemblies)
        if(Test-Path -$reportwrongThirdPartyReferenecesInThirdPartyAssembliesFullFileName)
        {
            Remove-Item -Path $reportwrongThirdPartyReferenecesInThirdPartyAssembliesFullFileName -Force
        }
        #BOF might require assembly bining redirect in web.config or app.config

        #BOF should be in GAC
        $reportHopeFullyInGACAssemblies = "Assemblies hopefully in GAC $newTargetDirectoryInfoName.csv"
        $reportHopeFullyInGACAssembliesFullFileName = [System.IO.Path]::Combine($reportoutputfolder,$reportHopeFullyInGACAssemblies)
        if(Test-Path -$reportHopeFullyInGACAssembliesFullFileName)
        {
            Remove-Item -Path $reportHopeFullyInGACAssembliesFullFileName -Force
        }
        #BOF should be in GAC

        #BOF consider shipping
        $reportConsiderShippingTheseAssemblies = "consider shippping these assemblies with $newTargetDirectoryInfoName.csv"
        $reportConsiderShippingTheseAssembliesFullFileName = [System.IO.Path]::Combine($reportoutputfolder,$reportConsiderShippingTheseAssemblies)
        if(Test-Path -$reportConsiderShippingTheseAssembliesFullFileName)
        {
            Remove-Item -Path $reportConsiderShippingTheseAssembliesFullFileName -Force
        }
        #BOF consider shipping


        $wrongReferencesReportLine = ""
        $wrongThirdPartyReferencesInSitecoreAssembliesReportLine = ""
        $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine = ""
        $hopeFullyInGACAssembliesReportLine = ""
        $considerShippingTheseAssembliesReportLine = ""
        #Get-ChildItem $newTargetDirectory -rec | Where-Object {$_.Name -match $fileFilter} | ForEach-Object {
        Get-ChildItem $newTargetDirectory | Where-Object {($_.Name.ToLower().EndsWith("dll")) -or ($_.Name.ToLower().EndsWith("exe"))} | ForEach-Object {
            $original = [io.path]::GetFileName($_.FullName)
            #$bytes   = [System.IO.File]::ReadAllBytes($_.FullName)
            #$loaded  = [System.Reflection.Assembly]::Load($bytes)
            $assemblyDefinition = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($_.FullName)
            
            $loadedAssemblyName = [Mono.Cecil.AssemblyNameReference]::Parse($assemblyDefinition.FullName)
            
            # Check for correct referenced Sitecore version
            $assemblyDefinition.MainModule.AssemblyReferences | ForEach-Object {
                $loadedAssemblyNameReferenced = $_
                if($_.FullName.ToLower().StartsWith("sitecore"))
                {
                    $matchValue = $_.Name
                    $assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName | Where-Object {$_.Name -eq "$matchValue.dll"})
                    if($assembly -ne $null)
                    {
                        if($_.Version -ne $assembly.AssemblyVersion)
                        {
                            if([string]::IsNullOrEmpty($wrongReferencesReportLine))
                            {
                                $wrongReferencesReportLine = "sep=,$nl"
                                $wrongReferencesReportLine = $wrongReferencesReportLine + "`"Assembly with wrong reference`",`"Wrong referenced assembly`",`"wrong referenced version`",`"correct referenced version`"$nl"
                            }
                            $wrongSitecoreReferenceName = $_.Name
                            $wrongSitecoreReferenceVersion = $_.Version
                            $wrongSitecoreReferenceOriginal = $original
                            $wrongSitecoreReferenceShouldBe = $assembly.AssemblyVersion
                            $wrongReferencesReportLine = $wrongReferencesReportLine + "`"$wrongSitecoreReferenceOriginal`",`"$wrongSitecoreReferenceName`",`"$wrongSitecoreReferenceVersion`",`"$wrongSitecoreReferenceShouldBe`"$nl"
                        }
                    }
                }

                if(!$_.FullName.ToLower().StartsWith("sitecore."))
                {
                    $matchValue = $_.Name
                    $assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName, PublicKeyToken, CultureName | Where-Object {$_.Name -eq "$matchValue.dll"})
                    $assemblyWithProblems = $original
                    if($assembly -ne $null)
                    {
                        $loadedCultureName = ""
                        if ([string]::IsNullOrEmpty($loadedAssemblyNameReferenced.Culture)) 
                        { 
                            $loadedCultureName = "neutral" 
                        }
                        else
                        {
                            $loadedCultureName = $loadedAssemblyNameReferenced.Culture
                        }
                    
                        [byte[]] $bytePublicKeyToken = $loadedAssemblyNameReferenced.PublicKeyToken

                        $pbt = Get-PublicKeyToken -bytePublicKeyToken $bytePublicKeyToken
                        $version = $loadedAssemblyNameReferenced.Version

                        
                        $assemblyWithProblemsWrongReferenceActualFullName = [string]$assembly.AssemblyFullName
                        $assemblyWithProblemsWrongReferenceWrongFullName = [string]$loadedAssemblyNameReferenced.FullName
                        if(($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.")) -or ($loadedAssemblyName.FullName.ToLower().StartsWith("maengine")) -or ($loadedAssemblyName.FullName.ToLower().StartsWith("xconnectsearchindexer")))
                        {
                            if(([string]$pbt -ne [string]$assembly.PublicKeyToken) -or ([string]$version -ne [string]$assembly.AssemblyVersion) -or (([string]$loadedCultureName).ToLowerInvariant() -ne ([string]$assembly.CultureName).ToLowerInvariant()) -or ($assemblyWithProblemsWrongReferenceActualFullName.ToLowerInvariant() -ne $assemblyWithProblemsWrongReferenceWrongFullName.ToLowerInvariant()))
                            {
                                if([string]::IsNullOrEmpty($wrongThirdPartyReferencesInSitecoreAssembliesReportLine))
                                {
                                    $wrongThirdPartyReferencesInSitecoreAssembliesReportLine = "sep=,$nl"
                                    $wrongThirdPartyReferencesInSitecoreAssembliesReportLine = $wrongThirdPartyReferencesInSitecoreAssembliesReportLine + "`"Assembly with wrong reference`",`"actual shipped assembly fullname`",`"wrong referenced assembly fullname`"$nl"
                                }

                                $wrongThirdPartyReferencesInSitecoreAssembliesReportLine = $wrongThirdPartyReferencesInSitecoreAssembliesReportLine + "`"$assemblyWithProblems`",`"$assemblyWithProblemsWrongReferenceActualFullName`",`"$assemblyWithProblemsWrongReferenceWrongFullName`"$nl"
                            }
                        }
                        else {
                            # trying to report on wrong referenced assemblies from 3rd party components, which might require assembly binding redirect, since we have them in our shipped folder
                            if(([string]$pbt -ne [string]$assembly.PublicKeyToken) -or ([string]$version -ne [string]$assembly.AssemblyVersion) -or (([string]$loadedCultureName).ToLowerInvariant() -ne ([string]$assembly.CultureName).ToLowerInvariant()) -or ($assemblyWithProblemsWrongReferenceActualFullName.ToLowerInvariant() -ne $assemblyWithProblemsWrongReferenceWrongFullName.ToLowerInvariant()))
                            {
                                if([string]::IsNullOrEmpty($wrongThirdPartyReferencesInThirdPartyAssembliesReportLine))
                                {
                                    $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine = "sep=,$nl"
                                    $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine = $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine + "`"Assembly with wrong reference`",`"actual shipped assembly fullname`",`"wrong referenced assembly fullname`"$nl"
                                }

                                $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine = $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine + "`"$assemblyWithProblems`",`"$assemblyWithProblemsWrongReferenceActualFullName`",`"$assemblyWithProblemsWrongReferenceWrongFullName`"$nl"
                            }
                        }
                    }
                    else {
                        # Things we don't ship, but that are referenced from assemblies we actually ship - it should be either in GAC, or we need to ship it.
                        $notShippedAssemblyFullName = [string]$loadedAssemblyNameReferenced.FullName
                        $reflectionOnlyAssembly = $null
                        try {
                            $reflectionOnlyAssembly = [System.Reflection.Assembly]::ReflectionOnlyLoad($notShippedAssemblyFullName)
                            if($reflectionOnlyAssembly.GlobalAssemblyCache)
                            {
                                if([string]::IsNullOrEmpty($hopeFullyInGACAssembliesReportLine))
                                {
                                    $hopeFullyInGACAssembliesReportLine = "sep=,$nl"
                                    $hopeFullyInGACAssembliesReportLine = $hopeFullyInGACAssembliesReportLine + "`"Assembly with reference to assembly hopefully in GAC`",`"Assembly fullname which might be in GAC`"$nl"
                                }
                                
                                $hopeFullyInGACAssembliesReportLine = $hopeFullyInGACAssembliesReportLine + "`"$assemblyWithProblems`",`"$notShippedAssemblyFullName`"$nl"
                            }
                            else {
                                Write-host "Assembly is found SOMEWHERE ELSE ON THE MACHINE - WTF"
                                Write-Host "`"$assemblyWithProblems`",`"$notShippedAssemblyFullName`"$nl"
                            }
                        }
                        catch {
                            if([string]::IsNullOrEmpty($considerShippingTheseAssembliesReportLine))
                            {
                                $considerShippingTheseAssembliesReportLine = "sep=,$nl"
                                $considerShippingTheseAssembliesReportLine = $considerShippingTheseAssembliesReportLine + "`"Assembly with reference to nowhere to be found assembly`",`"Assembly fullname which might be worth shipping`"$nl"
                            }

                            $considerShippingTheseAssembliesReportLine = $considerShippingTheseAssembliesReportLine + "`"$assemblyWithProblems`",`"$notShippedAssemblyFullName`"$nl"
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

        if(![string]::IsNullOrEmpty($wrongThirdPartyReferencesInSitecoreAssembliesReportLine))
        {
            $wrongThirdPartyReferencesInSitecoreAssembliesReportLine | Out-File -FilePath $reportwrongThirdPartyReferenecesInSitecoreAssembliesFullFileName -Enc "UTF8"
        }

        if(![string]::IsNullOrEmpty($wrongThirdPartyReferencesInThirdPartyAssembliesReportLine))
        {
            $wrongThirdPartyReferencesInThirdPartyAssembliesReportLine | Out-File -FilePath $reportwrongThirdPartyReferenecesInThirdPartyAssembliesFullFileName -Enc "UTF8"
        }
        
        if(![string]::IsNullOrEmpty($hopeFullyInGACAssembliesReportLine))
        {
            $hopeFullyInGACAssembliesReportLine | Out-File -FilePath $reportHopeFullyInGACAssembliesFullFileName -Enc "UTF8"
        }

        if(![string]::IsNullOrEmpty($considerShippingTheseAssembliesReportLine))
        {
            $considerShippingTheseAssembliesReportLine | Out-File -FilePath $reportConsiderShippingTheseAssembliesFullFileName -Enc "UTF8"
        }
    }
}

$workingFolderPackage = [System.IO.Path]::Combine($workingFolder, "packages")

if(Test-Path -Path $workingFolderPackage)
{
    Remove-PathToLongDirectory -Path $workingFolderPackage
}

if(Test-Path -Path $targetDirectory)
{
    Remove-PathToLongDirectory -Path $targetDirectory
}

if(Test-Path -Path $nugetExecutable)
{
    Remove-Item $nugetExecutable -Force
}

if(Test-Path -Path $workingFolder)
{
    Remove-PathToLongDirectory -Path $workingFolder
}