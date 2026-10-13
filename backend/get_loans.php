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

$stmt = $pdo->prepare("SELECT id, amount, interest, loan_term, loan_type, reason, status, rejection_reason, created_at FROM loans WHERE user_id = ? ORDER BY created_at DESC");
$stmt->execute([$userId]);
$loans = $stmt->fetchAll();

echo json_encode(['loans' => $loans]);
