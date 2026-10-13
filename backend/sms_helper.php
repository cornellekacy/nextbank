<?php
function getSmsSettings() {
    $host = 'localhost';
    $dbname = 'nextbank_db';
    $user = 'root';
    $pass = '';
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $stmt = $pdo->query("SELECT setting_key, setting_value FROM settings WHERE setting_key IN ('sendchamp_api_key', 'sendchamp_sender_name')");
        $settings = [];
        foreach ($stmt as $row) {
            $settings[$row['setting_key']] = $row['setting_value'];
        }
        return $settings;
    } catch (Exception $e) {
        return [];
    }
}

function sendSms($phone, $message) {
    if (empty($phone)) {
        error_log("[SMS] No phone number provided");
        return false;
    }

    $settings = getSmsSettings();
    $apiKey = $settings['sendchamp_api_key'] ?? '';
    $senderName = $settings['sendchamp_sender_name'] ?? 'NextBank';

    if (empty($apiKey)) {
        error_log("[SMS] Sendchamp API key not configured");
        return false;
    }

    $ch = curl_init('https://api.sendchamp.com/api/v1/sms/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $payload = json_encode([
        'to' => [$phone],
        'message' => $message,
        'sender_name' => $senderName,
        'route' => 'non_dnd',
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);

    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        error_log("[SMS] cURL error: $curlError");
        return false;
    }
    if ($httpCode !== 200) {
        error_log("[SMS] Sendchamp error: HTTP $httpCode, response: $result");
        return false;
    }

    return true;
}
