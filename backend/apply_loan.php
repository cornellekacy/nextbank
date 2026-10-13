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
$interest = 4.00;
$loanTerm = intval($data['loan_term'] ?? 1);
$loanType = $data['loan_type'] ?? 'Personal';
$reason = $data['reason'] ?? '';

$totalRepayment = $amount + ($amount * ($interest / 100));

$stmt = $pdo->prepare("INSERT INTO loans (user_id, amount, interest, loan_term, loan_type, reason, status) VALUES (?, ?, ?, ?, ?, ?, 'pending')");
$stmt->execute([$userId, $amount, $interest, $loanTerm, $loanType, $reason]);
$loanId = $pdo->lastInsertId();

$stmt = $pdo->prepare("SELECT name FROM users WHERE id = ?");
$stmt->execute([$userId]);
$applicant = $stmt->fetch();
$applicantName = $applicant ? $applicant['name'] : 'A user';

echo json_encode([
    'success' => true,
    'message' => 'Loan application submitted. Pending approval.',
    'loan_id' => $loanId
]);
flush();

$stmt = $pdo->prepare("SELECT id, name, email FROM users WHERE role = 'admin'");
$stmt->execute();
$admins = $stmt->fetchAll();

$title = 'New Loan Application';
$message = "$applicantName has applied for a loan of \$$amount. Review and take action.";
foreach ($admins as $admin) {
    $locale = getUserLocale($pdo, $admin['id']);
    $translated = notif_trans('new_loan', $locale, ['amount' => $amount, 'userName' => $applicantName]);
    createNotification($pdo, $admin['id'], $translated['title'], $translated['message'], 'new_loan', ['amount' => $amount, 'userName' => $applicantName]);
    try { sendPushNotification($pdo, $admin['id'], $translated['title'], $translated['message']); } catch (\Throwable $e) { error_log("[ApplyLoan] Push failed: " . $e->getMessage()); }
    try { sendEmail($admin['email'], $translated['title'], "Dear {$admin['name']},\n\n{$translated['message']}\n\nBest regards,\nNextBank System"); } catch (\Throwable $e) { error_log("[ApplyLoan] Email failed: " . $e->getMessage()); }
}
