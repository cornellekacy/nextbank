<?php
require_once 'config.php';

$token = getAuthToken();

if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$userId = base64_decode($token);

$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user || $user['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $status = $_GET['status'] ?? 'pending';
    $stmt = $pdo->prepare("SELECT t.id, t.amount, t.description, t.status, t.rejection_reason, t.created_at, t.payment_method, t.payment_details, u.name, u.email, u.id as user_id, u.withdrawal_pin FROM transactions t JOIN users u ON t.user_id = u.id WHERE t.type = 'withdraw' AND t.status = ? ORDER BY t.created_at DESC");
    $stmt->execute([$status]);
    echo json_encode(['withdrawals' => $stmt->fetchAll()]);
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data || empty($data['transaction_id']) || empty($data['action'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Transaction ID and action (approve/reject) are required']);
        exit();
    }
    $action = $data['action'];
    $rejectionReason = $data['rejection_reason'] ?? '';
    if (!in_array($action, ['approve', 'reject'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Action must be approve or reject']);
        exit();
    }
    $txId = $data['transaction_id'];

    $stmt = $pdo->prepare("SELECT t.id, t.user_id, t.amount, u.name, u.email, u.phone FROM transactions t JOIN users u ON t.user_id = u.id WHERE t.id = ? AND t.type = 'withdraw' AND t.status = 'pending'");
    $stmt->execute([$txId]);
    $tx = $stmt->fetch();

    if (!$tx) {
        http_response_code(404);
        echo json_encode(['error' => 'Withdrawal not found or already processed']);
        exit();
    }

    try {
        $pdo->beginTransaction();

        if ($action === 'approve') {
            $stmt = $pdo->prepare("UPDATE transactions SET status = 'completed' WHERE id = ?");
            $stmt->execute([$txId]);
        } else {
            $stmt = $pdo->prepare("UPDATE transactions SET status = 'failed', rejection_reason = ? WHERE id = ?");
            $stmt->execute([$rejectionReason, $txId]);
            $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
            $stmt->execute([$tx['amount'], $tx['user_id']]);
        }

        $pdo->commit();

        if ($action === 'approve') {
            $locale = getUserLocale($pdo, $tx['user_id']);
            $translated = notif_trans('withdrawal_approved', $locale, ['amount' => $tx['amount']]);
            $msg = $translated['message'];
            createNotification($pdo, $tx['user_id'], $translated['title'], $msg, 'withdrawal_approved', ['amount' => $tx['amount']]);
            try { sendPushNotification($pdo, $tx['user_id'], $translated['title'], $msg); } catch (\Throwable $e) { error_log("[AdminWithdraw] Push failed: " . $e->getMessage()); }
            try { sendEmail($tx['email'], $translated['title'], "Dear {$tx['name']},\n\n{$msg}\n\nBest regards,\nNextBank Team"); } catch (\Throwable $e) { error_log("[AdminWithdraw] Email failed: " . $e->getMessage()); }
            try { sendSms($tx['phone'], "NextBank: Your withdrawal of \${$tx['amount']} has been approved."); } catch (\Throwable $e) { error_log("[AdminWithdraw] SMS failed: " . $e->getMessage()); }
        } else {
            $locale = getUserLocale($pdo, $tx['user_id']);
            $reasonParam = $rejectionReason ? " Reason: $rejectionReason" : '';
            $translated = notif_trans('withdrawal_rejected', $locale, ['amount' => $tx['amount'], 'reason' => $reasonParam]);
            $msg = $translated['message'];
            createNotification($pdo, $tx['user_id'], $translated['title'], $msg, 'withdrawal_rejected', ['amount' => $tx['amount'], 'reason' => $reasonParam]);
            try { sendPushNotification($pdo, $tx['user_id'], $translated['title'], $msg); } catch (\Throwable $e) { error_log("[AdminWithdraw] Push failed: " . $e->getMessage()); }
            try { sendEmail($tx['email'], $translated['title'], "Dear {$tx['name']},\n\n{$msg}\n\nBest regards,\nNextBank Team"); } catch (\Throwable $e) { error_log("[AdminWithdraw] Email failed: " . $e->getMessage()); }
            $smsMsg = "NextBank: Your withdrawal of \${$tx['amount']} has been rejected.";
            if ($rejectionReason) $smsMsg .= " Reason: $rejectionReason";
            try { sendSms($tx['phone'], $smsMsg); } catch (\Throwable $e) { error_log("[AdminWithdraw] SMS failed: " . $e->getMessage()); }
        }

        echo json_encode(['success' => true, 'message' => "Withdrawal {$action}d"]);
    } catch (\Throwable $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to process withdrawal']);
    }
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
