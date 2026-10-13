<?php
require_once 'config.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$token = getAuthToken();
if (empty($token)) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit(); }

$adminId = base64_decode($token);
$stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$adminId]);
$admin = $stmt->fetch();

if (!$admin || $admin['role'] !== 'admin') {
    http_response_code(403); echo json_encode(['error' => 'Forbidden']); exit();
}

$data = json_decode(file_get_contents('php://input'), true);
if (!$data || empty($data['to']) || empty($data['host']) || empty($data['port']) || empty($data['user']) || empty($data['pass'])) {
    http_response_code(400); echo json_encode(['error' => 'to, host, port, user, pass are required']); exit();
}

$mail = new PHPMailer(true);
try {
    $mail->isSMTP();
    $mail->Host = $data['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $data['user'];
    $mail->Password = $data['pass'];
    $mail->SMTPSecure = intval($data['port']) === 465 ? PHPMailer::ENCRYPTION_SMTPS : PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = intval($data['port']);
    $mail->SMTPDebug = 0;

    $mail->setFrom($data['user'], $data['from_name'] ?? 'NextBank');
    $mail->addAddress($data['to']);
    $mail->isHTML(true);
    $mail->Subject = 'SMTP Test from NextBank';
    $mail->Body = '<p>This is a test email from NextBank admin panel.</p><p>Your SMTP settings are working correctly!</p>';

    $mail->send();
    echo json_encode(['success' => true, 'message' => 'Test email sent successfully to ' . $data['to']]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'SMTP test failed: ' . $mail->ErrorInfo]);
}
