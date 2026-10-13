<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = 'localhost';
$dbname = 'nextbank_db';
$user = 'root';
$pass = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit();
}

require_once 'fcm_helper.php';
require_once 'mail_helper.php';
require_once 'sms_helper.php';
require_once 'notifications_helper.php';

function getAuthToken() {
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    return $auth;
}

function createNotification($pdo, $userId, $title, $message, $type, $params = []) {
    $paramsJson = !empty($params) ? json_encode($params, JSON_UNESCAPED_UNICODE) : null;
    $stmt = $pdo->prepare("INSERT INTO notifications (user_id, title, message, type, params_json) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$userId, $title, $message, $type, $paramsJson]);
}

function generateCardNumber() {
    $prefixes = ['51', '52', '53', '54', '55'];
    $number = $prefixes[array_rand($prefixes)];
    for ($i = 0; $i < 14; $i++) {
        $number .= random_int(0, 9);
    }
    return implode(' ', str_split($number, 4));
}

function generateExpiry() {
    $month = str_pad(random_int(1, 12), 2, '0', STR_PAD_LEFT);
    $year = date('y') + random_int(1, 5);
    return "$month/$year";
}

function generateCVV() {
    return str_pad(random_int(0, 999), 3, '0', STR_PAD_LEFT);
}
