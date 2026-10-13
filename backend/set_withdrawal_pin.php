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

$userId = base64_decode($token);
$data = json_decode(file_get_contents('php://input'), true);
$pin = $data['pin'] ?? '';

if (!preg_match('/^\d{4}$/', $pin)) {
    http_response_code(400);
    echo json_encode(['error' => 'PIN must be exactly 4 digits']);
    exit();
}

$stmt = $pdo->prepare("UPDATE users SET withdrawal_pin = ? WHERE id = ?");
$stmt->execute([$pin, $userId]);

echo json_encode(['success' => true, 'message' => 'Withdrawal PIN set successfully']);
