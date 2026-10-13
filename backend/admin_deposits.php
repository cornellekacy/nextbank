<?php
require_once 'config.php';

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

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $status = $_GET['status'] ?? 'pending';
    $stmt = $pdo->prepare("
        SELECT t.*, u.name, u.email, pm.name as payment_method_name
        FROM transactions t
        JOIN users u ON t.user_id = u.id
        LEFT JOIN payment_methods pm ON t.payment_method_id = pm.id
        WHERE t.type = 'deposit' AND t.status = ?
        ORDER BY t.created_at DESC
    ");
    $stmt->execute([$status]);
    echo json_encode(['success' => true, 'deposits' => $stmt->fetchAll()]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $txId = intval($data['transaction_id'] ?? 0);
    $action = $data['action'] ?? '';
    $rejectionReason = $data['rejection_reason'] ?? '';

    if (!$txId || !in_array($action, ['approve', 'reject'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Valid transaction_id and action (approve/reject) required']);
        exit();
    }

    try {
        $pdo->beginTransaction();

        $stmt = $pdo->prepare("SELECT * FROM transactions WHERE id = ? AND type = 'deposit' AND status = 'pending'");
        $stmt->execute([$txId]);
        $tx = $stmt->fetch();

        if (!$tx) {
            http_response_code(404);
            echo json_encode(['error' => 'Pending deposit not found']);
            $pdo->rollBack();
            exit();
        }

        if ($action === 'approve') {
            $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
            $stmt->execute([$tx['amount'], $tx['user_id']]);

            $stmt = $pdo->prepare("UPDATE transactions SET status = 'completed' WHERE id = ?");
            $stmt->execute([$txId]);
        } else {
            $stmt = $pdo->prepare("UPDATE transactions SET status = 'failed', rejection_reason = ? WHERE id = ?");
            $stmt->execute([$rejectionReason, $txId]);
        }

        $stmt = $pdo->prepare("SELECT name, email, phone FROM users WHERE id = ?");
        $stmt->execute([$tx['user_id']]);
        $user = $stmt->fetch();

        $pdo->commit();

        if ($action === 'approve') {
            $locale = getUserLocale($pdo, $tx['user_id']);
            $translated = notif_trans('deposit_approved', $locale, ['amount' => $tx['amount']]);
            $notifTitle = $translated['title'];
            $notifMsg = $translated['message'];
            createNotification($pdo, $tx['user_id'], $notifTitle, $notifMsg, 'deposit_approved', ['amount' => $tx['amount']]);
            $emailMsg = "Dear {$user['name']},\n\nYour deposit of \${$tx['amount']} has been approved and credited to your account.\n\nBest regards,\nNextBank Team";
            try { sendEmail($user['email'], $notifTitle, $emailMsg); } catch (\Throwable $e) { error_log("[AdminDeposit] Email failed: " . $e->getMessage()); }
            try { sendPushNotification($pdo, $tx['user_id'], $notifTitle, $notifMsg); } catch (\Throwable $e) { error_log("[AdminDeposit] Push failed: " . $e->getMessage()); }
            try { sendSms($user['phone'], "NextBank: Your deposit of \${$tx['amount']} has been approved and credited."); } catch (\Throwable $e) { error_log("[AdminDeposit] SMS failed: " . $e->getMessage()); }
            echo json_encode(['success' => true, 'message' => 'Deposit approved']);
        } else {
            $locale = getUserLocale($pdo, $tx['user_id']);
            $reasonParam = $rejectionReason ? " Reason: $rejectionReason" : '';
            $translated = notif_trans('deposit_rejected', $locale, ['amount' => $tx['amount'], 'reason' => $reasonParam]);
            $notifTitle = $translated['title'];
            $notifMsg = $translated['message'];
            createNotification($pdo, $tx['user_id'], $notifTitle, $notifMsg, 'deposit_rejected', ['amount' => $tx['amount'], 'reason' => $reasonParam]);
            $emailMsg = "Dear {$user['name']},\n\nYour deposit request of \${$tx['amount']} has been rejected.";
            if ($rejectionReason) $emailMsg .= " Reason: $rejectionReason";
            $emailMsg .= "\n\nBest regards,\nNextBank Team";
            try { sendEmail($user['email'], $notifTitle, $emailMsg); } catch (\Throwable $e) { error_log("[AdminDeposit] Email failed: " . $e->getMessage()); }
            try { sendPushNotification($pdo, $tx['user_id'], $notifTitle, $notifMsg); } catch (\Throwable $e) { error_log("[AdminDeposit] Push failed: " . $e->getMessage()); }
            $smsMsg = "NextBank: Your deposit of \${$tx['amount']} has been rejected.";
            if ($rejectionReason) $smsMsg .= " Reason: $rejectionReason";
            try { sendSms($user['phone'], $smsMsg); } catch (\Throwable $e) { error_log("[AdminDeposit] SMS failed: " . $e->getMessage()); }
            echo json_encode(['success' => true, 'message' => 'Deposit rejected']);
        }
    } catch (\Throwable $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Operation failed']);
    }
    exit();
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
