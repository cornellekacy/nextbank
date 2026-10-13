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

$stmt = $pdo->prepare("SELECT status FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

if ($user && $user['status'] === 'banned') {
    http_response_code(403);
    echo json_encode(['error' => 'Your account has been banned.', 'status' => 'banned']);
    exit();
}

$locale = getUserLocale($pdo, $userId);

$stmt = $pdo->prepare("SELECT id, title, message, type, params_json, is_read, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50");
$stmt->execute([$userId]);
$notifications = $stmt->fetchAll();

foreach ($notifications as &$n) {
    if (!empty($n['type']) && !empty($n['params_json'])) {
        $params = json_decode($n['params_json'], true);
        if (is_array($params)) {
            $translated = notif_trans($n['type'], $locale, $params);
            if ($translated) {
                $n['title'] = $translated['title'];
                $n['message'] = $translated['message'];
            }
        }
    } elseif (!empty($n['type'])) {
        $translated = notif_trans($n['type'], $locale);
        if ($translated) {
            $n['title'] = $translated['title'];
            $n['message'] = $translated['message'];
        }
    }
    unset($n['params_json']);
}
unset($n);

$stmt = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
$stmt->execute([$userId]);
$unreadCount = $stmt->fetchColumn();

echo json_encode([
    'notifications' => $notifications,
    'unread_count' => (int)$unreadCount
]);
