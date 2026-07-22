param([string]$Target, [string]$Bdname = '__BDNAME__')
$ErrorActionPreference='Stop'
$sp = $PSScriptRoot

$stdRows = Get-Content "$sp\std.tsv" -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
$advRows = Get-Content "$sp\adv.tsv" -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
$sdRows  = Get-Content "$sp\sd.tsv"  -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
$hdrLine = Get-Content "$sp\sheet1_hdr.tsv" -Encoding UTF8 | Select-Object -First 1

$reqRows = @(9,11,13)
$svcRows = @(9,11,12,13,14,16)
$cfgRows = @(8,9)
$log = @()

$xl = New-Object -ComObject Excel.Application
$xl.Visible=$false; $xl.DisplayAlerts=$false
$wb = $xl.Workbooks.Open($Target)
$xl.Calculation = -4135

$ws  = $wb.Worksheets.Item('standard_usecase')
$adv = $wb.Worksheets.Item('advance_usecase')
$con = $wb.Worksheets.Item('constrain')
$oth = $wb.Worksheets.Item('other')

# --- guard: verify offsets match what this script assumes ---
$f7  = '' + $adv.Cells.Item(30,7).Formula
$f8  = '' + $adv.Cells.Item(30,8).Formula
$f20 = '' + $adv.Cells.Item(30,20).Formula
$okOff = ($f7 -like '*constrain!$D7*') -and ($f8 -like '*other!B8*') -and ($f20 -like '*formula!$J6*')
if(-not $okOff){
  $wb.Close($false); $xl.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
  throw ("OFFSET MISMATCH - c7=[$f7] c8=[$f8] c20=[$f20]")
}
$log += 'offset guard OK (adv=std+22, constrain=std-1, formula=std-2, other=std+0)'

# --- standard_usecase ---
for($r=8;$r -le 67;$r++){
  $ws.Cells.Item($r,1).Value2='none'
  $ws.Cells.Item($r,2).Value2='none'
  $ws.Cells.Item($r,3).Value2='String'
  $ws.Cells.Item($r,4).Value2='none'
  $ws.Cells.Item($r,5).Value2='none'
  $ws.Cells.Item($r,6).Value2='none'
  $ws.Cells.Item($r,7).Value2='none'
  $ws.Cells.Item($r,8).ClearContents() | Out-Null
}
foreach($ln in $stdRows){
  $p = $ln -split "`t"
  $rowNo = [int]$p[0]
  for($c=1;$c -le 8;$c++){ $ws.Cells.Item($rowNo,$c).Value2 = $p[$c] }
}
$log += ('standard_usecase written rows=' + $stdRows.Count)

# --- constrain ---
for($r=7;$r -le 66;$r++){
  $con.Cells.Item($r,4).ClearContents()  | Out-Null
  $con.Cells.Item($r,10).ClearContents() | Out-Null
}
foreach($rq in $reqRows){ $con.Cells.Item($rq-1,4).Value2 = $true }
$con.Cells.Item(17,10).Value2 = "(`$exists_txno`$)==''"

# --- other ---
for($r=8;$r -le 67;$r++){
  $oth.Cells.Item($r,2).ClearContents() | Out-Null
  $oth.Cells.Item($r,3).ClearContents() | Out-Null
}
foreach($rs in $svcRows){ $oth.Cells.Item($rs,2).Value2 = $true }

# --- advance literals ---
for($r=30;$r -le 89;$r++){
  $adv.Cells.Item($r,23).ClearContents() | Out-Null
  $adv.Cells.Item($r,29).ClearContents() | Out-Null
  $adv.Cells.Item($r,30).ClearContents() | Out-Null
}
foreach($rc in $cfgRows){ $adv.Cells.Item($rc+22,29).Value2 = $true }
foreach($ln in $advRows){
  $q = $ln -split "`t"
  $adv.Cells.Item([int]$q[0], [int]$q[1]).Value2 = $q[2]
}
$log += ('advance literals written=' + $advRows.Count)

