<?php
require_once 'config.php';

$token = getAuthToken();
if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$userId = base64_decode($token);
$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

$stmt = $pdo->prepare("SELECT id, name, details FROM payment_methods WHERE is_active = 1 ORDER BY name");
$stmt->execute();
$methods = $stmt->fetchAll();

echo json_encode(['success' => true, 'methods' => $methods]);
