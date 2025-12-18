#!/usr/bin/env pwsh

Write-Host "=== God Buff Calculation Debug ===" -ForegroundColor Yellow

$base_attack = 50
$zeus_buff = 0.10  # 10% lightning damage
$buffed_attack = $base_attack * (1 + $zeus_buff)

Write-Host "Base attack: $base_attack" -ForegroundColor White
Write-Host "Zeus buff: $zeus_buff" -ForegroundColor White
Write-Host "Calculation: $base_attack * (1 + $zeus_buff) = $base_attack * $((1 + $zeus_buff)) = $buffed_attack" -ForegroundColor White
Write-Host "Expected: 55.0" -ForegroundColor Green
Write-Host "Actual: $buffed_attack" -ForegroundColor Cyan
Write-Host "Type: $($buffed_attack.GetType().Name)" -ForegroundColor Gray

$difference = [Math]::Abs($buffed_attack - 55.0)
Write-Host "Difference from 55.0: $difference" -ForegroundColor Magenta

if ($buffed_attack -eq 55.0) {
    Write-Host "✅ Exact comparison (== 55.0): TRUE" -ForegroundColor Green
} else {
    Write-Host "❌ Exact comparison (== 55.0): FALSE" -ForegroundColor Red
}

if ($buffed_attack -eq 55) {
    Write-Host "✅ Exact comparison (== 55): TRUE" -ForegroundColor Green
} else {
    Write-Host "❌ Exact comparison (== 55): FALSE" -ForegroundColor Red
}

if ($difference -lt 0.001) {
    Write-Host "✅ Approximate comparison (abs diff < 0.001): TRUE" -ForegroundColor Green
    Write-Host "✅ PASS: God buff applied correctly (+10%)" -ForegroundColor Green
} else {
    Write-Host "❌ Approximate comparison (abs diff < 0.001): FALSE" -ForegroundColor Red
    Write-Host "❌ FAIL: God buff application failed" -ForegroundColor Red
}