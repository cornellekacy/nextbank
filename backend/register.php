<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$isMultipart = str_contains($contentType, 'multipart/form-data');

if ($isMultipart) {
    $name = trim($_POST['name'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $phone = trim($_POST['phone'] ?? '');
    $country = trim($_POST['country'] ?? '');
    $dateOfBirth = trim($_POST['date_of_birth'] ?? '');
} else {
    $data = json_decode(file_get_contents('php://input'), true);
    $name = trim($data['name'] ?? '');
    $email = trim($data['email'] ?? '');
    $password = $data['password'] ?? '';
    $phone = trim($data['phone'] ?? '');
    $country = trim($data['country'] ?? '');
    $dateOfBirth = trim($data['date_of_birth'] ?? '');
}

if (empty($name) || empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Name, email, and password are required']);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid email format']);
    exit();
}

$stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['error' => 'Email already registered']);
    exit();
}

$hash = password_hash($password, PASSWORD_DEFAULT);

$cardNumber = generateCardNumber();
$expiry = generateExpiry();
$cvv = generateCVV();

$currency = trim($_POST['currency'] ?? ($data['currency'] ?? 'USD'));
if (empty($currency)) $currency = 'USD';

$profileImage = null;
if ($isMultipart && isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] === UPLOAD_ERR_OK) {
    $file = $_FILES['profile_image'];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (in_array($ext, $allowed) && $file['size'] <= 5 * 1024 * 1024) {
        $dir = __DIR__ . '/uploads/profiles/';
        if (!is_dir($dir)) mkdir($dir, 0755, true);
        $filename = 'profile_new_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
        if (move_uploaded_file($file['tmp_name'], $dir . $filename)) {
            $profileImage = 'uploads/profiles/' . $filename;
        }
    }
}

$stmt = $pdo->prepare("INSERT INTO users (name, email, phone, country, date_of_birth, password, card_number, card_expiry, card_cvv, profile_image, currency) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->execute([$name, $email, $phone, $country, $dateOfBirth, $hash, $cardNumber, $expiry, $cvv, $profileImage, $currency]);

$userId = $pdo->lastInsertId();

echo json_encode([
    'success' => true,
    'message' => 'Account created successfully. Please wait for admin approval.',
    'user_id' => $userId
]);
