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

if (!$data || empty($data['amount']) || $data['amount'] <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'Valid amount is required']);
    exit();
}

$amount = floatval($data['amount']);
$pin = $data['pin'] ?? '';
$paymentMethod = $data['payment_method'] ?? '';
$paymentDetails = $data['payment_details'] ?? '';

$stmt = $pdo->prepare("SELECT balance, withdrawal_pin, phone, name FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();
$balance = $user['balance'];
$withdrawalPin = $user['withdrawal_pin'];
$phone = $user['phone'];
$userName = $user['name'];

if (empty($withdrawalPin) || $pin !== $withdrawalPin) {
    http_response_code(403);
    echo json_encode(['error' => 'Invalid withdrawal PIN']);
    exit();
}

if ($balance < $amount) {
    http_response_code(400);
    echo json_encode(['error' => 'Insufficient balance']);
    exit();
}

$description = $data['description'] ?? 'Withdrawal';

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
    $stmt->execute([$amount, $userId]);

    $stmt = $pdo->prepare("INSERT INTO transactions (user_id, type, amount, description, status, payment_method, payment_details) VALUES (?, 'withdraw', ?, ?, 'pending', ?, ?)");
    $stmt->execute([$userId, $amount, $description, $paymentMethod, $paymentDetails]);

    $stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $newBalance = $stmt->fetchColumn();

    $stmt = $pdo->prepare("SELECT id, name, email FROM users WHERE role = 'admin'");
    $stmt->execute();
    $admins = $stmt->fetchAll();

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Withdrawal request submitted for approval',
        'balance' => $newBalance
    ]);
    flush();

    $locale = getUserLocale($pdo, $userId);
    $translated = notif_trans('withdrawal_pending', $locale, ['amount' => $amount]);
    createNotification($pdo, $userId, $translated['title'], $translated['message'], 'withdrawal_pending', ['amount' => $amount]);
    try { sendPushNotification($pdo, $userId, $translated['title'], $translated['message']); } catch (\Throwable $e) { error_log("[Withdraw] Push failed: " . $e->getMessage()); }
    try { sendSms($phone, "NextBank: Your withdrawal request of \$$amount has been submitted and is pending admin approval."); } catch (\Throwable $e) { error_log("[Withdraw] SMS failed: " . $e->getMessage()); }

    $adminTitle = 'New Withdrawal Request';
    $paymentInfo = $paymentMethod ? " via $paymentMethod ($paymentDetails)" : '';
    $adminMsg = "$userName has requested a withdrawal of \$$amount{$paymentInfo}. Review and take action.";
    foreach ($admins as $admin) {
        $locale = getUserLocale($pdo, $admin['id']);
        $translated = notif_trans('new_withdrawal', $locale, ['amount' => $amount, 'userName' => $userName, 'paymentInfo' => $paymentInfo]);
        createNotification($pdo, $admin['id'], $translated['title'], $translated['message'], 'new_withdrawal', ['amount' => $amount, 'userName' => $userName, 'paymentInfo' => $paymentInfo]);
        try { sendPushNotification($pdo, $admin['id'], $translated['title'], $translated['message']); } catch (\Throwable $e) { error_log("[Withdraw] Push failed: " . $e->getMessage()); }
    }
} catch (\Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => 'Transaction failed']);
}
