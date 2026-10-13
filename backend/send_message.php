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

if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['ticket_id']) || empty($data['message'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Ticket ID and message are required']);
    exit();
}

$ticketId = $data['ticket_id'];
$message = $data['message'];

if ($user['role'] === 'admin') {
    $stmt = $pdo->prepare("SELECT * FROM support_tickets WHERE id = ?");
    $stmt->execute([$ticketId]);
} else {
    $stmt = $pdo->prepare("SELECT * FROM support_tickets WHERE id = ? AND user_id = ?");
    $stmt->execute([$ticketId, $userId]);
}

$ticket = $stmt->fetch();
if (!$ticket) {
    http_response_code(404);
    echo json_encode(['error' => 'Ticket not found']);
    exit();
}

if ($ticket['status'] === 'closed') {
    http_response_code(400);
    echo json_encode(['error' => 'Ticket is closed']);
    exit();
}

$senderRole = $user['role'] === 'admin' ? 'admin' : 'user';

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("INSERT INTO support_messages (ticket_id, sender_id, sender_role, message) VALUES (?, ?, ?, ?)");
    $stmt->execute([$ticketId, $userId, $senderRole, $message]);

    $stmt = $pdo->prepare("UPDATE support_tickets SET updated_at = NOW() WHERE id = ?");
    $stmt->execute([$ticketId]);

    if ($senderRole === 'user') {
        $stmt = $pdo->prepare("SELECT id, name FROM users WHERE role = 'admin'");
        $stmt->execute();
        $admins = $stmt->fetchAll();
        foreach ($admins as $admin) {
            $locale = getUserLocale($pdo, $admin['id']);
            $translated = notif_trans('new_ticket_reply', $locale);
            createNotification($pdo, $admin['id'], $translated['title'], $translated['message'], 'new_ticket_reply', []);
            sendPushNotification($pdo, $admin['id'], $translated['title'], $translated['message']);
        }
    } else {
        $stmt = $pdo->prepare("SELECT id, name FROM users WHERE id = ?");
        $stmt->execute([$ticket['user_id']]);
        $ticketUser = $stmt->fetch();
        if ($ticketUser) {
            $locale = getUserLocale($pdo, $ticketUser['id']);
            $translated = notif_trans('new_ticket_reply', $locale);
            createNotification($pdo, $ticketUser['id'], $translated['title'], $translated['message'], 'new_ticket_reply', []);
            sendPushNotification($pdo, $ticketUser['id'], $translated['title'], $translated['message']);
        }
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'message' => 'Message sent']);
} catch (Exception $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => 'Failed to send message']);
}
