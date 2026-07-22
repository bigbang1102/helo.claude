param([string]$Src,[string]$Dest)
$ErrorActionPreference='Stop'
$xl = New-Object -ComObject Excel.Application
$xl.Visible=$false; $xl.DisplayAlerts=$false
$wb = $xl.Workbooks.Open($Src,0,$true)
$out = @()
$names = @()
foreach($ws in $wb.Worksheets){ $names += $ws.Name }
$out += ("SHEETS: " + ($names -join ' , '))
foreach($ws in $wb.Worksheets){
  $sn = $ws.Name
  $ur = $ws.UsedRange
  $r0=$ur.Row; $c0=$ur.Column; $nr=$ur.Rows.Count; $nc=$ur.Columns.Count
  $out += ("===SHEET=== " + $sn + "  rows=" + $nr + " cols=" + $nc + " startR=" + $r0 + " startC=" + $c0)
  $maxR = $r0+$nr-1
  if($maxR -gt 200){ $maxR = 200 }
  $maxC = $c0+$nc-1
  if($maxC -gt 45){ $maxC = 45 }
  for($r=$r0;$r -le $maxR;$r++){
    $line=@(); $any=$false
    for($c=$c0;$c -le $maxC;$c++){
      $v = $ws.Cells.Item($r,$c).Text
      if($v -ne $null -and "$v" -ne ''){ $any=$true; $line += ("[" + $c + "]" + $v) }
    }
    if($any){ $out += ("R" + $r + " :: " + ($line -join ' | ')) }
  }
}
$wb.Close($false); $xl.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
$out | Out-File -FilePath $Dest -Encoding utf8
Write-Output ("DONE lines=" + $out.Count)
