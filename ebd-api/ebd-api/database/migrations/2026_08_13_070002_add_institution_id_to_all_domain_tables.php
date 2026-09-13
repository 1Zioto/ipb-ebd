<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $tables = [
            'people',
            'users',
            'classes',
            'ebd_events',
            'coletas_dizimos',
            'lancamentos_dizimos',
            'consolidacao_dizimos_mensal',
            'alertas_dizimos',
            'acompanhamento_dizimos',
            'solicitacoes_diaconato',
            'auditoria_dizimos',
            'audit_logs',
            'announcements',
        ];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && ! Schema::hasColumn($tableName, 'institution_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->foreignId('institution_id')
                        ->nullable()
                        ->constrained('institutions')
                        ->nullOnDelete();

                    $table->index('institution_id');
                });
            }
        }
    }

    public function down(): void
    {
        $tables = [
            'people',
            'users',
            'classes',
            'ebd_events',
            'coletas_dizimos',
            'lancamentos_dizimos',
            'consolidacao_dizimos_mensal',
            'alertas_dizimos',
            'acompanhamento_dizimos',
            'solicitacoes_diaconato',
            'auditoria_dizimos',
            'audit_logs',
            'announcements',
        ];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'institution_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropForeign(['institution_id']);
                    $table->dropColumn('institution_id');
                });
            }
        }
    }
};
