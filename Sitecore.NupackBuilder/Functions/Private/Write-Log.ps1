#
# Write-Log.ps1
#
Function Write-Log
{
  param
      (
      [string][Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$Message,
      [string]$Program = "PowerShell",
      [string]$Level = "INFO",
      [string]$foregroundcolor = "Green",
      [switch]$silent
    )
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

