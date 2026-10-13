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
    $stmt = $pdo->prepare("SELECT l.id, l.amount, l.interest, l.loan_term, l.loan_type, l.reason, l.status, l.rejection_reason, l.created_at, u.name, u.email FROM loans l JOIN users u ON l.user_id = u.id WHERE l.status = ? ORDER BY l.created_at DESC");
    $stmt->execute([$status]);
    echo json_encode(['loans' => $stmt->fetchAll()]);
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data || empty($data['loan_id']) || empty($data['action'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Loan ID and action (approve/reject) are required']);
        exit();
    }
    $action = $data['action'];
    $rejectionReason = $data['rejection_reason'] ?? '';
    if (!in_array($action, ['approve', 'reject'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Action must be approve or reject']);
        exit();
    }
    $status = $action === 'approve' ? 'approved' : 'rejected';
    $stmt = $pdo->prepare("SELECT l.user_id, l.amount, u.name, u.email, u.phone FROM loans l JOIN users u ON l.user_id = u.id WHERE l.id = ? AND l.status = 'pending'");
    $stmt->execute([$data['loan_id']]);
    $loan = $stmt->fetch();

    if (!$loan) {
        http_response_code(404);
        echo json_encode(['error' => 'Loan not found or already processed']);
        exit();
    }

    try {
        $pdo->beginTransaction();

        if ($action === 'reject') {
            $stmt = $pdo->prepare("UPDATE loans SET status = ?, rejection_reason = ? WHERE id = ? AND status = 'pending'");
            $stmt->execute([$status, $rejectionReason, $data['loan_id']]);
        } else {
            $stmt = $pdo->prepare("UPDATE loans SET status = ? WHERE id = ? AND status = 'pending'");
            $stmt->execute([$status, $data['loan_id']]);
            $stmt = $pdo->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
            $stmt->execute([$loan['amount'], $loan['user_id']]);
        }

        $pdo->commit();

        if ($action === 'approve') {
            $locale = getUserLocale($pdo, $loan['user_id']);
            $translated = notif_trans('loan_approved', $locale, ['amount' => $loan['amount']]);
            $msg = $translated['message'];
            createNotification($pdo, $loan['user_id'], $translated['title'], $msg, 'loan_approved', ['amount' => $loan['amount']]);
            try { sendPushNotification($pdo, $loan['user_id'], $translated['title'], $msg); } catch (\Throwable $e) { error_log("[AdminLoan] Push failed: " . $e->getMessage()); }
            try { sendEmail($loan['email'], $translated['title'], "Dear {$loan['name']},\n\n{$msg}\n\nBest regards,\nNextBank Team"); } catch (\Throwable $e) { error_log("[AdminLoan] Email failed: " . $e->getMessage()); }
            try { sendSms($loan['phone'], "NextBank: Your loan of \${$loan['amount']} has been approved and credited."); } catch (\Throwable $e) { error_log("[AdminLoan] SMS failed: " . $e->getMessage()); }
        } else {
            $locale = getUserLocale($pdo, $loan['user_id']);
            $reasonParam = $rejectionReason ? " Reason: $rejectionReason" : '';
            $translated = notif_trans('loan_rejected', $locale, ['amount' => $loan['amount'], 'reason' => $reasonParam]);
            $msg = $translated['message'];
            createNotification($pdo, $loan['user_id'], $translated['title'], $msg, 'loan_rejected', ['amount' => $loan['amount'], 'reason' => $reasonParam]);
            try { sendPushNotification($pdo, $loan['user_id'], $translated['title'], $msg); } catch (\Throwable $e) { error_log("[AdminLoan] Push failed: " . $e->getMessage()); }
            try { sendEmail($loan['email'], $translated['title'], "Dear {$loan['name']},\n\n{$msg}\n\nBest regards,\nNextBank Team"); } catch (\Throwable $e) { error_log("[AdminLoan] Email failed: " . $e->getMessage()); }
            $smsMsg = "NextBank: Your loan application of \${$loan['amount']} has been rejected.";
            if ($rejectionReason) $smsMsg .= " Reason: $rejectionReason";
            try { sendSms($loan['phone'], $smsMsg); } catch (\Throwable $e) { error_log("[AdminLoan] SMS failed: " . $e->getMessage()); }
        }

        echo json_encode(['success' => true, 'message' => "Loan {$status}"]);
    } catch (\Throwable $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to process loan']);
    }
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
