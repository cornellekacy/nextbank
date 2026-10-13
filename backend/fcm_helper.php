<?php
define('FCM_CA_BUNDLE', function_exists('php_uname') && strtoupper(substr(php_uname('s'), 0, 3)) === 'WIN'
    ? 'C:\xampp1\apache\bin\curl-ca-bundle.crt'
    : '/etc/ssl/certs/ca-certificates.crt');

function _logError($msg) {
    error_log("[FCM] $msg");
}

function getFcmAccessToken() {
    $keyPath = __DIR__ . '/../nextbank-673d1-firebase-adminsdk-fbsvc-25915253b8.json';
    if (!file_exists($keyPath)) {
        _logError('Service account file not found: ' . $keyPath);
        return null;
    }

    $serviceAccount = json_decode(file_get_contents($keyPath), true);
    if (!$serviceAccount) {
        _logError('Failed to parse service account JSON');
        return null;
    }

    $now = time();
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    $payload = [
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now,
    ];

    $base64url = function($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    };

    $jwt = $base64url(json_encode($header)) . '.' . $base64url(json_encode($payload));
    $privateKey = $serviceAccount['private_key'];
    $signature = '';
    $ok = openssl_sign($jwt, $signature, $privateKey, 'sha256WithRSAEncryption');
    if (!$ok) {
        _logError('openssl_sign failed for JWT');
        return null;
    }
    $jwt .= '.' . $base64url($signature);

    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    if (file_exists(FCM_CA_BUNDLE)) {
        curl_setopt($ch, CURLOPT_CAINFO, FCM_CA_BUNDLE);
    }
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt,
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        _logError('cURL error during token exchange: ' . $curlError);
    }
    if ($httpCode !== 200) {
        _logError("OAuth2 token exchange failed: HTTP $httpCode, response: $result");
        return null;
    }

    $data = json_decode($result, true);
    if (!$data || !isset($data['access_token'])) {
        _logError('No access_token in OAuth2 response');
        return null;
    }
    return $data['access_token'];
}

function sendPushNotification($pdo, $userId, $title, $body) {
    $stmt = $pdo->prepare("SELECT device_token FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user || empty($user['device_token'])) {
        _logError("User $userId has no device token");
        return false;
    }

    $deviceToken = $user['device_token'];
    $accessToken = getFcmAccessToken();
    if (!$accessToken) {
        _logError("Failed to get FCM access token for user $userId");
        return false;
    }

    $projectId = json_decode(file_get_contents(__DIR__ . '/../nextbank-673d1-firebase-adminsdk-fbsvc-25915253b8.json'), true)['project_id'];

    $message = [
        'message' => [
            'token' => $deviceToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'android' => [
                'priority' => 'HIGH',
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                    ],
                ],
            ],
        ],
    ];

    $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
    curl_setopt($ch, CURLOPT_POST, true);
    if (file_exists(FCM_CA_BUNDLE)) {
        curl_setopt($ch, CURLOPT_CAINFO, FCM_CA_BUNDLE);
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));

    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        _logError("cURL error sending FCM to user $userId: $curlError");
    }
    if ($httpCode !== 200) {
        _logError("FCM send failed for user $userId: HTTP $httpCode, response: $result");
    }

    return $httpCode === 200;
}
