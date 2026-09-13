<?php

namespace App\Database\Connectors;

use Illuminate\Database\Connectors\PostgresConnector;

class NeonPostgresConnector extends PostgresConnector
{
    protected function getDsn(array $config)
    {
        $dsn = parent::getDsn($config);

        if (! empty($config['endpoint'])) {
            $endpoint = str_replace(["'", ';'], '', (string) $config['endpoint']);
            $dsn .= ";options='endpoint={$endpoint}'";
        }

        return $dsn;
    }
}
