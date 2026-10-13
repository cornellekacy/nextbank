<?php
require_once 'config.php';

$token = getAuthToken();
if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$adminId = base64_decode($token);
$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $stmt = $pdo->query("SELECT id, name, details, is_active FROM payment_methods ORDER BY name");
    echo json_encode(['success' => true, 'methods' => $stmt->fetchAll()]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (empty($data['name']) || empty($data['details'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Name and details are required']);
        exit();
    }
    $stmt = $pdo->prepare("INSERT INTO payment_methods (name, details, is_active) VALUES (?, ?, ?)");
    $stmt->execute([$data['name'], $data['details'], $data['is_active'] ?? 1]);
    echo json_encode(['success' => true, 'message' => 'Payment method added']);
    exit();
}

if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'ID is required']);
        exit();
    }
    $fields = [];
    $params = [];
    foreach (['name', 'details', 'is_active'] as $f) {
        if (isset($data[$f])) {
            $fields[] = "$f = ?";
            $params[] = $data[$f];
        }
    }
    if (empty($fields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        exit();
    }
    $params[] = $data['id'];
    $stmt = $pdo->prepare("UPDATE payment_methods SET " . implode(', ', $fields) . " WHERE id = ?");
    $stmt->execute($params);
    echo json_encode(['success' => true, 'message' => 'Payment method updated']);
    exit();
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID is required']);
        exit();
    }
    $stmt = $pdo->prepare("DELETE FROM payment_methods WHERE id = ?");
    $stmt->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Payment method deleted']);
    exit();
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
