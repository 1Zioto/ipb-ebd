<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

Route::get('/', function (Request $request) {
    // Se o cliente explicitamente solicita JSON (ex: chamadas de API, bots, testes)
    if ($request->wantsJson()) {
        return response()->json([
            'system' => 'CONCÍLIA IPB API',
            'status' => 'operational',
            'version' => '1.0.0',
            'church' => 'Igreja Presbiteriana do Brasil',
        ]);
    }

    // Para qualquer navegador (dispositivos móveis ou desktop):
    // Carrega diretamente o aplicativo Flutter compilado para web (sem prompt ou link de download de APK)
    $flutterIndex = public_path('index.html');
    if (file_exists($flutterIndex)) {
        return response()->file($flutterIndex, [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Cache-Control' => 'no-cache, private'
        ]);
    }

    return response()->json([
        'system' => 'CONCÍLIA IPB API',
        'status' => 'operational',
    ]);
});

Route::get('/app', function () {
    $flutterIndex = public_path('index.html');
    if (file_exists($flutterIndex)) {
        return response()->file($flutterIndex, [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Cache-Control' => 'no-cache, private'
        ]);
    }
    return redirect('/');
});

Route::get('/mobile', function () {
    $flutterIndex = public_path('index.html');
    if (file_exists($flutterIndex)) {
        return response()->file($flutterIndex, [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Cache-Control' => 'no-cache, private'
        ]);
    }
    return redirect('/');
});
