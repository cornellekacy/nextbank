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

$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$userId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['user_id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'User ID is required']);
    exit();
}

$targetId = $data['user_id'];
$verified = $data['verified'] ?? 1;

$stmt = $pdo->prepare("UPDATE users SET email_verified = ? WHERE id = ? AND role = 'user'");
$stmt->execute([$verified ? 1 : 0, $targetId]);

if ($stmt->rowCount() === 0) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
    exit();
}

$status = $verified ? 'verified' : 'unverified';
echo json_encode([
    'success' => true,
    'message' => "Email has been {$status}"
]);
