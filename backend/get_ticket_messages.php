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
$ticketId = $_GET['ticket_id'] ?? 0;

if (!$ticketId) {
    http_response_code(400);
    echo json_encode(['error' => 'Ticket ID is required']);
    exit();
}

$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if (!$user) {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
    exit();
}

if ($user['role'] === 'admin') {
    $stmt = $pdo->prepare("SELECT t.*, u.name as user_name, u.email as user_email, u.phone as user_phone FROM support_tickets t JOIN users u ON t.user_id = u.id WHERE t.id = ?");
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

$stmt = $pdo->prepare("SELECT sm.*, u.name as sender_name FROM support_messages sm JOIN users u ON sm.sender_id = u.id WHERE sm.ticket_id = ? ORDER BY sm.created_at ASC");
$stmt->execute([$ticketId]);
$messages = $stmt->fetchAll();

echo json_encode([
    'ticket' => $ticket,
    'messages' => $messages,
]);
