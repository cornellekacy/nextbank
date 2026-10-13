<?php
require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);
$email = trim($data['email'] ?? '');

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid email address']);
    exit();
}

$stmt = $pdo->prepare("SELECT id, name FROM users WHERE email = ?");
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'No account found with this email']);
    exit();
}

$pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
)");

$stmt = $pdo->prepare("DELETE FROM password_resets WHERE email = ?");
$stmt->execute([$email]);

$code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$expires = date('Y-m-d H:i:s', time() + 900);

$stmt = $pdo->prepare("INSERT INTO password_resets (email, code, expires_at) VALUES (?, ?, ?)");
$stmt->execute([$email, $code, $expires]);

$subject = 'Password Reset Code';
$body = "Dear {$user['name']},\n\nYour password reset code is: $code\n\nThis code will expire in 15 minutes.\n\nIf you did not request a password reset, please ignore this email.\n\nBest regards,\nNextBank Team";
sendEmail($email, $subject, $body);

echo json_encode(['success' => true, 'message' => 'Password reset code sent to your email']);
