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

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';

if (strpos($contentType, 'multipart/form-data') !== false) {
    $amount = floatval($_POST['amount'] ?? 0);
    $description = $_POST['description'] ?? 'Deposit';
    $paymentMethodId = $_POST['payment_method_id'] ?? null;
    $proofPath = null;
    if (isset($_FILES['proof']) && $_FILES['proof']['error'] === UPLOAD_ERR_OK) {
        $ext = pathinfo($_FILES['proof']['name'], PATHINFO_EXTENSION);
        $filename = 'proof_' . $userId . '_' . time() . '.' . $ext;
        $dest = __DIR__ . '/uploads/' . $filename;
        if (move_uploaded_file($_FILES['proof']['tmp_name'], $dest)) {
            $proofPath = 'uploads/' . $filename;
        }
    }
} else {
    $data = json_decode(file_get_contents('php://input'), true);
    $amount = floatval($data['amount'] ?? 0);
    $description = $data['description'] ?? 'Deposit';
    $paymentMethodId = $data['payment_method_id'] ?? null;
    $proofPath = null;
}

if ($amount <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'Valid amount is required']);
    exit();
}

$status = ($paymentMethodId || $proofPath) ? 'pending' : 'completed';

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("INSERT INTO transactions (user_id, type, amount, description, payment_method_id, proof_of_payment, status) VALUES (?, 'deposit', ?, ?, ?, ?, ?)");
    $stmt->execute([$userId, $amount, $description, $paymentMethodId, $proofPath, $status]);
    $txId = $pdo->lastInsertId();

    $stmt = $pdo->prepare("SELECT name, email, phone FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if ($status === 'completed') {
        $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
        $stmt->execute([$amount, $userId]);

        $stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $balance = $stmt->fetchColumn();

        $pdo->commit();

        echo json_encode(['success' => true, 'message' => 'Deposit successful', 'balance' => $balance]);
        flush();

        $msg = "A deposit of \${$amount} has been made to your account. New balance: \${$balance}.";
        $locale = getUserLocale($pdo, $userId);
        $translated = notif_trans('deposit_auto', $locale, ['amount' => $amount]);
        createNotification($pdo, $userId, $translated['title'], $translated['message'], 'deposit_auto', ['amount' => $amount]);
        try { sendPushNotification($pdo, $userId, $translated['title'], $translated['message']); } catch (\Throwable $e) { error_log("[Deposit] Push failed: " . $e->getMessage()); }
        try { sendEmail($user['email'], 'Deposit Received', "Dear {$user['name']},\n\n{$msg}\n\nBest regards,\nNextBank Team"); } catch (\Throwable $e) { error_log("[Deposit] Email failed: " . $e->getMessage()); }
        try { sendSms($user['phone'], "NextBank: A deposit of \${$amount} has been made to your account. New balance: \${$balance}."); } catch (\Throwable $e) { error_log("[Deposit] SMS failed: " . $e->getMessage()); }
    } else {
        $stmt = $pdo->prepare("SELECT balance FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $balance = $stmt->fetchColumn();

        $pdo->commit();

        echo json_encode(['success' => true, 'message' => 'Deposit request submitted. Awaiting admin approval.', 'transaction_id' => $txId]);
        flush();

        $locale = getUserLocale($pdo, $userId);
        $translated = notif_trans('deposit_pending', $locale, ['amount' => $amount]);
        $notifTitle = $translated['title'];
        $notifMsg = $translated['message'];
        createNotification($pdo, $userId, $notifTitle, $notifMsg, 'deposit_pending', ['amount' => $amount]);
        try { sendPushNotification($pdo, $userId, $notifTitle, $notifMsg); } catch (\Throwable $e) { error_log("[Deposit] Push failed: " . $e->getMessage()); }

        $emailMsg = "Dear {$user['name']},\n\nYour deposit request of \${$amount} has been submitted successfully.\nIt is now pending admin approval.\n\nBest regards,\nNextBank Team";
        try { sendEmail($user['email'], $notifTitle, $emailMsg); } catch (\Throwable $e) { error_log("[Deposit] Email failed: " . $e->getMessage()); }
        try { sendSms($user['phone'], "NextBank: Your deposit request of \${$amount} has been submitted and is pending review."); } catch (\Throwable $e) { error_log("[Deposit] SMS failed: " . $e->getMessage()); }
    }
} catch (\Throwable $e) {
    $pdo->rollBack();
    if (!empty($proofPath) && file_exists(__DIR__ . '/' . $proofPath)) {
        unlink(__DIR__ . '/' . $proofPath);
    }
    http_response_code(500);
    echo json_encode(['error' => 'Transaction failed']);
}
