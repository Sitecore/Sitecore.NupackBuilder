param
(
  [Parameter(Mandatory=$true,helpmessage="Local destinationfolder")][ValidateNotNullOrEmpty()][string]$destinationFolder,
  [Parameter(Mandatory=$true,helpmessage="The feed to upload packages from")][ValidateNotNullOrEmpty()][string]$source,  
  [Parameter(Mandatory=$true,helpmessage="The API key used when deleting from source")][ValidateNotNullOrEmpty()][string]$sourceAPIKey,
  [Parameter(Mandatory=$true,helpmessage="The feed to upload packages to")][ValidateNotNullOrEmpty()][string]$uploadFeed,  
  [Parameter(Mandatory=$true,helpmessage="The API key used when uploading")][ValidateNotNullOrEmpty()][string]$uploadAPIKey,
  [Parameter(Mandatory=$false,helpmessage="The filter used for getting packages - default is sitecore.framework")][ValidateNotNullOrEmpty()][string]$packageFilter = "sitecore.framework",
  [Parameter(Mandatory=$false,helpmessage="Specific version to download")][string]$specificVersion,
  [Parameter(Mandatory=$false,helpmessage="If specified packages will be uploaded to the feed, otherwise packages will only be created locally")][switch]$uploadPackages,
  [Parameter(Mandatory=$false,helpmessage="If specified packages will be deleted from source feed")][switch]$deletePackagesFromSource,
  [Parameter(Mandatory=$false,helpmessage="If specified destination folder will be deleted after the run")][switch]$deleteDestionationFolder
)

$upload = $false
if($uploadPackages)
{
	$upload = $true
}

$delete = $false
if($deletePackagesFromSource)
{
	$delete = $true
}

$deleteDestionation = $false
if($deleteDestionationFolder)
{
	$deleteDestionation = $true
}



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

Function PackNuspecFile(
	[Parameter(Mandatory=$true)][string]$nuspecfilename,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"
)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	}
	if($packageDirectory.EndsWith("\"))
	{
		$packageDirectory = $packageDirectory.Substring(0,$packageDirectory.Length-1)
	}

	$packargs = ' pack "' + $nuspecfilename + '" -OutputDirectory "' + $packageDirectory + '" -NonInteractive -NoPackageAnalysis -Verbosity ' + $verbosityValue
	$packcommand = "& '$nugetFullPath'" + $packargs
	Invoke-Expression $packcommand    
}

Function UploadNugetPackage(
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$packageFileName,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"
)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	} 

	$pushargs = ' push "' + $packageFileName + '" -ApiKey "'+$uploadAPIKey+'" -Source "'+$uploadFeed+'" -Timeout 600 -NonInteractive -Verbosity ' + $verbosityValue
	$pushcommand = "& '$nugetFullPath'" + $pushargs
	Invoke-Expression $pushcommand    
}

Function DeletePackageFromFeed(
	[Parameter(Mandatory=$true)][string]$moduleName,
	[Parameter(Mandatory=$true)][string]$moduleVersion,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$feed,
	[Parameter(Mandatory=$true)][string]$APIKey,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"
)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	}
	$deleteargs = ' delete ' + $moduleName + ' ' + $moduleVersion + ' -ApiKey "'+$APIKey+'" -Source "'+$feed+'" -NonInteractive -Verbosity ' + $verbosityValue
	$deletecommand = "& '$nugetFullPath'" + $deleteargs
	Invoke-Expression $deletecommand
}

Clear-Host

$workingFolder = [System.IO.Path]::Combine($env:TEMP, [System.IO.DirectoryInfo]::new("testSCFramework").Name)

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

if(Test-Path -Path $destinationFolder)
{
    Remove-PathToLongDirectory -Path $destinationFolder
}

if(!(Test-Path -Path $destinationFolder))
{
    [System.IO.Directory]::CreateDirectory($destinationFolder)
}

