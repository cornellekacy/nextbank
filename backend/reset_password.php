<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);
$email = trim($data['email'] ?? '');
$code = trim($data['code'] ?? '');
$password = $data['password'] ?? '';

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid email address']);
    exit();
}

if (!preg_match('/^\d{6}$/', $code)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid reset code']);
    exit();
}

if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode(['error' => 'Password must be at least 6 characters']);
    exit();
}

$stmt = $pdo->prepare("SELECT * FROM password_resets WHERE email = ? AND code = ? AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1");
$stmt->execute([$email, $code]);
$reset = $stmt->fetch();

if (!$reset) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid or expired reset code']);
    exit();
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $pdo->prepare("UPDATE users SET password = ? WHERE email = ?");
$stmt->execute([$hash, $email]);

$stmt = $pdo->prepare("DELETE FROM password_resets WHERE email = ?");
$stmt->execute([$email]);

echo json_encode(['success' => true, 'message' => 'Password reset successful']);
