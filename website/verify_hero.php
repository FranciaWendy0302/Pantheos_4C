<?php
// Quick verification script for hero account
require_once 'api/config.php';

echo "<!DOCTYPE html>
<html>
<head>
    <title>Hero Account Verification</title>
    <style>
        body { 
            font-family: monospace; 
            background: #1a1a1a; 
            color: #00ff00; 
            padding: 20px; 
            max-width: 800px;
            margin: 0 auto;
        }
        .success { color: #00ff00; }
        .error { color: #ff0000; }
        .info { color: #ffd700; }
        pre { 
            background: #000; 
            padding: 15px; 
            border-left: 3px solid #00ff00;
            overflow-x: auto;
        }
        h1 { color: #ffd700; }
    </style>
</head>
<body>
    <h1>🔍 Hero Account Verification</h1>
";

try {
    $conn = get_db_connection();
    
    // Get hero account
    $stmt = $conn->prepare("SELECT * FROM players WHERE username = 'hero'");
    $stmt->execute();
    $hero = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$hero) {
        echo "<p class='error'>❌ Hero account not found in database!</p>";
        echo "<p class='info'>Run complete_database_setup.sql to create it.</p>";
    } else {
        echo "<p class='success'>✅ Hero account found!</p>";
        echo "<h2>Account Details:</h2>";
        echo "<pre>";
        echo "Player ID: " . $hero['player_id'] . "\n";
        echo "Username: " . $hero['username'] . "\n";
        echo "Nickname: " . $hero['nickname'] . "\n";
        echo "Level: " . $hero['level'] . "\n";
        echo "XP: " . $hero['xp'] . "\n";
        echo "Gold: " . $hero['gold'] . "\n";
        echo "HP: " . $hero['hp'] . " / " . $hero['max_hp'] . "\n";
        echo "MP: " . $hero['mp'] . " / " . $hero['max_mp'] . "\n";
        echo "Position: (" . $hero['position_x'] . ", " . $hero['position_y'] . ")\n";
        echo "Created: " . $hero['created_at'] . "\n";
        echo "Last Login: " . ($hero['last_login'] ?? 'Never') . "\n";
        echo "</pre>";
        
        echo "<h2>Password Hash:</h2>";
        echo "<pre>";
        echo "Hash: " . $hero['password_hash'] . "\n";
        echo "Length: " . strlen($hero['password_hash']) . " characters\n";
        echo "Algorithm: " . substr($hero['password_hash'], 0, 4) . "\n";
        echo "</pre>";
        
        // Test password verification
        echo "<h2>Password Verification Test:</h2>";
        $test_password = "hero123";
        
        if (password_verify($test_password, $hero['password_hash'])) {
            echo "<p class='success'>✅ Password 'hero123' verified successfully!</p>";
            echo "<p class='info'>The hero account is ready to use.</p>";
        } else {
            echo "<p class='error'>❌ Password verification failed!</p>";
            echo "<p class='info'>The password hash may be corrupted or incorrect.</p>";
        }
        
        // Test creating a new hash
        echo "<h2>Bcrypt Test:</h2>";
        $new_hash = password_hash($test_password, PASSWORD_BCRYPT);
        echo "<pre>";
        echo "New hash for 'hero123': " . $new_hash . "\n";
        echo "Verification: " . (password_verify($test_password, $new_hash) ? "✅ PASS" : "❌ FAIL") . "\n";
        echo "</pre>";
        
        echo "<h2>Quick Actions:</h2>";
        echo "<p><a href='test_api.html' style='color: #00ff00;'>→ Open API Test Page</a></p>";
        echo "<p><a href='pantheos-optimized.html' style='color: #00ff00;'>→ Open Main Website</a></p>";
    }
    
} catch (Exception $e) {
    echo "<p class='error'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
}

echo "</body></html>";
?>
