param([string]$Src)
$ErrorActionPreference='Stop'
$sp='C:\Users\Dev\AppData\Local\Temp\claude\C--git-new-template-wildfly-30-0-0-Final-standalone-deployments-redjaka-ear-red-war\7fb170f7-4068-4a1c-afe7-d894697c96cf\scratchpad'
$xl = New-Object -ComObject Excel.Application
$xl.Visible=$false; $xl.DisplayAlerts=$false
$wb = $xl.Workbooks.Open($Src,0,$true)
$adv = $wb.Worksheets.Item('advance_usecase')
$out=@()
foreach($r in @(30,39,100)){
  foreach($c in @(1,7,8,20,21,31)){
    $out += ('ADV R' + $r + ' c' + $c + ' = ' + $adv.Cells.Item($r,$c).Formula)
  }
}
$out += ('LAST c31 formula row check:')
for($r=36;$r -le 46;$r++){
  $f = '' + $adv.Cells.Item($r,31).Formula
  $out += ('  R' + $r + ' c31=[' + $f + ']')
}
$wb.Close($false); $xl.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
$out | Out-File "$sp\offs.txt" -Encoding utf8
Write-Output 'DONE'
