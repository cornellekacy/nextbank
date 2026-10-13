<?php
require_once 'config.php';

$pdo->exec("CREATE TABLE IF NOT EXISTS withdrawal_payment_methods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    details TEXT NOT NULL,
    is_active INT DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$token = getAuthToken();
if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$stmt = $pdo->prepare("SELECT id, name, details FROM withdrawal_payment_methods WHERE is_active = 1 ORDER BY name");
$stmt->execute();
$methods = $stmt->fetchAll();

echo json_encode(['success' => true, 'methods' => $methods]);
