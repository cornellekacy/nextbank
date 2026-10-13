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
$ticketId = $data['ticket_id'] ?? 0;

if (!$ticketId) {
    http_response_code(400);
    echo json_encode(['error' => 'Ticket ID is required']);
    exit();
}

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

$stmt = $pdo->prepare("UPDATE support_tickets SET status = 'closed' WHERE id = ?");
$stmt->execute([$ticketId]);

echo json_encode(['success' => true, 'message' => 'Ticket closed']);
