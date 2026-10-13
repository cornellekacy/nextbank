<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

$stmt = $pdo->prepare("SELECT id, name, email, balance, card_number, card_expiry, card_cvv, role, status, withdrawal_pin, currency, language, profile_image FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
    exit();
}

if ($user['status'] === 'banned') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account has been banned.', 'status' => 'banned']);
    exit();
}

$stmt = $pdo->prepare("SELECT t.id, t.type, t.amount, t.recipient_account, u.name AS recipient_name, t.status, t.created_at, t.payment_method, t.payment_details FROM transactions t LEFT JOIN users u ON t.recipient_account = REPLACE(u.card_number, ' ', '') AND t.type = 'transfer' WHERE t.user_id = ? ORDER BY t.created_at DESC LIMIT 5");
$stmt->execute([$userId]);
$transactions = $stmt->fetchAll();

$stmt = $pdo->prepare("SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as total FROM loans WHERE user_id = ? AND status IN ('approved','pending')");
$stmt->execute([$userId]);
$loanInfo = $stmt->fetch();

echo json_encode([
    'user' => [
        'id' => $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'balance' => $user['balance'],
        'card_number' => $user['card_number'],
        'card_expiry' => $user['card_expiry'],
        'card_cvv' => $user['card_cvv'],
        'role' => $user['role'],
        'status' => $user['status'],
        'has_withdrawal_pin' => !empty($user['withdrawal_pin']),
        'currency' => $user['currency'] ?? 'USD',
        'profile_image' => $user['profile_image'] ?? null,
    ],
    'recent_transactions' => $transactions,
    'loans' => $loanInfo
]);
