<?php
require_once 'config.php';

verify_api_key();

$data = get_json_input();
$action = $data['action'] ?? '';

$conn = get_db_connection();

switch ($action) {
    case 'create_account':
        create_account($conn, $data);
        break;
    
    case 'login':
        login($conn, $data);
        break;
    
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
        break;
}

function create_account($conn, $data) {
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
    $nickname = $data['nickname'] ?? '';
    
    if (empty($username) || empty($password) || empty($nickname)) {
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        return;
    }
    
    // Check if username exists
    $stmt = $conn->prepare("SELECT player_id FROM players WHERE username = ?");
    $stmt->execute([$username]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'Username already exists']);
        return;
    }
    
    // Hash password
    $password_hash = password_hash($password, PASSWORD_BCRYPT);
    
    // Create account
    $stmt = $conn->prepare("
        INSERT INTO players (username, password_hash, nickname, inventory, quests)
        VALUES (?, ?, ?, '[]', '[]')
    ");
    
    try {
        $stmt->execute([$username, $password_hash, $nickname]);
        $player_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Account created successfully',
            'player_id' => $player_id
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to create account']);
    }
}

function login($conn, $data) {
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        echo json_encode(['success' => false, 'error' => 'Missing credentials']);
        return;
    }
    
    // Get player data
    $stmt = $conn->prepare("SELECT * FROM players WHERE username = ?");
    $stmt->execute([$username]);
    
    if ($stmt->rowCount() === 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid username or password']);
        return;
    }
    
    $player = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Verify password
    if (!password_verify($password, $player['password_hash'])) {
        echo json_encode(['success' => false, 'error' => 'Invalid username or password']);
        return;
    }
    
    // Update last login
    $update_stmt = $conn->prepare("UPDATE players SET last_login = NOW() WHERE player_id = ?");
    $update_stmt->execute([$player['player_id']]);
    
    // Parse JSON fields
    $player['inventory'] = json_decode($player['inventory'], true) ?? [];
    $player['quests'] = json_decode($player['quests'], true) ?? [];
    
    // Remove password hash from response
    unset($player['password_hash']);
    
    echo json_encode([
        'success' => true,
        'player_data' => $player
    ]);
}
?>
