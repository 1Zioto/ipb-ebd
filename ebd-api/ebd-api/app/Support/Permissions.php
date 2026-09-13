<?php

namespace App\Support;

/** Catálogo central de permissões (fonte única para seeders e checagens). */
class Permissions
{
    public const ALL = [
        'person.view' => 'Ver pessoas',
        'person.manage' => 'Gerir pessoas',
        'class.view' => 'Ver classes',
        'class.manage' => 'Gerir classes',
        'enrollment.manage' => 'Gerir matrículas',
        'event.view' => 'Ver encontros',
        'event.generate' => 'Gerar calendário',
        'event.create_adhoc' => 'Criar chamada avulsa',
        'event.manage' => 'Gerir encontros',
        'call.view' => 'Ver chamadas',
        'call.perform' => 'Realizar chamada',
        'call.edit' => 'Editar chamada',
        'call.finalize' => 'Finalizar chamada',
        'call.reopen' => 'Reabrir chamada',
        'schedule.view' => 'Ver escalas',
        'schedule.manage' => 'Gerir escalas',
        'superintendent.assign' => 'Definir superintendente',
        'report.view' => 'Ver relatórios',
        'report.export' => 'Exportar relatórios',
        'user.manage' => 'Gerir usuários',
        'role.manage' => 'Gerir papéis',
        'audit.view' => 'Ver auditoria',
        'settings.manage' => 'Gerir configurações',
        'family.view' => 'Ver famílias',
        'family.manage' => 'Gerir famílias',

        // Módulo de Dízimos
        'dizimos.coleta.operar' => 'Operar coletas de dízimos',
        'dizimos.coleta.fechar' => 'Fechar coleta de dízimos',
        'dizimos.coleta.reabrir' => 'Reabrir coleta de dízimos',
        'dizimos.coleta.conferir' => 'Conferir coleta de dízimos',
        'dizimos.historico_individual.view' => 'Ver histórico financeiro individual de membros',
        'dizimos.alertas.manage' => 'Gerir alertas pastorais de dízimos',
        'dizimos.diaconato.atender' => 'Atender solicitações do diaconato',
        'dizimos.config.manage' => 'Gerir configurações de dízimos',
        'dizimos.relatorios.view' => 'Ver relatórios agregados de dízimos',
        'dizimos.relatorios.export' => 'Exportar relatórios de dízimos',

        // Módulo de Instituições & Estrutura Hierárquica
        'institution.view' => 'Ver instituições',
        'institution.manage' => 'Gerir instituições (cadastrar/editar)',
        'institution.tree.view' => 'Ver estrutura em árvore institucional',
        'institution.subordinate.view' => 'Ver instituições subordinadas',
        'institution.consolidated.view' => 'Ver indicadores e relatórios consolidados',
        'institution.transfer' => 'Transferir vínculo de instituição superior',
    ];

    /** Matriz papel => permissões. 'programador' recebe todas via Gate::before. */
    public const ROLE_MATRIX = [
        'programador' => ['*'],
        'pastor' => [
            'person.view', 'family.view', 'family.manage', 'class.view', 'event.view', 'call.view',
            'schedule.view', 'report.view', 'report.export', 'audit.view',
            'dizimos.coleta.operar', 'dizimos.historico_individual.view',
            'dizimos.alertas.manage', 'dizimos.relatorios.view',
            'dizimos.relatorios.export', 'dizimos.config.manage',
            'institution.view', 'institution.tree.view', 'institution.subordinate.view',
            'institution.consolidated.view',
        ],
        'superintendencia' => [
            'person.view', 'person.manage', 'family.view', 'family.manage', 'class.view', 'class.manage', 'enrollment.manage',
            'event.view', 'event.generate', 'event.create_adhoc', 'event.manage',
            'call.view', 'call.perform', 'call.edit', 'call.finalize', 'call.reopen',
            'schedule.view', 'schedule.manage', 'superintendent.assign',
            'report.view', 'report.export', 'audit.view',
            'dizimos.coleta.operar', 'dizimos.coleta.fechar',
            'institution.view', 'institution.manage', 'institution.tree.view',
            'institution.subordinate.view', 'institution.consolidated.view', 'institution.transfer',
        ],
        'diacono' => [
            'person.view', 'family.view',
            'dizimos.coleta.operar', 'dizimos.coleta.fechar', 'dizimos.coleta.conferir',
            'dizimos.diaconato.atender', 'dizimos.relatorios.view',
            'institution.view', 'institution.tree.view',
        ],
        'professor' => [
            'person.view', 'family.view', 'class.view', 'event.view',
            'call.view', 'call.perform', 'call.edit', 'call.finalize',
            'schedule.view', 'report.view',
            'institution.view',
        ],
    ];

    public const ROLES = [
        'programador' => ['Programador', 'Acesso técnico total ao sistema'],
        'pastor' => ['Pastor', 'Acesso pastoral total às informações e alertas de dízimos'],
        'superintendencia' => ['Superintendência', 'Operação total da EBD'],
        'diacono' => ['Diácono / Operador', 'Operação de coletas e atendimento diaconal'],
        'professor' => ['Professor', 'Acesso restrito às classes vinculadas'],
    ];
}
