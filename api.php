<?php
// api.php - Deploy this file to your InfinityFree hosting
// Place at: public_html/api.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$host = 'sql301.infinityfree.com';
$db   = 'if0_41504818_janki';
$user = 'if0_41504818';
$pass = 'Janki123456';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'DB Connection failed: ' . $e->getMessage()]);
    exit;
}

// Create tables if not exist
$pdo->exec("CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','manager','owner','canteen') NOT NULL DEFAULT 'manager',
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");

$pdo->exec("CREATE TABLE IF NOT EXISTS bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    mobile VARCHAR(15),
    batch_type ENUM('full_day','morning','afternoon') NOT NULL,
    guests_above_10 INT DEFAULT 0,
    amount_above_10 DECIMAL(10,2) DEFAULT 0,
    guests_3_to_10 INT DEFAULT 0,
    amount_3_to_10 DECIMAL(10,2) DEFAULT 0,
    food_breakfast TINYINT(1) DEFAULT 1,
    food_lunch TINYINT(1) DEFAULT 1,
    food_high_tea TINYINT(1) DEFAULT 0,
    food_dinner TINYINT(1) DEFAULT 0,
    total_guests INT DEFAULT 0,
    total_amount DECIMAL(10,2) DEFAULT 0,
    payment_mode ENUM('cash','online') DEFAULT 'cash',
    qr_code TEXT,
    booking_date DATE DEFAULT (CURDATE()),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)");

$pdo->exec("CREATE TABLE IF NOT EXISTS workers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50),
    mobile VARCHAR(15),
    salary DECIMAL(10,2) DEFAULT 0,
    joining_date DATE,
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");

// Insert default admin if not exists
$check = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
if ($check == 0) {
    $pdo->exec("INSERT INTO users (username, password, role, name) VALUES
        ('admin', '" . password_hash('admin123', PASSWORD_DEFAULT) . "', 'admin', 'Admin User'),
        ('manager1', '" . password_hash('manager123', PASSWORD_DEFAULT) . "', 'manager', 'Manager One'),
        ('owner1', '" . password_hash('owner123', PASSWORD_DEFAULT) . "', 'owner', 'Owner'),
        ('canteen1', '" . password_hash('canteen123', PASSWORD_DEFAULT) . "', 'canteen', 'Canteen Staff')
    ");
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'login':
        $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
        $stmt->execute([$input['username']]);
        $user = $stmt->fetch();
        if ($user && password_verify($input['password'], $user['password'])) {
            unset($user['password']);
            echo json_encode(['success' => true, 'user' => $user]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid username or password']);
        }
        break;

    case 'getBookings':
        $date = $input['date'] ?? date('Y-m-d');
        $stmt = $pdo->prepare("SELECT * FROM bookings WHERE booking_date = ? ORDER BY created_at DESC");
        $stmt->execute([$date]);
        echo json_encode(['success' => true, 'bookings' => $stmt->fetchAll()]);
        break;

    case 'getAllBookings':
        $stmt = $pdo->query("SELECT * FROM bookings ORDER BY booking_date DESC, created_at DESC");
        echo json_encode(['success' => true, 'bookings' => $stmt->fetchAll()]);
        break;

    case 'getDashboardStats':
        $date = $input['date'] ?? date('Y-m-d');
        $stmt = $pdo->prepare("SELECT 
            COUNT(*) as total_bookings,
            COALESCE(SUM(total_guests), 0) as total_guests,
            COALESCE(SUM(total_amount), 0) as total_revenue,
            COALESCE(SUM(CASE WHEN payment_mode='cash' THEN total_amount ELSE 0 END), 0) as cash_payment,
            COALESCE(SUM(CASE WHEN payment_mode='online' THEN total_amount ELSE 0 END), 0) as online_payment
            FROM bookings WHERE booking_date = ?");
        $stmt->execute([$date]);
        echo json_encode(['success' => true, 'stats' => $stmt->fetch()]);
        break;

    case 'addBooking':
        $stmt = $pdo->prepare("INSERT INTO bookings 
            (customer_name, city, mobile, batch_type, guests_above_10, amount_above_10,
             guests_3_to_10, amount_3_to_10, food_breakfast, food_lunch, food_high_tea, food_dinner,
             total_guests, total_amount, payment_mode, qr_code, booking_date)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
        $stmt->execute([
            $input['customer_name'], $input['city'], $input['mobile'],
            $input['batch_type'], $input['guests_above_10'], $input['amount_above_10'],
            $input['guests_3_to_10'], $input['amount_3_to_10'],
            $input['food_breakfast'] ? 1 : 0, $input['food_lunch'] ? 1 : 0,
            $input['food_high_tea'] ? 1 : 0, $input['food_dinner'] ? 1 : 0,
            $input['total_guests'], $input['total_amount'],
            $input['payment_mode'], $input['qr_code'] ?? null,
            $input['booking_date'] ?? date('Y-m-d')
        ]);
        $id = $pdo->lastInsertId();
        echo json_encode(['success' => true, 'id' => $id, 'message' => 'Booking added successfully']);
        break;

    case 'updateBooking':
        $stmt = $pdo->prepare("UPDATE bookings SET
            customer_name=?, city=?, mobile=?, batch_type=?, guests_above_10=?, amount_above_10=?,
            guests_3_to_10=?, amount_3_to_10=?, food_breakfast=?, food_lunch=?, food_high_tea=?,
            food_dinner=?, total_guests=?, total_amount=?, payment_mode=?
            WHERE id=?");
        $stmt->execute([
            $input['customer_name'], $input['city'], $input['mobile'],
            $input['batch_type'], $input['guests_above_10'], $input['amount_above_10'],
            $input['guests_3_to_10'], $input['amount_3_to_10'],
            $input['food_breakfast'] ? 1 : 0, $input['food_lunch'] ? 1 : 0,
            $input['food_high_tea'] ? 1 : 0, $input['food_dinner'] ? 1 : 0,
            $input['total_guests'], $input['total_amount'], $input['payment_mode'],
            $input['id']
        ]);
        echo json_encode(['success' => true, 'message' => 'Booking updated successfully']);
        break;

    case 'deleteBooking':
        $stmt = $pdo->prepare("DELETE FROM bookings WHERE id = ?");
        $stmt->execute([$input['id']]);
        echo json_encode(['success' => true, 'message' => 'Booking deleted successfully']);
        break;

    case 'getWorkers':
        $stmt = $pdo->query("SELECT * FROM workers ORDER BY name ASC");
        echo json_encode(['success' => true, 'workers' => $stmt->fetchAll()]);
        break;

    case 'addWorker':
        $stmt = $pdo->prepare("INSERT INTO workers (name, role, mobile, salary, joining_date, status) VALUES (?,?,?,?,?,?)");
        $stmt->execute([
            $input['name'], $input['role'], $input['mobile'],
            $input['salary'], $input['joining_date'] ?? date('Y-m-d'), $input['status'] ?? 'active'
        ]);
        echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    case 'updateWorker':
        $stmt = $pdo->prepare("UPDATE workers SET name=?, role=?, mobile=?, salary=?, status=? WHERE id=?");
        $stmt->execute([$input['name'], $input['role'], $input['mobile'], $input['salary'], $input['status'], $input['id']]);
        echo json_encode(['success' => true, 'message' => 'Worker updated']);
        break;

    case 'deleteWorker':
        $stmt = $pdo->prepare("DELETE FROM workers WHERE id = ?");
        $stmt->execute([$input['id']]);
        echo json_encode(['success' => true, 'message' => 'Worker deleted']);
        break;

    default:
        echo json_encode(['success' => false, 'message' => 'Unknown action: ' . $action]);
}
?>
