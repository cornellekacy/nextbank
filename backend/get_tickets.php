<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

$status = $_GET['status'] ?? 'open';

if ($user['role'] === 'admin') {
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as user_name, u.email as user_email,
            (SELECT message FROM support_messages WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) as last_message,
            0 as unread
        FROM support_tickets t JOIN users u ON t.user_id = u.id
        WHERE t.status = ?
        ORDER BY t.updated_at DESC
    ");
    $stmt->execute([$status]);
} else {
    $stmt = $pdo->prepare("
        SELECT t.*,
            (SELECT message FROM support_messages WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) as last_message,
            0 as unread
        FROM support_tickets t
        WHERE t.user_id = ? AND t.status = ?
        ORDER BY t.updated_at DESC
    ");
    $stmt->execute([$userId, $status]);
}

echo json_encode(['tickets' => $stmt->fetchAll()]);
