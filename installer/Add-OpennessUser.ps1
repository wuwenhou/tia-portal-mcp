# Adds the physically logged-on (console) user to the Siemens TIA Openness group.
# Run from an ELEVATED prompt: right-click -> "Run as administrator".
# Safe to re-run: exits 0 in every case so the Inno installer never reports failure.
$ErrorActionPreference = 'Stop'

try {
  $full = (Get-CimInstance Win32_ComputerSystem).UserName
} catch {
  $full = $null
}

if ([string]::IsNullOrWhiteSpace($full)) {
  Write-Host 'Khong xac dinh duoc user dang dang nhap. Hay chay lai file nay sau khi dang nhap Windows.'
  exit 0
}

# "DOMAIN\user" -> "user" ; ".\user" -> "user"
$user = ($full -split '\\')[-1]

# NOTE: via Start-Process with streams to NUL — a direct `& net ...` call would
# surface native stderr as a terminating error under $ErrorActionPreference='Stop'.
$net = Join-Path $env:SystemRoot 'System32\net.exe'
$outFile = Join-Path $env:TEMP 'tia-openness-net-out.txt'
$errFile = Join-Path $env:TEMP 'tia-openness-net-err.txt'
$proc = Start-Process -FilePath $net -ArgumentList 'localgroup', 'Siemens TIA Openness', $user, '/add' -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
Remove-Item $outFile, $errFile -Force -ErrorAction SilentlyContinue
if ($proc.ExitCode -ne 0) {
  Write-Host "Khong them duoc $user vao nhom (co the do chua cai TIA Portal nen nhom chua ton tai)."
  Write-Host 'Hay cai TIA Portal V17 truoc, roi chay lai file nay bang "Run as administrator".'
  exit 0
}

Write-Host "Da them $user vao nhom 'Siemens TIA Openness'."
Write-Host 'QUAN TRONG: Dang xuat (Sign out) roi dang nhap lai Windows de co hieu luc.'
exit 0
