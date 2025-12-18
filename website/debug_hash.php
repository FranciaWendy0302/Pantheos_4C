<?php
// Debug password hash compatibility
require_once 'api/config.php';

header('Content-Type: text/plain');

echo "=== PASSWORD HASH DEBUG ===\n\n";

$conn = get_db_connection();

// Get all accounts
$stmt = $conn->prepare("SELECT username, password_hash, created_at FROM players ORDER BY created_at DESC LIMIT 10");
$stmt->execute();
$accounts = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Recent Accounts:\n";
echo str_repeat("-", 80) . "\n";

foreach ($accounts as $account) {
    $hash = $account['password_hash'];
    $hash_type = substr($hash, 0, 4);
    
    echo "Username: " . $account['username'] . "\n";
    echo "Created: " . $account['created_at'] . "\n";
    echo "Hash Type: " . $hash_type . "\n";
    echo "Hash: " . $hash . "\n";
    echo "Length: " . strlen($hash) . "\n";
    
    // Determine source
    if ($hash_type === '$2y$') {
        echo "Source: PHP (password_hash)\n";
    } elseif ($hash_type === '$2b$' || $hash_type === '$2a$') {
        echo "Source: Node.js (bcrypt)\n";
    } else {
        echo "Source: UNKNOWN\n";
    }
    
    echo "\n";
}

echo "\n=== COMPATIBILITY TEST ===\n\n";

// Test password
$test_password = "test123";
echo "Test Password: $test_password\n\n";

// Create PHP hash
$php_hash = password_hash($test_password, PASSWORD_BCRYPT);
echo "PHP Hash ($2y$):\n";
echo "$php_hash\n";
echo "Verify with PHP: " . (password_verify($test_password, $php_hash) ? "✓ PASS" : "✗ FAIL") . "\n\n";

// Simulate Node.js hash (we can't actually create it in PHP, but we can test verification)
echo "Testing cross-compatibility:\n";
echo "PHP can verify $2y$ hashes: " . (password_verify($test_password, $php_hash) ? "✓ YES" : "✗ NO") . "\n";

// Test if PHP can verify $2b$ hashes (if any exist)
$stmt = $conn->prepare("SELECT password_hash FROM players WHERE password_hash LIKE '$2b$%' LIMIT 1");
$stmt->execute();
$nodejs_hash = $stmt->fetch(PDO::FETCH_ASSOC);

if ($nodejs_hash) {
    echo "\nFound Node.js hash in database\n";
    echo "Testing if PHP can verify it...\n";
    // We don't know the original password, so we can't test this properly
    echo "(Cannot test without knowing original password)\n";
}

echo "\n=== SOLUTION ===\n\n";
echo "If accounts created on website don't work in game:\n";
echo "1. The issue is bcrypt version compatibility\n";
echo "2. PHP creates \$2y\$ hashes\n";
echo "3. Node.js bcrypt should accept \$2y\$ hashes\n";
echo "4. If not, we need to update Node.js bcrypt library\n";
echo "5. Or modify PHP to create \$2b\$ hashes\n";

?>