if ([string]::IsNullOrEmpty($specificVersion))
{
    Find-Package -Contains "$packageFilter" -AllowPrereleaseVersions -AllVersions -Source $source -ProviderName "NuGet" -Force -SkipValidate | Install-Package -AllVersions -AllowPrereleaseVersions -Contains "$packageFilter" -Force -SkipDependencies -SkipValidate -Destination $destinationFolder
}
else {
    Find-Package -Contains "$packageFilter" -AllowPrereleaseVersions -AllVersions -Source $source -ProviderName "NuGet" -Force -SkipValidate | Where-Object {$_.Version -eq $specificVersion} | ForEach-Object {
        Install-Package $_ -AllowPrereleaseVersions -Force -SkipDependencies -SkipValidate -Destination $destinationFolder
    }
}
Get-ChildItem $destinationFolder -Filter "*.nupkg" -Recurse | ForEach-Object {

    #Test
    #Write-Host $_.FullName
    $archivePath = $_.FullName
    $newTargetFileInfo = [System.IO.FileInfo]::new($archivePath)
    $targetDirectory = $newTargetFileInfo.DirectoryName

    $newFullName = $archivePath.Replace(".nupkg", ".zip")

    $newFileName = $newTargetFileInfo.Name.Replace(".nupkg", ".zip")

    $newNuspecFileName = $newTargetFileInfo.FullName.Replace(".nupkg", "")

    $newNuspecFileName = $newNuspecFileName.Remove($newNuspecFileName.LastIndexOf("."))
    $newNuspecFileName = $newNuspecFileName.Remove($newNuspecFileName.LastIndexOf("."))
    $newNuspecFileName = $newNuspecFileName.Remove($newNuspecFileName.LastIndexOf("."))
    
    $packageVersion = $newTargetFileInfo.FullName.Replace(".nupkg", "").Replace($newNuspecFileName, "")
    $packageName = $newFileName.Replace(".zip","").Replace($packageVersion,"")
    if($packageVersion.StartsWith("."))
    {
        $packageVersion = $packageVersion.Substring(1,$packageVersion.Length-1)
    }
    $newNuspecFileName = "$newNuspecFileName.nuspec"
    $currentYear = [DateTime]::UtcNow.Year
    Rename-Item -Path $archivePath -NewName $newFileName -Force
    if(Test-Path -Path $newFullName)
    {
        UnZipFiles -installPath $workingFolder `
                   -ArchivePath $newFullName `
                   -TargetPath $targetDirectory `
                   -SuppressOutput `
                   -nugetFullPath $nugetExecutable `
                   -NugetFeed "https://www.nuget.org/api/v2/" `
                   -doNotDeleteTargetPath

        if(Test-Path -Path $newNuspecFileName)
        {
            [xml]$nuspecContent = [xml] (Get-Content -Path $newNuspecFileName)

            if($nuspecContent.package.metadata.authors -ne $null)
            {
               $nuspecContent.package.metadata.authors = "Sitecore Corporation A/S"
            }

            if($nuspecContent.package.metadata.owners -ne $null)
            {
               $nuspecContent.package.metadata.owners = "Sitecore Corporation A/S"
            }

            if($nuspecContent.package.metadata.iconUrl -ne $null)
            {
                $nuspecContent.package.metadata.iconUrl = "https://mygetwwwsitecoreeu.blob.core.windows.net/feedicons/sc-packages.png"
            }
            else
            {
                $newChild = $nuspecContent.CreateElement("iconUrl", $nuspecContent.DocumentElement.NamespaceURI)
                $newChild.InnerText = "https://mygetwwwsitecoreeu.blob.core.windows.net/feedicons/sc-packages.png"
                $childnode = $nuspecContent.package.metadata.ChildNodes | Where-Object {$_.Name -eq "description"}
                [void]$nuspecContent.package.metadata.InsertAfter($newChild,$childnode)
            }

            if($nuspecContent.package.metadata.licenseUrl -ne $null)
            {
                $nuspecContent.package.metadata.licenseUrl = "https://doc.sitecore.net/~/media/C23E989268EC4FA588108F839675A5B6.pdf"
            }
            else
            {
                $newChild = $nuspecContent.CreateElement("licenseUrl", $nuspecContent.DocumentElement.NamespaceURI)
                $newChild.InnerText = "https://doc.sitecore.net/~/media/C23E989268EC4FA588108F839675A5B6.pdf"
                $childnode = $nuspecContent.package.metadata.ChildNodes | Where-Object {$_.Name -eq "description"}
                [void]$nuspecContent.package.metadata.InsertAfter($newChild,$childnode)
            }

            if($nuspecContent.package.metadata.copyright -ne $null)
            {
                $nuspecContent.package.metadata.copyright = "© $currentYear Sitecore Corporation A/S. All rights reserved. Sitecore® is a registered trademark of Sitecore Corporation A/S."
            }
            else
            {
                $newChild = $nuspecContent.CreateElement("copyright", $nuspecContent.DocumentElement.NamespaceURI)
                $newChild.innerXML = "&#169; $currentYear Sitecore Corporation A/S. All rights reserved. Sitecore&#174; is a registered trademark of Sitecore Corporation A/S."
                $childnode = $nuspecContent.package.metadata.ChildNodes | Where-Object {$_.Name -eq "description"}
                [void]$nuspecContent.package.metadata.InsertAfter($newChild,$childnode)
            }

            $nuspecContent.Save($newNuspecFileName) 
            $relsDirectory = [System.IO.Path]::Combine($targetDirectory, "_rels")
            $ContentTypesXmlFile = [System.IO.Path]::Combine($targetDirectory, "[Content_Types].xml")

            $packageNugetDirectory = [System.IO.Path]::Combine($targetDirectory, "package")
            
            if(Test-Path -Path $relsDirectory)
            {
                Remove-PathToLongDirectory -Path $relsDirectory
            }

            if(Test-Path -Path $packageNugetDirectory)
            {
                Remove-PathToLongDirectory -Path $packageNugetDirectory
            }

            if([System.IO.File]::Exists($ContentTypesXmlFile))
            {
                [System.IO.File]::Delete($ContentTypesXmlFile)
            }

            if([System.IO.File]::Exists($newFullName))
            {
                [System.IO.File]::Delete($newFullName)
            }

            PackNuspecFile -nuspecfilename $newNuspecFileName -packageDirectory $destinationFolder -nugetFullPath $nugetExecutable

            
            $uploadPackage = [System.IO.Path]::Combine($destinationFolder, $newTargetFileInfo.Name)

            

            if(Test-Path -Path $uploadPackage)
            {
                if($upload)
                {
                    UploadNugetPackage -nugetFullPath $nugetExecutable -packageFileName $uploadPackage -uploadFeed $uploadFeed -uploadAPIKey $uploadAPIKey
                }
                if($delete)
                {
                    DeletePackageFromFeed -moduleName $packageName -moduleVersion $packageVersion -nugetFullPath $nugetExecutable -feed $source -APIKey $sourceAPIKey
            
                }
            }
        }
    }
}

if(Test-Path -Path $nugetExecutable)
{
    Remove-Item $nugetExecutable -Force
}

if(Test-Path -Path $workingFolder)
{
    Remove-PathToLongDirectory -Path $workingFolder
}

if(Test-Path -Path $destinationFolder)
{
    if($deleteDestionation -eq $true)
    {
        Remove-PathToLongDirectory -Path $destinationFolder
    }
}

