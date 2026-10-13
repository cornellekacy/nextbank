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

if (!$data || empty($data['amount']) || $data['amount'] <= 0 || empty($data['recipient'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Valid amount and recipient are required']);
    exit();
}

$amount = floatval($data['amount']);
$recipientAccount = trim($data['recipient']);
$description = $data['description'] ?? 'Transfer';

$stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
$stmt->execute([$userId]);
$senderBalance = $stmt->fetchColumn();

if ($senderBalance < $amount) {
    http_response_code(400);
    echo json_encode(['error' => 'Insufficient balance']);
    exit();
}

$stmt = $pdo->prepare("SELECT id FROM users WHERE REPLACE(card_number, ' ', '') = REPLACE(?, ' ', '') AND status = 'approved'");
$stmt->execute([$recipientAccount]);
$recipient = $stmt->fetch();

if (!$recipient) {
    http_response_code(404);
    echo json_encode(['error' => 'Recipient account not found']);
    exit();
}

$recipientId = $recipient['id'];

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
    $stmt->execute([$amount, $userId]);

    $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
    $stmt->execute([$amount, $recipientId]);

    $stmt = $pdo->prepare("INSERT INTO transactions (user_id, type, amount, recipient_account, description) VALUES (?, 'transfer', ?, ?, ?)");
    $stmt->execute([$userId, $amount, $recipientAccount, $description]);

    $stmt = $pdo->prepare("INSERT INTO transactions (user_id, type, amount, recipient_account, description) VALUES (?, 'transfer', ?, ?, ?)");
    $stmt->execute([$recipientId, $amount, $recipientAccount, "Received from account"]);

    $stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $newBalance = $stmt->fetchColumn();

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Transfer successful',
        'balance' => $newBalance
    ]);
} catch (\Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => 'Transaction failed']);
}
