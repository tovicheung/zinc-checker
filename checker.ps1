param (
    [string]$Path = $PWD
)

# 1. Locate the single C++ file in the target directory
$cppFile = Get-ChildItem -Path $Path -Filter "*.cpp" | Select-Object -First 1

if (-not $cppFile) {
    Write-Error "No .cpp file found in directory '$Path'."
    exit 1
}

$exePath = [System.IO.Path]::ChangeExtension($cppFile.FullName, ".exe")

# 2. Compile C++ file
Write-Host "Compiling $($cppFile.Name)..." -ForegroundColor Cyan
& g++ -std=c++17 $cppFile.FullName -o $exePath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed."
    exit $LASTEXITCODE
}

# 3. Locate the testcase directory
$testcaseDir = Join-Path $Path "testcase"
if (-not (Test-Path $testcaseDir)) {
    Write-Error "Directory 'testcase' not found in '$Path'."
    exit 1
}

# 4. Iterate over test cases and run checks
$inputFiles = Get-ChildItem -Path $testcaseDir -Filter "input*.txt" | Sort-Object Name

if ($inputFiles.Count -eq 0) {
    Write-Warning "No input*.txt files found in '$testcaseDir'."
    exit 0
}

$passed = 0
$total = 0

Write-Host "Running Test Cases..." -ForegroundColor Cyan

foreach ($inputFile in $inputFiles) {$total++
    # Extract test number/suffix (e.g., input1.txt -> 1)
    $testId =$inputFile.BaseName -replace '^input', ''
    $outputFileName = "output$testId.txt"
    $outputFile = Join-Path $testcaseDir $outputFileName

    if (-not (Test-Path $outputFile)) {
        Write-Host "[SKIP] Test ${testId}: Missing matching$outputFileName" -ForegroundColor Yellow
        continue
    }

    # Stream input into executable and collect output
    $actualOutput = Get-Content $inputFile.FullName | &$exePath
    $expectedOutput = Get-Content -Raw $outputFile

    # Convert output array to a unified string and trim whitespace/newlines
    $actualText = ($actualOutput -join "`n").Trim()
    $expectedText = ($expectedOutput -replace "`r`n", "`n").Trim()

    if ($actualText -eq$expectedText) {
        Write-Host "[PASS] Test $testId" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Test $testId" -ForegroundColor Red
    }
}

# Output Summary
$summaryColor = if ($passed -eq $total -and$total -gt 0) { "Green" } else { "Red" }

Write-Host "----------------------------------------"
Write-Host "Results: $passed / $total test cases passed." -ForegroundColor $summaryColor
Write-Host "----------------------------------------"