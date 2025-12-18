<?php
// MySQL Database Configuration

define('DB_HOST', 'localhost');
define('DB_USER', 'your_mysql_username');
define('DB_PASS', 'your_mysql_password');
define('DB_NAME', 'mmorpg_game');

// API Security
define('API_KEY', 'your_secret_api_key_here');  // Change this!

// CORS Headers (allow Godot to connect)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key');
header('Content-Type: application/json');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Verify API Key
function verify_api_key() {
    $headers = getallheaders();
    if (!isset($headers['X-API-Key']) || $headers['X-API-Key'] !== API_KEY) {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Invalid API key']);
        exit();
    }
}

// Database Connection
function get_db_connection() {
    try {
        $conn = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit();
    }
}

// Get JSON input
function get_json_input() {
    $json = file_get_contents('php://input');
    return json_decode($json, true);
}
?>
