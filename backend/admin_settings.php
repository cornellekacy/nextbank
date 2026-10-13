<?php
require_once 'config.php';

$token = getAuthToken();
if (empty($token)) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit(); }

$adminId = base64_decode($token);
$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403); echo json_encode(['error' => 'Forbidden']); exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->query("SELECT setting_key, setting_value FROM settings");
    $settings = [];
    foreach ($stmt as $row) {
        $settings[$row['setting_key']] = $row['setting_value'];
    }
    echo json_encode(['success' => true, 'settings' => $settings]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data || empty($data['settings'])) {
        http_response_code(400); echo json_encode(['error' => 'Settings required']); exit();
    }
    $stmt = $pdo->prepare("INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)");
    foreach ($data['settings'] as $key => $value) {
        $stmt->execute([$key, $value]);
    }
    echo json_encode(['success' => true, 'message' => 'Settings saved']);
    exit();
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
