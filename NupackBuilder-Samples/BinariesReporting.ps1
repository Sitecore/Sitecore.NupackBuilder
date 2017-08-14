param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$sitecoreRepositoryFolder  
)

cls


if (!(Test-Path -Path $sitecoreRepositoryFolder))
{
    New-Item $sitecoreRepositoryFolder -type directory -Force | Out-Null
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $root
Set-location -Path $root
if (!(Test-Path -Path "$sitecoreRepositoryFolder\nuget.exe" -PathType Leaf))
{
    $sourceNugetExe = "http://nuget.org/nuget.exe"
    Invoke-WebRequest $sourceNugetExe -OutFile "$sitecoreRepositoryFolder\nuget.exe"
}

if ((Test-Path -Path "$sitecoreRepositoryFolder\nuget.exe"))
{
    $nugetArgs = ' update -self -PreRelease'
    $nugetCommand = "& '"+"$sitecoreRepositoryFolder\nuget.exe"+"'" + $nugetArgs
    iex $nugetCommand -Verbose | Out-Null
    
}

$PlatformModule = Get-Module -Name NupackBuilder-Platform
if ($PlatformModule -eq $null)
{
    Import-Module $NugetModuleRoot\NupackBuilder-Platform -DisableNameChecking
}
else
{
    Remove-Module $PlatformModule -Force
    Import-Module $NugetModuleRoot\NupackBuilder-Platform -DisableNameChecking
}

$nugetExecutable = $sitecoreRepositoryFolder + "nuget.exe"

Get-ChildItem $sitecoreRepositoryFolder -Filter "*.zip" | % {
    $sitecorezipFileNameOnly = $_.Name    
$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
$archivePath = "$sitecoreRepositoryFolder$sitecorezipFileNameOnly"
$targetDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\"
$nuspecDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nuspec\"
$packageDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nupack\"

$SitecoreVersionWithRev = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(".zip","").Trim()

$SitecoreVersion = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(" rev. ",".").Replace("rev. ",".").Replace(" rev.",".").Replace(".zip","").Trim()
$nugetExecutable = $sitecoreRepositoryFolder + "nuget.exe"
$frameworVersion = "NET462"

Write-Host $SitecoreVersionWithRev

UnZipFiles -installPath $root `
    -ArchivePath $archivePath `
    -TargetPath $targetDirectory `
    -SuppressOutput `
    -nugetFullPath $nugetExecutable `
    -NugetFeed $NugetFeed

#UnZipDLLFiles -installPath $root `
#    -ArchivePath $archivePath `
#    -TargetPath $targetDirectory `
#    -SuppressOutput `
#    -nugetFullPath $nugetExecutable `
#    -NugetFeed $NugetFeed `
#    -Filter "*.exe" `
#    -doNotDeleteTargetPath

#exit

$fileFilter = "(Sitecore.*\.(dll|exe)|maengine\.exe|XConnectSearchIndexer.exe)$"

#$fileFilter = "(*.(dll|exe)|maengine\.exe|XConnectSearchIndexer.exe)$"

$xconnectServer = "Sitecore XConnect Server $SitecoreVersionWithRev\Website\bin"
$MarketingAutomationService = "Sitecore Marketing Automation Service $SitecoreVersionWithRev\"
$xconnectIndexingService = "Sitecore XConnect Index Service $SitecoreVersionWithRev\"
$sitecorePlatform = "$FileNameNoExtension\Website\bin\"


#$newTargetDirectory = "$targetDirectory$xconnectServer"
#$newTargetDirectory = "$targetDirectory$MarketingAutomationService"
#$newTargetDirectory = "$targetDirectory$xconnectIndexingService"
$newTargetDirectory = "$targetDirectory$sitecorePlatform"

# Reporting
$assemblies=Get-ChildItem $newTargetDirectory -rec | Where-Object {$_.Name.ToLower().EndsWith("dll")} |
ForEach-Object {
    try {
        $_ | Add-Member NoteProperty FileVersion ($_.VersionInfo.FileVersion)
        $_ | Add-Member NoteProperty AssemblyVersion ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).Version.ToString())
        $_ | Add-Member NoteProperty AssemblyFullName ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).FullName)
        $_ | Add-Member NoteProperty AssemblyFileName ($_.Name)
    } catch {}
    $_
}

#$fileNames = Get-ChildItem $newTargetDirectory -rec | Where-Object {$_.Name -match $fileFilter} |Select-Object -ExpandProperty FullName

#foreach($polle in $assemblies)
#{
#    $polleTest = $polle.AssemblyFileName
#    Write-Host "po = $polleTest"
#}

#exit

#Get-ChildItem $newTargetDirectory -rec| Where-Object {$_.Name.ToLower().EndsWith("dll")} | % {