# --- field-subtab formula fill (only for real field rows) ---
$maxStd = 0
foreach($ln in $stdRows){ $n = [int](($ln -split "`t")[0]); if($n -gt $maxStd){ $maxStd = $n } }
$maxAdv = $maxStd + 22
for($r=30;$r -le 89;$r++){
  if($r -le $maxAdv){
    $cur = '' + $adv.Cells.Item($r,31).Formula
    if($cur -eq ''){ $adv.Cells.Item($r,31).Formula = ('=standard_usecase!H' + ($r-22)) }
  } else {
    $adv.Cells.Item($r,31).ClearContents() | Out-Null
  }
}
$log += ('c31 filled up to adv row ' + $maxAdv)

# --- set_display ---
$existing = @()
foreach($sh in $wb.Worksheets){ $existing += $sh.Name }
if($existing -notcontains 'set_display'){
  $sd = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $adv)
  $sd.Name = 'set_display'
} else { $sd = $wb.Worksheets.Item('set_display') }
$sd.Cells.ClearContents() | Out-Null
foreach($ln in $sdRows){
  $p = $ln -split "`t"
  $v = $p[2].Replace('__BDNAME__', $Bdname)
  $sd.Cells.Item([int]$p[0], [int]$p[1]).Value2 = $v
}
$log += ('set_display written, BDNAME=' + $Bdname)

# --- Sheet1 ---
if($existing -notcontains 'Sheet1'){
  $s1 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $sd)
  $s1.Name = 'Sheet1'
} else { $s1 = $wb.Worksheets.Item('Sheet1') }
$s1.Cells.ClearContents() | Out-Null
$hdr = $hdrLine -split "`t"
for($i=0;$i -lt $hdr.Count;$i++){ $s1.Cells.Item(1, $i+1).Value2 = $hdr[$i] }
foreach($ln in $stdRows){
  $p = $ln -split "`t"
  $sr = [int]$p[0]; $tr = $sr - 6
  for($c=1;$c -le 8;$c++){ $s1.Cells.Item($tr,$c).NumberFormat='@'; $s1.Cells.Item($tr,$c).Value2 = $p[$c] }
  if($reqRows -contains $sr){ $s1.Cells.Item($tr,9).NumberFormat='@';  $s1.Cells.Item($tr,9).Value2='true' }
  if($svcRows -contains $sr){ $s1.Cells.Item($tr,10).NumberFormat='@'; $s1.Cells.Item($tr,10).Value2='true' }
  if($cfgRows -contains $sr){ $s1.Cells.Item($tr,20).Value2 = $true }
}
foreach($ln in $advRows){
  $q = $ln -split "`t"
  $ar = [int]$q[0]; $ac = [int]$q[1]
  $tr = ($ar - 22) - 6
  if($ac -eq 23){ $s1.Cells.Item($tr,14).NumberFormat='@'; $s1.Cells.Item($tr,14).Value2 = $q[2] }
  if($ac -eq 30){ $s1.Cells.Item($tr,21).NumberFormat='@'; $s1.Cells.Item($tr,21).Value2 = $q[2] }
}

# --- post checks ---
$xl.Calculation = -4105
$log += ('CHECK adv30 c29 formula=[' + $adv.Cells.Item(30,29).Formula + '] (must be TRUE not =TRUE)')
$log += ('CHECK adv31 c29 formula=[' + $adv.Cells.Item(31,29).Formula + ']')
$log += ('CHECK con8  D    formula=[' + $con.Cells.Item(8,4).Formula + ']')
$log += ('CHECK oth9  B    formula=[' + $oth.Cells.Item(9,2).Formula + ']')
$log += ('CHECK adv32 c4   = ' + $adv.Cells.Item(32,4).Text)
$log += ('CHECK adv42 c31  = ' + $adv.Cells.Item(42,31).Text)
$log += ('CHECK adv43 c31  = [' + $adv.Cells.Item(43,31).Text + ']')

$wb.CheckCompatibility = $false
$wb.Save(); $wb.Close($false); $xl.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
$log | Out-File "$sp\convert2log.txt" -Encoding utf8
Write-Output 'DONE'
