<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

function env_value(string $name, string $fallback = ''): string {
    $value = getenv($name);
    return $value === false || $value === '' ? $fallback : $value;
}

function probe_tcp(string $host, int $port, float $timeout): bool {
    $errno = 0;
    $error = '';
    $socket = @fsockopen($host, $port, $errno, $error, $timeout);
    if ($socket === false) {
        return false;
    }
    fclose($socket);
    return true;
}

function status_payload(): array {
    $torHost = env_value('ZDOS_TOR_HOST', '127.0.0.1');
    $torPort = (int) env_value('ZDOS_TOR_PORT', '9050');
    $torReachable = probe_tcp($torHost, $torPort, 0.35);
    $node = env_value('ZDOS_NODE', 'unconfigured');
    $domain = env_value('ZDOS_DOMAIN', 'unconfigured');
    $analytics = env_value('ZDOS_ANALYTICS_ID', 'disabled');

    return [
        'node' => $node,
        'domain' => $domain,
        'analytics_id' => $analytics,
        'hypervisor' => env_value('ZDOS_HYPERVISOR_VERSION', 'unknown'),
        'tor' => [
            'host' => $torHost,
            'port' => $torPort,
            'reachable' => $torReachable,
            'status' => $torReachable ? 'reachable' : 'unreachable',
        ],
        'timestamp' => time(),
        'status' => $torReachable ? 'DEGRADED_UNVERIFIED' : 'LOCAL_STATUS_ONLY',
        'disclaimer' => 'La telemetria indica solo raggiungibilita TCP e configurazione locale; non certifica anonimato, cifratura o sicurezza del nodo.',
    ];
}

$action = $_GET['action'] ?? 'status';
if ($action === 'status') {
    echo json_encode(status_payload(), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit;
}

http_response_code(404);
echo json_encode(['error' => 'Command not recognized'], JSON_PRETTY_PRINT);