$references = Get-ChildItem $newTargetDirectory -rec | Where-Object {$_.Name -match $fileFilter} | % {
    $fullName = $_.FullName
    #Write-Host "Original is <$fullName>...."
    $original = [io.path]::GetFileName($_.FullName)
    #Write-Host "Processing <$original>...."
    $bytes   = [System.IO.File]::ReadAllBytes($_.FullName)
    $loaded  = [System.Reflection.Assembly]::Load($bytes)
    $name    = $loaded.ManifestModule
    $loadedAssemblyName = $loaded.GetName()

    if (1 -eq 2)
    {
        # Check for correct referenced version
        $loaded.GetReferencedAssemblies() | % {
            $toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe
            #if($_.FullName.ToLower().StartsWith("sitecore."))
            #{
                $matchValue = $_.Name
                $assembly = $null
                foreach($testAssembly in $assemblies)
                {
                    if($testAssembly.AssemblyFileName -eq "$matchValue.dll")
                    {
                        $assembly = $testAssembly
                    }
                }

                if($assembly -ne $null)
                {   
                    if($_.Version -ne $assembly.AssemblyVersion)
                    {
                        $toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe = $loaded,$_.FullName,$_.Name,$_.Version, $original, $assembly.AssemblyVersion
                    }
                }         
                
            #}
            $toAdd
            if($loaded -ne $null)
            {
                $loaded = $null
            }
        }
    }

    if (1 -eq 1)
    {
        # Report on referenced 3rd party components
        $loaded.GetReferencedAssemblies() | % {
            $toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe, CultureName, PublicKeyToken
            if($_.FullName.ToLower().StartsWith("system.io.abstractions"))
            {
                $matchValue = $_.Name
                #$assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName) -match "$matchValue.dll"

                #if($assembly -ne $null)
                #{
                    #if($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore."))
                    #{
                        $cultureName = ""
                        if ([string]::IsNullOrEmpty($loadedAssemblyName.CultureName)) { $cultureName = "neutral" } else {$cultureName = $loadedAssemblyName.CultureName}

                        [byte[]] $bytePublicKeyToken = $loadedAssemblyName.GetPublicKeyToken()
                        
                       
                        $pbt = ""
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
                        $name = $loadedAssemblyName.Name
                        $version = $loadedAssemblyName.Version

                        if([string]::IsNullOrEmpty($pbt))
                        {
                            $pbt = "null"
                        }

                        Write-Host "$name,$version,$cultureName,$pbt"
                        #$toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe, $toAdd.CultureName, $toAdd.PublicKeyToken = $loaded,$_.FullName,$_.Name,$_.Version, $original, "", $cultureName, $pbt
                    #}
                #}         
                
            }
            #$toAdd
            if($loaded -ne $null)
            {
                $loaded = $null
            }
        }
    }

    if (1 -eq 2)
    {
        # Report on referenced 3rd party components
        $loaded.GetReferencedAssemblies() | % {
            $toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe, CultureName, PublicKeyToken
            if(!$_.FullName.ToLower().StartsWith("sitecore."))
            {
                $matchValue = $_.Name
                #$assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName) -match "$matchValue.dll"

                #if($assembly -ne $null)
                #{
                    #if($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore."))
                    #{
                        $cultureName = ""
                        if ([string]::IsNullOrEmpty($_.CultureName)) { $cultureName = "neutral" } else {$cultureName = $_.CultureName}

                        [byte[]] $bytePublicKeyToken = $_.GetPublicKeyToken()
                        
                       
                        $pbt = ""
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
                        $name = $_.Name
                        $version = $_.Version

                        if([string]::IsNullOrEmpty($pbt))
                        {
                            $pbt = "null"
                        }

                        Write-Host "$name,$version,$cultureName,$pbt"
                        #$toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe, $toAdd.CultureName, $toAdd.PublicKeyToken = $loaded,$_.FullName,$_.Name,$_.Version, $original, "", $cultureName, $pbt
                    #}
                #}         
                
            }
            #$toAdd
            if($loaded -ne $null)
            {
                $loaded = $null
            }
        }
    }

    if (1 -eq 2)
    {
        # Check for correct referenced version
        $loaded.GetReferencedAssemblies() | % {
            $toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe
            if($_.FullName.ToLower().StartsWith("sitecore"))
            {
                $matchValue = $_.Name
                $assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName) -match "$matchValue.dll"

                if($assembly -ne $null)
                {
                    if($_.Version -ne $assembly.AssemblyVersion)
                    {
                        $toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe = $loaded,$_.FullName,$_.Name,$_.Version, $original, $assembly.AssemblyVersion
                    }
                }         
                
            }
            $toAdd
            if($loaded -ne $null)
            {
                $loaded = $null
            }
        }
    }

    if(1 -eq 2)
    {
        # Report wrong Assembly Version
        if(($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.")) -and (!$loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.nexus")))
        {
            $assemblyItemVersion = $loadedAssemblyName.Version
            $assemblyItemName = $loadedAssemblyName.Name
            if(!($assemblyItemVersion.toString().EndsWith(".0.0")))
            {
                Write-Host "$assemblyItemName, $assemblyItemVersion"
            }

        }
    }

    if(1 -eq 2)
    {
        if(($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.")))
        {
            $assemblyItemVersion = $loadedAssemblyName.Version
            $assemblyItemName = $loadedAssemblyName.Name
            
            Write-Host "$assemblyItemName, $assemblyItemVersion"
            
        }
    }

    if(1 -eq 2)
    {
        # reporting of usage of 3rd party components in Sitecore assemblies
        if((!$loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.")))
        {
            $toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe
            $toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe = $loaded,$loaded.FullName,$loaded.Name,$loadedAssemblyName.Version, $original, ""
                
            
            $toAdd
            if($loaded -ne $null)
            {
                $loaded = $null
            }						
        }
    }
}


    
$references | 
    #Group-Object Original, Version | 
    #Select-Object -expand Name | 
    #Sort-Object
    Group-Object Original,Name,Version,ShouldBe | 
    Select-Object -expand Name | 
    Sort-Object
}
