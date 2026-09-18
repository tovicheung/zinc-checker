param (
    [string]$Path = $PWD
)

$testcaseDir = Join-Path $Path "testcase"
if (-not (Test-Path $testcaseDir)) {
    Write-Error "Directory 'testcase' not found in '$Path'."
    exit 1
}

# assume one cpp file only
$cppFile = Get-ChildItem -Path $Path -Filter "*.cpp" | Select-Object -First 1

if (-not $cppFile) {
    Write-Error "No .cpp file found in directory '$Path'."
    exit 1
}

$exePath = [System.IO.Path]::ChangeExtension($cppFile.FullName, ".exe")

Write-Host "Compiling $($cppFile.Name)..." -ForegroundColor Cyan
& g++ -std=c++17 $cppFile.FullName -o $exePath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed."
    exit $LASTEXITCODE
}

$inputFiles = Get-ChildItem -Path $testcaseDir -Filter "input*.txt" | Sort-Object Name

if ($inputFiles.Count -eq 0) {
    Write-Warning "No input*.txt files found in '$testcaseDir'."
    exit 0
}

$passed = 0
$total = 0

Write-Host "Running Test Cases..." -ForegroundColor Cyan

foreach ($inputFile in $inputFiles) {
    $total++
    $testId = $inputFile.BaseName -replace '^input', ''
    $outputFileName = "output$testId.txt"
    $outputFile = Join-Path $testcaseDir $outputFileName

    if (-not (Test-Path $outputFile)) {
        Write-Host "[SKIP] Test ${testId}: Missing matching $outputFileName" -ForegroundColor Yellow
        continue
    }

    $actualOutput = Get-Content $inputFile.FullName | &$exePath
    $expectedOutput = Get-Content -Raw $outputFile

    $actualText = ($actualOutput -join "`n").Trim()
    $expectedText = ($expectedOutput -replace "`r`n", "`n").Trim()

    if ($actualText -eq $expectedText) {
        Write-Host "[PASS] Test $testId" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Test $testId" -ForegroundColor Red
    }
}

$summaryColor = if ($passed -eq $total -and $total -gt 0) { "Green" } else { "Red" }

Write-Host "$passed / $total test cases passed." -ForegroundColor $summaryColor
