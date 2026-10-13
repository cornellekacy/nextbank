<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

$token = getAuthToken();
if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$adminId = base64_decode($token);
$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Admin access required']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);
$userId = intval($data['user_id'] ?? 0);
$pin = $data['pin'] ?? '';

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid user ID']);
    exit();
}

if (!preg_match('/^\d{4}$/', $pin)) {
    http_response_code(400);
    echo json_encode(['error' => 'PIN must be exactly 4 digits']);
    exit();
}

$stmt = $pdo->prepare("UPDATE users SET withdrawal_pin = ? WHERE id = ?");
$stmt->execute([$pin, $userId]);

echo json_encode(['success' => true, 'message' => 'Withdrawal PIN reset successfully']);
