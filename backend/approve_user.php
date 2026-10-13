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

$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user || $user['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['user_id']) || empty($data['action'])) {
    http_response_code(400);
    echo json_encode(['error' => 'User ID and action are required']);
    exit();
}

$targetId = $data['user_id'];
$action = $data['action'];
$rejectionReason = $data['rejection_reason'] ?? '';

$allowed = ['approve', 'reject', 'ban', 'unban'];
if (!in_array($action, $allowed)) {
    http_response_code(400);
    echo json_encode(['error' => 'Action must be approve, reject, ban, or unban']);
    exit();
}

$stmt = $pdo->prepare("SELECT name, email, status FROM users WHERE id = ? AND role = 'user'");
$stmt->execute([$targetId]);
$targetUser = $stmt->fetch();

if (!$targetUser) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
    exit();
}

$statusMap = ['approve' => 'approved', 'reject' => 'rejected', 'ban' => 'banned', 'unban' => 'approved'];
$newStatus = $statusMap[$action];

if ($action === 'reject') {
    $stmt = $pdo->prepare("UPDATE users SET status = ?, rejection_reason = ? WHERE id = ? AND role = 'user'");
    $stmt->execute([$newStatus, $rejectionReason, $targetId]);
} else {
    $stmt = $pdo->prepare("UPDATE users SET status = ? WHERE id = ? AND role = 'user'");
    $stmt->execute([$newStatus, $targetId]);
}

$locale = getUserLocale($pdo, $targetId);
$reasonParam = ($action === 'reject' && $rejectionReason) ? " Reason: $rejectionReason" : '';
$translated = notif_trans("account_{$newStatus}", $locale, ['reason' => $reasonParam]);
$title = $translated['title'];
$message = $translated['message'];

createNotification($pdo, $targetId, $title, $message, "account_{$newStatus}", ['reason' => $reasonParam]);
sendPushNotification($pdo, $targetId, $title, $message);

if ($action !== 'ban') {
    $emailBody = "Dear {$targetUser['name']},\n\n" . $message . "\n\nBest regards,\nNextBank Team";
    sendEmail($targetUser['email'], $title, $emailBody);
}

echo json_encode([
    'success' => true,
    'message' => "User has been {$newStatus}",
    'new_status' => $newStatus
]);