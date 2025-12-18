<?php
require_once 'config.php';

verify_api_key();

$data = get_json_input();
$action = $data['action'] ?? '';

$conn = get_db_connection();

switch ($action) {
    case 'log_trade':
        log_trade($conn, $data);
        break;
    
    case 'get_trade_history':
        get_trade_history($conn, $data);
        break;
    
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
        break;
}

function log_trade($conn, $data) {
    $from_player_id = $data['from_player_id'] ?? 0;
    $to_player_id = $data['to_player_id'] ?? 0;
    $item_id = $data['item_id'] ?? '';
    $quantity = $data['quantity'] ?? 0;
    $gold_amount = $data['gold_amount'] ?? 0;
    
    if ($from_player_id <= 0 || $to_player_id <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid player IDs']);
        return;
    }
    
    $stmt = $conn->prepare("
        INSERT INTO trades (from_player_id, to_player_id, item_id, quantity, gold_amount)
        VALUES (?, ?, ?, ?, ?)
    ");
    
    try {
        $stmt->execute([$from_player_id, $to_player_id, $item_id, $quantity, $gold_amount]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Trade logged',
            'trade_id' => $conn->lastInsertId()
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to log trade']);
    }
}

function get_trade_history($conn, $data) {
    $player_id = $data['player_id'] ?? 0;
    $limit = $data['limit'] ?? 10;
    
    if ($player_id <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid player ID']);
        return;
    }
    
    $stmt = $conn->prepare("
        SELECT t.*, 
               p1.username as from_username, 
               p2.username as to_username
        FROM trades t
        JOIN players p1 ON t.from_player_id = p1.player_id
        JOIN players p2 ON t.to_player_id = p2.player_id
        WHERE t.from_player_id = ? OR t.to_player_id = ?
        ORDER BY t.trade_date DESC
        LIMIT ?
    ");
    
    $stmt->execute([$player_id, $player_id, $limit]);
    $trades = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'trades' => $trades
    ]);
}
?>
