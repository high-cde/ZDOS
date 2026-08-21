<?php
header('Content-Type: application/json');

$action = $_GET['action'] ?? 'status';

if ($action === 'status') {
    $response = [
        "node" => "vmi3082470.contaboserver.net",
        "domain" => "x-zdos.it",
        "analytics_id" => "G-5JVXZ7TYH1",
        "hypervisor" => "v2.5.1 Active",
        "tor_status" => "ONLINE (Port 9050)",
        "timestamp" => time(),
        "status" => "SYSTEM OPERATIONAL"
    ];
    echo json_encode($response, JSON_PRETTY_PRINT);
} else {
    echo json_encode(["error" => "Command not recognized"]);
}
