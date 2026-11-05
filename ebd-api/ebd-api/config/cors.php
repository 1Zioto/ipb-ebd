<?php

$envOrigins = array_filter(array_map(
    'trim',
    explode(',', (string) env('CORS_ALLOWED_ORIGINS', ''))
));

$defaultOrigins = [
    'http://localhost:4200',
    'https://conciliaipb.vercel.app',
    'https://ebd-web.vercel.app',
    'https://ebd-web-zioto-news.vercel.app',
];

$allOrigins = array_values(array_unique(array_filter(array_merge($defaultOrigins, $envOrigins))));

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => $allOrigins,

    'allowed_origins_patterns' => [
        '#^https://.*\.vercel\.app$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
