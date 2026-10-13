<?php
require_once 'config.php';

$token = getAuthToken();
if (empty($token)) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$userId = base64_decode($token);

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->prepare("SELECT id, name, email, phone, date_of_birth, country, role, status, email_verified, balance, card_number, card_expiry, profile_image, language, currency, created_at FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'User not found']);
        exit();
    }

    echo json_encode(['success' => true, 'user' => $user]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (str_contains($contentType, 'multipart/form-data')) {
        $action = $_POST['action'] ?? '';
    } else {
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $action = $data['action'] ?? $_POST['action'] ?? '';
    }

    if ($action === 'upload_image') {
        if (!isset($_FILES['profile_image']) || $_FILES['profile_image']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            echo json_encode(['error' => 'No image uploaded']);
            exit();
        }

        $file = $_FILES['profile_image'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowed = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (!in_array($ext, $allowed)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid image format']);
            exit();
        }

        if ($file['size'] > 5 * 1024 * 1024) {
            http_response_code(400);
            echo json_encode(['error' => 'Image too large (max 5MB)']);
            exit();
        }

        $dir = __DIR__ . '/uploads/profiles/';
        if (!is_dir($dir)) mkdir($dir, 0755, true);

        $filename = 'profile_' . $userId . '_' . time() . '.' . $ext;
        $filepath = $dir . $filename;
        $webPath = 'uploads/profiles/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $filepath)) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save image']);
            exit();
        }

        $stmt = $pdo->prepare("SELECT profile_image FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $oldImage = $stmt->fetchColumn();

        $stmt = $pdo->prepare("UPDATE users SET profile_image = ? WHERE id = ?");
        $stmt->execute([$webPath, $userId]);

        if ($oldImage && file_exists(__DIR__ . '/' . $oldImage)) {
            @unlink(__DIR__ . '/' . $oldImage);
        }

        echo json_encode(['success' => true, 'profile_image' => $webPath]);
        exit();
    }

    if ($action === 'change_password') {
        $currentPassword = $data['current_password'] ?? '';
        $newPassword = $data['new_password'] ?? '';

        if (empty($currentPassword) || empty($newPassword)) {
            http_response_code(400);
            echo json_encode(['error' => 'Current and new password are required']);
            exit();
        }

        if (strlen($newPassword) < 6) {
            http_response_code(400);
            echo json_encode(['error' => 'New password must be at least 6 characters']);
            exit();
        }

        $stmt = $pdo->prepare("SELECT password FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $currentHash = $stmt->fetchColumn();

        if (!password_verify($currentPassword, $currentHash)) {
            http_response_code(400);
            echo json_encode(['error' => 'Current password is incorrect']);
            exit();
        }

        $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("UPDATE users SET password = ? WHERE id = ?");
        $stmt->execute([$newHash, $userId]);

        echo json_encode(['success' => true, 'message' => 'Password changed successfully']);
        exit();
    }

    if ($action === 'update_profile') {
        $name = trim($data['name'] ?? '');
        $phone = trim($data['phone'] ?? '');
        $dateOfBirth = trim($data['date_of_birth'] ?? '');
        $country = trim($data['country'] ?? '');

        if (empty($name)) {
            http_response_code(400);
            echo json_encode(['error' => 'Name is required']);
            exit();
        }

        $stmt = $pdo->prepare("UPDATE users SET name = ?, phone = ?, date_of_birth = ?, country = ? WHERE id = ?");
        $stmt->execute([$name, $phone, $dateOfBirth, $country, $userId]);

        echo json_encode(['success' => true, 'message' => 'Profile updated successfully']);
        exit();
    }

    if ($action === 'save_language') {
        $language = trim($data['language'] ?? 'en');
        $allowed = ['en','es','fr','ar','pt','de','it','ru','zh','ja','ko'];
        if (!in_array($language, $allowed)) $language = 'en';

        $stmt = $pdo->prepare("UPDATE users SET language = ? WHERE id = ?");
        $stmt->execute([$language, $userId]);

        echo json_encode(['success' => true, 'message' => 'Language saved']);
        exit();
    }

    if ($action === 'save_currency') {
        $currency = strtoupper(trim($data['currency'] ?? 'USD'));
        if (empty($currency) || strlen($currency) > 10) $currency = 'USD';

        $stmt = $pdo->prepare("UPDATE users SET currency = ? WHERE id = ?");
        $stmt->execute([$currency, $userId]);

        echo json_encode(['success' => true, 'message' => 'Currency saved']);
        exit();
    }

    http_response_code(400);
    echo json_encode(['error' => 'Invalid action']);
    exit();
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
