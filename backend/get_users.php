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

if (!$user || $user['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

$status = $_GET['status'] ?? '';

if ($status && $status !== 'all') {
    $stmt = $pdo->prepare("SELECT id, name, email, phone, balance, status, email_verified, rejection_reason, created_at, profile_image, currency FROM users WHERE role = 'user' AND status = ? ORDER BY created_at DESC");
    $stmt->execute([$status]);
} else {
    $stmt = $pdo->prepare("SELECT id, name, email, phone, balance, status, email_verified, rejection_reason, created_at, profile_image, currency FROM users WHERE role = 'user' ORDER BY created_at DESC");
    $stmt->execute();
}

$users = $stmt->fetchAll();

echo json_encode(['users' => $users]);
