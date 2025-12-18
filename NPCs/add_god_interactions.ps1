# PowerShell script to add god interactions to safezone.tscn

$scenePath = "Levels/final map/scene/safezone.tscn"
$scriptPath = "res://NPCs/god_npc_interaction.gd"

# God configuration
$gods = @{
    "Athena" = @{
        type = 1
        portrait = "res://GUI/god_selection/sprites/athena.png"
        lineStart = 5962
    }
    "Ares" = @{
        type = 6
        portrait = "res://GUI/god_selection/sprites/Ares.png"
        lineStart = 5967
    }
    "Asclepius" = @{
        type = 4
        portrait = "res://GUI/god_selection/sprites/asclepius.png"
        lineStart = 5971
    }
    "Gigantes" = @{
        type = 8
        portrait = "res://GUI/god_selection/sprites/gigantes.png"
        lineStart = 5976
    }
    "Hades" = @{
        type = 5
        portrait = "res://GUI/god_selection/sprites/hades.png"
        lineStart = 5980
    }
    "Titan" = @{
        type = 7
        portrait = "res://GUI/god_selection/sprites/titan.png"
        lineStart = 5984
    }
    "Venus" = @{
        type = 3
        portrait = "res://GUI/god_selection/sprites/venus.png"
        lineStart = 5989
    }
    "Zeus" = @{
        type = 2
        portrait = "res://GUI/god_selection/sprites/zeus.png"
        lineStart = 5993
    }
}

Write-Host "Reading safezone.tscn..." -ForegroundColor Cyan
$content = Get-Content $scenePath

# Check if script resource is already added
$scriptExtResourceExists = $content | Select-String -Pattern 'path="res://NPCs/god_npc_interaction.gd"'

if (-not $scriptExtResourceExists) {
    Write-Host "Adding script ext_resource..." -ForegroundColor Yellow
    
    # Find the last ext_resource line
    $lastExtResourceIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match '^\[ext_resource') {
            $lastExtResourceIndex = $i
        }
    }
    
    if ($lastExtResourceIndex -ge 0) {
        # Insert new ext_resource after the last one
        $newExtResource = '[ext_resource type="Script" path="res://NPCs/god_npc_interaction.gd" id="13_godscript"]'
        $content = $content[0..$lastExtResourceIndex] + $newExtResource + $content[($lastExtResourceIndex + 1)..($content.Count - 1)]
        Write-Host "Script resource added at line $($lastExtResourceIndex + 2)" -ForegroundColor Green
    }
}

# Add CircleShape2D subresource if not exists
$circleShapeExists = $content | Select-String -Pattern 'CircleShape2D.*id="CircleShape2D_godinteract"'

if (-not $circleShapeExists) {
    Write-Host "Adding CircleShape2D subresource..." -ForegroundColor Yellow
    
    # Find where to insert (after last sub_resource)
    $lastSubResourceIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match '^\[sub_resource') {
            $lastSubResourceIndex = $i
            # Find the end of this subresource
            for ($j = $i + 1; $j -lt $content.Count; $j++) {
                if ($content[$j] -match '^\[' -and $content[$j] -notmatch '^\[sub_resource') {
                    $lastSubResourceIndex = $j - 1
                    break
                }
            }
        }
    }
    
    if ($lastSubResourceIndex -ge 0) {
        $newSubResource = @(
            "",
            "[sub_resource type=`"CircleShape2D`" id=`"CircleShape2D_godinteract`"]",
            "radius = 50.0"
        )
        $content = $content[0..$lastSubResourceIndex] + $newSubResource + $content[($lastSubResourceIndex + 1)..($content.Count - 1)]
        Write-Host "CircleShape2D subresource added" -ForegroundColor Green
    }
}

# Now modify each god sprite node
foreach ($godName in $gods.Keys) {
    Write-Host "`nProcessing $godName..." -ForegroundColor Cyan
    
    $godConfig = $gods[$godName]
    $nodePattern = "^\[node name=`"$godName`" type=`"Sprite2D`" parent=`"\.`"\]"
    
    # Find the god node
    $nodeIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $nodePattern) {
            $nodeIndex = $i
            break
        }
    }
    
    if ($nodeIndex -lt 0) {
        Write-Host "  Warning: Could not find $godName node" -ForegroundColor Red
        continue
    }
    
    # Check if script is already attached
    $hasScript = $false
    for ($i = $nodeIndex + 1; $i -lt [Math]::Min($nodeIndex + 10, $content.Count); $i++) {
        if ($content[$i] -match '^\[node name=') {
            break
        }
        if ($content[$i] -match '^script =') {
            $hasScript = $true
            break
        }
    }
    
    if ($hasScript) {
        Write-Host "  $godName already has a script attached, skipping..." -ForegroundColor Yellow
        continue
    }
    
    # Find where to insert script (after texture line)
    $insertIndex = $nodeIndex + 1
    for ($i = $nodeIndex + 1; $i -lt [Math]::Min($nodeIndex + 10, $content.Count); $i++) {
        if ($content[$i] -match '^texture =') {
            $insertIndex = $i + 1
            break
        }
        if ($content[$i] -match '^\[node name=') {
            $insertIndex = $i
            break
        }
    }
    
    # Add script and properties
    $newLines = @(
        "script = ExtResource(`"13_godscript`")",
        "god_type = $($godConfig.type)",
        "god_portrait_path = `"$($godConfig.portrait)`""
    )
    
    $content = $content[0..($insertIndex - 1)] + $newLines + $content[$insertIndex..($content.Count - 1)]
    Write-Host "  Added script to $godName" -ForegroundColor Green
    
    # Now add InteractionArea child node
    # Find the next node after this god
    $nextNodeIndex = -1
    for ($i = $insertIndex + 3; $i -lt $content.Count; $i++) {
        if ($content[$i] -match '^\[node name=') {
            $nextNodeIndex = $i
            break
        }
    }
    
    if ($nextNodeIndex -gt 0) {
        $areaNodeLines = @(
            "",
            "[node name=`"InteractionArea`" type=`"Area2D`" parent=`"$godName`"]",
            "",
            "[node name=`"CollisionShape2D`" type=`"CollisionShape2D`" parent=`"$godName/InteractionArea`"]",
            "shape = SubResource(`"CircleShape2D_godinteract`")"
        )
        
        $content = $content[0..($nextNodeIndex - 1)] + $areaNodeLines + $content[$nextNodeIndex..($content.Count - 1)]
        Write-Host "  Added InteractionArea to $godName" -ForegroundColor Green
    }
}

# Save the modified content
Write-Host "`nSaving modified safezone.tscn..." -ForegroundColor Cyan
$content | Set-Content $scenePath -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SUCCESS! All god interactions added!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nModified file: $scenePath" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Open Godot Editor" -ForegroundColor White
Write-Host "2. Open safezone.tscn to verify changes" -ForegroundColor White
Write-Host "3. Run the game and test god interactions" -ForegroundColor White
