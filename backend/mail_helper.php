<?php
require_once __DIR__ . '/vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

function getSmtpSettings() {
    $host = 'localhost';
    $dbname = 'nextbank_db';
    $user = 'root';
    $pass = '';
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $stmt = $pdo->query("SELECT setting_key, setting_value FROM settings");
        $settings = [];
        foreach ($stmt as $row) {
            $settings[$row['setting_key']] = $row['setting_value'];
        }
        return $settings;
    } catch (Exception $e) {
        return [];
    }
}

function sendEmail($to, $subject, $body) {
    $settings = getSmtpSettings();
    $host = $settings['smtp_host'] ?? 'smtp.gmail.com';
    $port = intval($settings['smtp_port'] ?? 587);
    $user = $settings['smtp_user'] ?? '';
    $pass = $settings['smtp_pass'] ?? '';
    $fromEmail = $settings['smtp_from_email'] ?? $user ?: 'noreply@nextbank.com';
    $fromName = $settings['smtp_from_name'] ?? 'NextBank';

    if (empty($user) || empty($pass)) {
        error_log("Mail not sent: SMTP credentials not configured");
        return false;
    }

    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host = $host;
        $mail->SMTPAuth = true;
        $mail->Username = $user;
        $mail->Password = $pass;
        $mail->SMTPSecure = $port === 465 ? PHPMailer::ENCRYPTION_SMTPS : PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = $port;

        $mail->setFrom($fromEmail, $fromName);
        $mail->addAddress($to);

        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body = "<!DOCTYPE html><html><head><style>
            body { font-family: Arial, sans-serif; background: #f5f7fa; padding: 20px; }
            .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; padding: 32px; }
            .header { text-align: center; margin-bottom: 24px; }
            .header h1 { color: #1565C0; font-size: 24px; margin: 0; }
            .content { color: #333; line-height: 1.6; }
            .footer { margin-top: 24px; text-align: center; color: #999; font-size: 12px; }
        </style></head><body>
        <div class='container'>
            <div class='header'><h1>NextBank</h1></div>
            <div class='content'>" . nl2br($body) . "</div>
            <div class='footer'>This is an automated message from NextBank. Please do not reply.</div>
        </div></body></html>";

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Mail error: " . $mail->ErrorInfo);
        return false;
    }
}
