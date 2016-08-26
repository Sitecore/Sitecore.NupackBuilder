$TypeDefinitionSource = @"
  namespace NupackBuilder
{
	using System;
	using System.Linq;

	public class PackageAssembly
	{
		public string AssemblyName { get; protected set; }
		public string AssemblyVersion { get; protected set; }
		public string AssemblyCulture { get; protected set; }
		public string AssemblyPublicKeyToken { get; protected set; }

		public PackageAssembly(string assemblyName, string assemblyVersion, string assemblyCulture, string assemblyPublicKeyToken)
		{
			AssemblyName = assemblyName;
			AssemblyVersion = assemblyVersion;
			AssemblyCulture = assemblyCulture;
			AssemblyPublicKeyToken = assemblyPublicKeyToken;
		}
	}

	public class PackageInfo
	{
		public string PackageName { get; protected set; }
		public string PackageVersion { get; protected set; }
		public bool PreRelease { get; protected set; }

		public System.Collections.Generic.List<PackageAssembly> PackageAssemblies { get; protected set; }

		public PackageInfo(string packageName, string packageVersion, bool preRelease)
		{
			PackageAssemblies = new System.Collections.Generic.List<PackageAssembly>();
			PackageName = packageName;
			PackageVersion = packageVersion;
			PreRelease = preRelease;
		}

		public PackageInfo(string packageName, string packageVersion, bool preRelease, PackageAssembly packageAssembly) : this(packageName, packageVersion, preRelease)
		{
			PackageAssemblies.Add(packageAssembly);
		}

		public void AddPackageAssembly(PackageAssembly packageAssembly)
		{
			PackageAssemblies.Add(packageAssembly);
		}
	}

	public class Packages
	{
		public System.Collections.Concurrent.ConcurrentDictionary<string, PackageInfo> PackageInfos { get; protected set; }

		public Packages()
		{
			PackageInfos = new System.Collections.Concurrent.ConcurrentDictionary<string, PackageInfo>();
		}

		public void AddPackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (!PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				PackageInfos.TryAdd(packageInfo.PackageName + packageInfo.PackageVersion, packageInfo);
			}
		}

		public void RemovePackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (!PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				return;
			}

			PackageInfo removePackage;
			PackageInfos.TryRemove(packageInfo.PackageName + packageInfo.PackageVersion, out removePackage);
		}

		public void UpdatePackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				RemovePackageInfo(packageInfo);
			}

			AddPackageInfo(packageInfo);
		}

		public PackageInfo FindPackageInfoByAssemblyNameAndAssemblyVersion(string assemblyName, string assemblyVersion)
		{
			var packageInfo = PackageInfos.FirstOrDefault(
				pInfo =>
					pInfo.Value.PackageAssemblies.Find(
						pAssembly =>
							pAssembly.AssemblyName.Equals(assemblyName, StringComparison.InvariantCultureIgnoreCase) &&
							pAssembly.AssemblyVersion.Equals(assemblyVersion,
								StringComparison.InvariantCultureIgnoreCase)) != null);

			return packageInfo.Value;
		}
	}
}
"@

Add-Type -TypeDefinition $TypeDefinitionSource

