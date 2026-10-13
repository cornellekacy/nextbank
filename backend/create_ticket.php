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

if (!$data || empty($data['subject']) || empty($data['message'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Subject and message are required']);
    exit();
}

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("INSERT INTO support_tickets (user_id, subject) VALUES (?, ?)");
    $stmt->execute([$userId, $data['subject']]);
    $ticketId = $pdo->lastInsertId();

    $stmt = $pdo->prepare("INSERT INTO support_messages (ticket_id, sender_id, sender_role, message) VALUES (?, ?, 'user', ?)");
    $stmt->execute([$ticketId, $userId, $data['message']]);

    $stmt = $pdo->prepare("SELECT id, name FROM users WHERE role = 'admin'");
    $stmt->execute();
    $admins = $stmt->fetchAll();
    foreach ($admins as $admin) {
        $locale = getUserLocale($pdo, $admin['id']);
        $translated = notif_trans('new_ticket', $locale, ['userName' => "User #$userId", 'subject' => $data['subject']]);
        createNotification($pdo, $admin['id'], $translated['title'], $translated['message'], 'new_ticket', ['userName' => "User #$userId", 'subject' => $data['subject']]);
        sendPushNotification($pdo, $admin['id'], $translated['title'], $translated['message']);
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'ticket_id' => $ticketId]);
} catch (Exception $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => 'Failed to create ticket']);
}
