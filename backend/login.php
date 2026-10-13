<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['email']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Email/phone and password are required']);
    exit();
}

$emailOrPhone = trim($data['email']);
$password = $data['password'];

$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? OR phone = ?");
$stmt->execute([$emailOrPhone, $emailOrPhone]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid email or password']);
    exit();
}

if ($user['status'] === 'pending') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account is pending admin approval', 'status' => 'pending']);
    exit();
}

if ($user['status'] === 'rejected') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account has been rejected', 'status' => 'rejected']);
    exit();
}

if ($user['status'] === 'banned') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account has been banned. Please contact support.', 'status' => 'banned']);
    exit();
}

echo json_encode([
    'success' => true,
    'user' => [
        'id' => $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'role' => $user['role'],
        'balance' => $user['balance'],
        'card_number' => $user['card_number'],
        'card_expiry' => $user['card_expiry'],
        'card_cvv' => $user['card_cvv'],
        'status' => $user['status'],
        'email_verified' => $user['email_verified'] ?? 0,
        'has_withdrawal_pin' => !empty($user['withdrawal_pin']),
        'currency' => $user['currency'] ?? 'USD',
        'profile_image' => $user['profile_image'] ?? null,
    ]
]);