Function Write-Log(
  [string][Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$Message,
  [string]$Program = "PowerShell",
  [string]$Level = "INFO",
  [string]$foregroundcolor = "Green",
  [switch]$silent
)
{
  $msg="[$(Get-Date -Format T)] [$Level] $Message" 
  if (-not $silent.IsPresent) 
  {
	switch ($Level) 
	{ 
	  "info"    
	  {
		if ($foregroundcolor)
		{
		  Write-Host "$msg" -foregroundcolor $foregroundcolor
		}
		else
		{
		  Write-Host "$msg"
		}
	  } 
	  "inform"  
	  {
		Write-Host "$msg"
	  } 
	  "warn"    
	  {
		Write-Host "$msg" -foregroundcolor Yellow
		$global:warningcount++
	  } 
	  "warni"   
	  {
		 Write-Host "$msg" -foregroundcolor Yellow
		 $global:warningcount++
	  }
	  "warning" 
	  {
		Write-Host "$msg" -foregroundcolor Yellow
		$global:warningcount++
	  }
	  "err"     
	  {
		Write-Host "$msg" -foregroundcolor Red
		$global:errorcount++
		#throw
		exit(-1)
	  } 
	  "error"   
	  {
		Write-Host "$msg" -foregroundcolor Red
		$global:errorcount++
		#throw
		exit(-1)
	  } 
	  default {Write-Host "$msg"}
	}
  }
}

Function Get-7z(
[Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
[Parameter(Mandatory=$true)][string]$installPath,
[Parameter(Mandatory=$true)][string]$nugetFullPath
)
{
	if (!(Test-Path -Path "$installPath\packages\7-Zip.CommandLine\tools\7za.exe"))
	{
		$nugetArgs = ' install 7-Zip.CommandLine -ExcludeVersion -o "' + $installPath + '\packages" -Source "' + $NugetFeed + '"'
		$nugetCommand = "& '$nugetFullPath'" + $nugetArgs
		Write-Log -Message "Installing 7-Zip.CommandLine nuget package to $installPath\packages ..." -Program "nuget"
		iex $nugetCommand -Verbose | Out-Null
		Write-Log -Message "Done installing 7-Zip.CommandLine nuget package to $installPath\packages ..." -Program "nuget"
	}
	return "$installPath\packages\7-Zip.CommandLine\tools\7za.exe"
}

Function Add-ThirdPartyComponent(
[Parameter(Mandatory=$true)][string]$PackageName,
[Parameter(Mandatory=$true)][Array]$AssemblyNames,
[Parameter(Mandatory=$true)][Array]$Versions
)
{
	$thirdpartycomponents = @()
	$objThirdPartyComponent = New-Object System.Object
	$objThirdPartyComponent | Add-Member -type NoteProperty -name PackageName -value $PackageName
	$objThirdPartyComponent | Add-Member -type NoteProperty -name AssemblyNames -value $AssemblyNames
	$objThirdPartyComponent | Add-Member -type NoteProperty -name Versions -value $Versions
	$thirdpartycomponents += $objThirdPartyComponent
	return $thirdpartycomponents

}


Function Add-PlatformThirdPartyPackages()
{
	$packages  = [NupackBuilder.Packages]::new()

	# Newtonsoft.Json 4.5.9
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "4.5.0.0", "neutral", "30ad4fe6b2a6aeed")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "4.5.9", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	# Newtonsoft.Json 6.0.8
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "6.0.0.0", "neutral", "30ad4fe6b2a6aeed")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "6.0.8", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	# Lucene.Net 3.0.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Lucene.Net", "3.0.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	# Lucene.Net.Contrib 3.0.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Analyzers", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Lucene.Net.Contrib", "3.0.3", $false, $packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Core", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.FastVectorHighlighter", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Highlighter", "2.3.2.1", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Memory", "1.0.0.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Queries", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Regex", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.SimpleFacetedSearch", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Snowball", "2.0.0.1", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.SpellChecker", "3.0.3.0", "neutral", "85089178b9ac3181")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#HtmlAgilityPack 1.4.6
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("HtmlAgilityPack", "1.4.6.0", "neutral", "bd319b19eaf3b43a")
	$packageInfo = [NupackBuilder.PackageInfo]::new("HtmlAgilityPack", "1.4.6", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#YUICompressor.NET 2.1.1
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Yahoo.Yui.Compressor", "2.1.1.0", "neutral", "null")
	$packageInfo = [NupackBuilder.PackageInfo]::new("YUICompressor.NET", "2.1.1", $false, $packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Iesi.Collections", "1.0.1.0", "neutral", "aa95f207798dfdb4")
	$packageInfo.AddPackageAssembly($packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("EcmaScript.NET", "1.0.1.0", "neutral", "null")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#mongocsharpdriver 1.10.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Bson", "1.10.0.62", "neutral", "f686731cfb9cc103")
	$packageInfo = [NupackBuilder.PackageInfo]::new("mongocsharpdriver", "1.10.0", $false, $packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver", "1.10.0.62", "neutral", "f686731cfb9cc103")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#SolrNet 0.4.0.4001
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("SolrNet", "0.4.0.4001", "neutral", "null")
	$packageInfo = [NupackBuilder.PackageInfo]::new("SolrNet", "0.4.0.4001", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#SolrNet 0.4.0-beta2 - can't be used since nuget doesn't allow creation of final packages with prereleases - and this is the one we use.
	#$packageAssembly = [NupackBuilder.PackageAssembly]::new("SolrNet", "0.4.0.2002", "neutral", "bc21753e8aa334cb")
	#$packageInfo = [NupackBuilder.PackageInfo]::new("SolrNet", "0.4.0-beta2", $true, $packageAssembly)
	#$packages.AddPackageInfo($packageInfo)

	#RazorGenerator.Mvc 2.4.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("RazorGenerator.Mvc", "2.0.0.0", "neutral", "7b26dc2a43f6a0d4")
	$packageInfo = [NupackBuilder.PackageInfo]::new("RazorGenerator.Mvc", "2.4.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#protobuf-net 2.0.0.668
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("protobuf-net", "2.0.0.668", "neutral", "257b51d87d2e4d67")
	$packageInfo = [NupackBuilder.PackageInfo]::new("protobuf-net", "2.0.0.668", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Ninject 3.2.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Ninject", "3.2.0.0", "neutral", "c7192dc5380945e7")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Ninject", "3.2.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#WebActivatorEx 2.0.6
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("WebActivatorEx", "2.0.0.0", "neutral", "7b26dc2a43f6a0d4")
	$packageInfo = [NupackBuilder.PackageInfo]::new("WebActivatorEx", "2.0.6", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Markdown 1.14.6
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("MarkdownSharp", "1.14.5.0", "neutral", "eb89951a0d41ab86")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Markdown", "1.14.6", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Facebook 5.4.1
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Facebook", "5.4.1.0", "neutral", "58cb4f2111d1e6de")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Facebook", "5.4.1", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.Mvc 5.1.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Mvc", "5.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Mvc", "5.1.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.Mvc 5.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Mvc", "5.2.3.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Mvc", "5.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.Razor 3.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Razor", "3.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Razor", "3.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Client 5.1.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Formatting", "5.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Client", "5.1.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Client 5.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Formatting", "5.2.3.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Client", "5.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Core 5.1.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http", "5.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Core", "5.1.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Core 5.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http", "5.2.3.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Core", "5.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.WebHost 5.1.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.WebHost", "5.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.WebHost", "5.1.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.WebHost 5.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.WebHost", "5.2.3.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.WebHost", "5.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebPages 3.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Helpers", "3.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebPages", "3.2.3", $false, $packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Deployment", "3.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo.AddPackageAssembly($packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages", "3.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo.AddPackageAssembly($packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Razor", "3.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo.AddPackageAssembly($packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.Web.Infrastructure 1.0.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Web.Infrastructure", "1.0.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Web.Infrastructure", "1.0.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.OData 5.9.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.OData", "5.9.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.OData", "5.9.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.OData.Core 6.15.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Core", "6.15.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Core", "6.15.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.OData.Edm 6.15.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Edm", "6.15.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Edm", "6.15.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.Spatial 6.15.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Spatial", "6.15.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Spatial", "6.15.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.Extensions.DependencyInjection.Abstractions 1.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.DependencyInjection.Abstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.DependencyInjection.Abstractions", "1.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.Extensions.DependencyInjection 1.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.DependencyInjection", "1.0.0.0", "neutral", "adb9793829ddae60")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.DependencyInjection", "1.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Cors 5.1.2
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.Cors", "5.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Cors", "5.1.2", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Cors 5.2.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.Cors", "5.2.3.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Cors", "5.2.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.Web.Optimization 1.1.3
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Optimization", "1.1.0.0", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Web.Optimization", "1.1.3", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#System.IdentityModel.Tokens.Jwt 5.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IdentityModel.Tokens.Jwt", "5.0.0.127", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("System.IdentityModel.Tokens.Jwt", "5.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#System.IdentityModel.Tokens.Jwt 4.0.2.206221351
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IdentityModel.Tokens.Jwt", "4.0.20622.1351", "neutral", "31bf3856ad364e35")
	$packageInfo = [NupackBuilder.PackageInfo]::new("System.IdentityModel.Tokens.Jwt", "4.0.2.206221351", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#CommonServiceLocation 1.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.ServiceLocation", "1.0.0.0", "neutral", "59d6d24383174ac4")
	$packageInfo = [NupackBuilder.PackageInfo]::new("CommonServiceLocation", "1.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#System.Net.Http 4.0.0
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http", "4.0.0.0", "neutral", "b03f5f7f11d50a3a")
	$packageInfo = [NupackBuilder.PackageInfo]::new("System.Net.Http", "4.0.0", $false, $packageAssembly)
	$packages.AddPackageInfo($packageInfo)

	#Microsoft.AspNet.WebApi.Extensions.Compression.Server 2.0.6
	$packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.AspNet.WebApi.Extensions.Compression.Server", "2.0.0.0", "neutral", "null")
	$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Extensions.Compression.Server", "2.0.6", $false, $packageAssembly)

	$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Extensions.Compression.Core", "2.0.0.0", "neutral", "null")
	$packageInfo.AddPackageAssembly($packageAssembly)

	$packages.AddPackageInfo($packageInfo)


	return $packages
}

Function UnZipDLLFiles (
  [Parameter(Mandatory=$true)][string]$installPath,
  [Parameter(Mandatory=$true)][string]$ArchivePath,  
  [Parameter(Mandatory=$true)][string]$TargetPath, 
  [Parameter(Mandatory=$true)][string]$Filter,  
  [switch]$SuppressOutput,
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$nugetFullPath
)
{
  
  if (!(Test-Path -Path $ArchivePath))
  {
	Write-Log -Message "The archive to extract was not found: $ArchivePath" -Level "Error"
  }
	
  if((Test-Path -Path $TargetPath ))
  {
	$child_items = ([array] (Get-ChildItem -Path $TargetPath -Recurse -Force))
		if ($child_items) {
			$null = $child_items | Remove-Item -Force -Recurse | Out-Null
		}
		$null = Remove-Item $TargetPath -Force | Out-Null
  }
  
  if (!(Test-Path -Path $TargetPath))
  {
	New-Item -Path $TargetPath -ItemType directory | Out-Null
  }
  
  $FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($ArchivePath)
  [string]$pathTo7z = $(Get-7z -installPath $installPath -nugetFullPath $nugetFullPath -NugetFeed $NugetFeed)
  $unzipargs = ' e -r "' + $ArchivePath + '" "' + $Filter + '" -o"' + $TargetPath + '" -y'
  $unzipcommand = "& '$pathTo7z'" + $unzipargs
  
  if ($SuppressOutput)
  {
	Write-Log -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
	iex $unzipcommand | Out-Null
	Write-Log -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
  }
  else
  {
	iex $unzipcommand
  }  
}
