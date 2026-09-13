<?php

declare(strict_types=1);

foreach (['/tmp/views', '/tmp/sessions', '/tmp/cache'] as $directory) {
    if (! is_dir($directory)) {
        mkdir($directory, 0755, true);
    }
}

// The Vercel runtime executes this router from /api/index.php. Normalize the
// front-controller path so Symfony keeps the public /api prefix in requests.
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';

require __DIR__.'/../public/index.php';
