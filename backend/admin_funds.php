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

$adminId = base64_decode($token);

$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['user_id']) || empty($data['amount']) || $data['amount'] <= 0 || !in_array($data['type'], ['add', 'deduct'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Valid user_id, amount, and type (add/deduct) are required']);
    exit();
}

$targetUserId = intval($data['user_id']);
$amount = floatval($data['amount']);
$type = $data['type'];
$description = $data['description'] ?? ($type === 'add' ? 'Admin credit' : 'Admin debit');

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("SELECT name, email, phone, balance FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'User not found']);
        $pdo->rollBack();
        exit();
    }

    if ($type === 'add') {
        $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
        $stmt->execute([$amount, $targetUserId]);
    } else {
        if ($user['balance'] < $amount) {
            http_response_code(400);
            echo json_encode(['error' => 'Insufficient balance']);
            $pdo->rollBack();
            exit();
        }
        $stmt = $pdo->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
        $stmt->execute([$amount, $targetUserId]);
    }

    $txType = $type === 'add' ? 'deposit' : 'withdraw';
    $stmt = $pdo->prepare("INSERT INTO transactions (user_id, type, amount, description) VALUES (?, ?, ?, ?)");
    $stmt->execute([$targetUserId, $txType, $amount, $description]);

    $stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $newBalance = $stmt->fetchColumn();

    $locale = getUserLocale($pdo, $targetUserId);
    $fundType = $type === 'add' ? 'credit' : 'debit';
    $translated = notif_trans($fundType, $locale, ['amount' => $amount]);
    $notifTitle = $translated['title'];
    $notifMsg = $translated['message'];
    createNotification($pdo, $targetUserId, $notifTitle, $notifMsg, $fundType, ['amount' => $amount]);

    $pdo->commit();

    $actionLabel = $type === 'add' ? 'credited' : 'debited';
    $emailMsg = "Dear {$user['name']},\n\nYour account has been {$actionLabel} with \${$amount} by admin.\nNew balance: \${$newBalance}\nNote: {$description}\n\nBest regards,\nNextBank Team";
    try { sendEmail($user['email'], $notifTitle, $emailMsg); } catch (Exception $e) { _logError("sendEmail failed: " . $e->getMessage()); }
    try { sendPushNotification($pdo, $targetUserId, $notifTitle, $notifMsg); } catch (Exception $e) { _logError("sendPushNotification failed: " . $e->getMessage()); }
    try { sendSms($user['phone'], "NextBank: Your account has been {$actionLabel} with \${$amount}. New balance: \${$newBalance}."); } catch (Exception $e) { _logError("sendSms failed: " . $e->getMessage()); }

    echo json_encode([
        'success' => true,
        'message' => 'User account ' . ($type === 'add' ? 'credited' : 'debited') . ' successfully',
        'balance' => $newBalance
    ]);
} catch (Exception $e) {
    $pdo->rollBack();
    _logError("admin_funds transaction failed: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Transaction failed']);
}
