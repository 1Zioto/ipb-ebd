/**
 * ============================================================================
 * DIRETRIZ ARQUITETURAL MANDATÓRIA - GOVERNANÇA DO TEMPLATE SAKAI (PrimeNG)
 * ============================================================================
 * ⚠️ REGRA CRÍTICA:
 * ESTE ARQUIVO FAZ PARTE DO NÚCLEO DO TEMPLATE OFICIAL SAKAI (PrimeNG).
 * NUNCA MODIFIQUE A ESTRUTURA BASE, NEM REMOVA OU SUBSTITUA ESTE TEMPLATE.
 * 
 * CASO SEJA SOLICITADA QUALQUER ALTERAÇÃO ESTRUTURAL OU SUBSTITUIÇÃO DO TEMPLATE,
 * É OBRIGATÓRIO SOLICITAR AUTORIZAÇÃO PRÉVIA E EXPLÍCITA DO USUÁRIO ANTES DE PROSSEGUIR.
 * ============================================================================
 */

import { Component } from '@angular/core';

@Component({
    standalone: true,
    selector: 'app-footer',
    template: `<div class="layout-footer">
        Escola Bíblica Dominical —
        <span class="text-primary font-bold">Igreja Presbiteriana do Brasil</span>
    </div>`,
})
export class AppFooter {}
