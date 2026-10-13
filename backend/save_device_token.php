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

if (!$data || empty($data['device_token'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Device token is required']);
    exit();
}

$stmt = $pdo->prepare("UPDATE users SET device_token = ? WHERE id = ?");
$stmt->execute([$data['device_token'], $userId]);

echo json_encode(['success' => true]);
