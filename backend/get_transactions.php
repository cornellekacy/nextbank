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

$stmt = $pdo->prepare("SELECT status FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if ($user && $user['status'] === 'banned') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account has been banned.', 'status' => 'banned']);
    exit();
}

$page = max(1, intval($_GET['page'] ?? 1));
$limit = 20;
$offset = ($page - 1) * $limit;

$stmt = $pdo->prepare("SELECT t.id, t.type, t.amount, t.recipient_account, u.name AS recipient_name, t.description, t.status, t.rejection_reason, t.created_at, t.payment_method, t.payment_details FROM transactions t LEFT JOIN users u ON t.recipient_account = REPLACE(u.card_number, ' ', '') AND t.type = 'transfer' WHERE t.user_id = ? ORDER BY t.created_at DESC LIMIT $limit OFFSET $offset");
$stmt->execute([$userId]);
$transactions = $stmt->fetchAll();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM transactions WHERE user_id = ?");
$stmt->execute([(int)$userId]);
$total = $stmt->fetchColumn();

echo json_encode([
    'transactions' => $transactions,
    'total' => $total,
    'page' => $page,
    'pages' => ceil($total / $limit)
]);
