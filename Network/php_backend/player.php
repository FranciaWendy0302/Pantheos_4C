<?php
require_once 'config.php';

verify_api_key();

$data = get_json_input();
$action = $data['action'] ?? '';

$conn = get_db_connection();

switch ($action) {
    case 'save_player':
        save_player($conn, $data);
        break;
    
    case 'get_player':
        get_player($conn, $data);
        break;
    
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
        break;
}

function save_player($conn, $data) {
    $player_id = $data['player_id'] ?? 0;
    
    if ($player_id <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid player ID']);
        return;
    }
    
    $stmt = $conn->prepare("
        UPDATE players SET
            level = ?,
            xp = ?,
            gold = ?,
            hp = ?,
            max_hp = ?,
            last_map = ?,
            last_position_x = ?,
            last_position_y = ?,
            inventory = ?,
            quests = ?,
            character_class = ?
        WHERE player_id = ?
    ");
    
    try {
        $stmt->execute([
            $data['level'] ?? 1,
            $data['xp'] ?? 0,
            $data['gold'] ?? 0,
            $data['hp'] ?? 100,
            $data['max_hp'] ?? 100,
            $data['last_map'] ?? '',
            $data['last_position_x'] ?? 0.0,
            $data['last_position_y'] ?? 0.0,
            $data['inventory'] ?? '[]',
            $data['quests'] ?? '[]',
            $data['character_class'] ?? '',
            $player_id
        ]);
        
        echo json_encode(['success' => true, 'message' => 'Player data saved']);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to save player data']);
    }
}

function get_player($conn, $data) {
    $player_id = $data['player_id'] ?? 0;
    
    if ($player_id <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid player ID']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT * FROM players WHERE player_id = ?");
    $stmt->execute([$player_id]);
    
    if ($stmt->rowCount() === 0) {
        echo json_encode(['success' => false, 'error' => 'Player not found']);
        return;
    }
    
    $player = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Parse JSON fields
    $player['inventory'] = json_decode($player['inventory'], true) ?? [];
    $player['quests'] = json_decode($player['quests'], true) ?? [];
    
    // Remove password hash
    unset($player['password_hash']);
    
    echo json_encode([
        'success' => true,
        'player_data' => $player
    ]);
}
?>
