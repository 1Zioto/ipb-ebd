<?php

namespace Database\Seeders;

use App\Models\CotaConciliar;
use App\Models\EscalaDiacono;
use App\Models\OrcamentoAnualLinha;
use App\Models\OrdemServicoDiaconia;
use App\Models\ParecerExameContas;
use App\Models\PatrimonioBem;
use App\Models\Person;
use App\Models\ProcessoDisciplinar;
use Illuminate\Database\Seeder;

class DisciplinaDiaconiaCotasExameSeeder extends Seeder
{
    public function run(): void
    {
        $people = Person::take(10)->get();
        if ($people->isEmpty()) {
            return;
        }

        $p1 = $people->first();
        $p2 = $people->count() > 1 ? $people->get(1) : $p1;
        $p3 = $people->count() > 2 ? $people->get(2) : $p1;

        // 1. Processos Disciplinares
        if (ProcessoDisciplinar::count() === 0) {
            ProcessoDisciplinar::create([
                'institution_id' => 5,
                'person_id' => $p1->id,
                'numero_processo' => 'PROC-2026/001',
                'tipo_falta' => 'Abandono de Comunhão',
                'descricao_falta' => 'Ausência injustificada dos cultos e sacramentos por mais de 12 meses consecutivos.',
                'medida_disciplinar' => 'Suspensão dos Sacramentos',
                'data_abertura' => '2026-02-15',
                'data_julgamento' => '2026-03-10',
                'prazo_meses' => 6,
                'relator_presbitero' => 'Presb. Antônio Marcos',
                'status' => 'Cumprindo Disciplina',
                'observacoes_pastorais' => 'Comissão pastoral realizou duas visitas prévias. O irmão manifestou desejo de retorno após período de reflexão.',
            ]);

            ProcessoDisciplinar::create([
                'institution_id' => 5,
                'person_id' => $p2->id,
                'numero_processo' => 'PROC-2026/002',
                'tipo_falta' => 'Conduta',
                'descricao_falta' => 'Divergência pública desarmônica com liderança departamental.',
                'medida_disciplinar' => 'Sob Admoestação',
                'data_abertura' => '2026-06-05',
                'data_julgamento' => '2026-06-20',
                'prazo_meses' => 3,
                'relator_presbitero' => 'Presb. Carlos Eduardo',
                'status' => 'Restaurado',
                'data_restauracao' => '2026-09-20',
                'observacoes_pastorais' => 'O irmão compareceu perante o Conselho, apresentou escusas e a comunhão foi plenamente restabelecida com oração.',
            ]);
        }

        // 2. Livro Tombo / Patrimônio
        if (PatrimonioBem::count() === 0) {
            $bens = [
                [
                    'numero_tombamento' => 'TOMBO-0001',
                    'nome' => 'Mesa de Som Digital Behringer X32',
                    'categoria' => 'Som & Áudio',
                    'localizacao' => 'Templo Principal - Cabine de Som',
                    'data_aquisicao' => '2024-03-15',
                    'valor_aquisicao' => 14500.00,
                    'valor_atual' => 13200.00,
                    'estado_conservacao' => 'Excelente',
                    'status' => 'Ativo',
                    'nota_fiscal' => 'NF-984321',
                    'descricao' => 'Mesa digital 32 canais, utilizada nos cultos solenes e transmissões.',
                    'responsavel_diacono' => 'Diác. Marcos Vinícius',
                ],
                [
                    'numero_tombamento' => 'TOMBO-0002',
                    'nome' => 'Projetor Laser Epson PowerLite 5000 Lumens',
                    'categoria' => 'Projeção & Multimídia',
                    'localizacao' => 'Templo Principal - Altar Central',
                    'data_aquisicao' => '2023-11-10',
                    'valor_aquisicao' => 7800.00,
                    'valor_atual' => 6400.00,
                    'estado_conservacao' => 'Bom',
                    'status' => 'Ativo',
                    'nota_fiscal' => 'NF-112093',
                    'descricao' => 'Projetor central para liturgia, hinos e pregação.',
                    'responsavel_diacono' => 'Diác. Daniel Rocha',
                ],
                [
                    'numero_tombamento' => 'TOMBO-0003',
                    'nome' => 'Piano Digital Yamaha Clavinova CLP-735',
                    'categoria' => 'Instrumentos Musicais',
                    'localizacao' => 'Templo Principal',
                    'data_aquisicao' => '2022-08-20',
                    'valor_aquisicao' => 12900.00,
                    'valor_atual' => 11000.00,
                    'estado_conservacao' => 'Excelente',
                    'status' => 'Ativo',
                    'nota_fiscal' => 'NF-74621',
                    'descricao' => 'Piano para execução dos prelúdios, hinos do Novo Cântico e pós-lúdios.',
                    'responsavel_diacono' => 'Diác. Paulo Ferreira',
                ],
                [
                    'numero_tombamento' => 'TOMBO-0004',
                    'nome' => 'Ar Condicionado Split Inverter 60.000 BTUs',
                    'categoria' => 'Climatização',
                    'localizacao' => 'Templo Principal - Lado Esquerdo',
                    'data_aquisicao' => '2024-01-05',
                    'valor_aquisicao' => 9400.00,
                    'valor_atual' => 8900.00,
                    'estado_conservacao' => 'Bom',
                    'status' => 'Ativo',
                    'nota_fiscal' => 'NF-44912',
                    'descricao' => 'Aparelho de climatização central da nave do templo.',
                    'responsavel_diacono' => 'Diác. Roberto Alves',
                ],
                [
                    'numero_tombamento' => 'TOMBO-0005',
                    'nome' => 'Conjunto de 30 Bancos de Madeira Maciça Angelim',
                    'categoria' => 'Mobiliário',
                    'localizacao' => 'Templo Principal',
                    'data_aquisicao' => '2021-05-18',
                    'valor_aquisicao' => 36000.00,
                    'valor_atual' => 35000.00,
                    'estado_conservacao' => 'Bom',
                    'status' => 'Ativo',
                    'nota_fiscal' => 'NF-0941',
                    'descricao' => 'Bancos almofadados para assento da congregação.',
                    'responsavel_diacono' => 'Diác. Marcos Vinícius',
                ],
            ];

            foreach ($bens as $b) {
                PatrimonioBem::create(array_merge($b, ['institution_id' => 5]));
            }
        }

        // 3. Ordens de Serviço & Zeladoria
        if (OrdemServicoDiaconia::count() === 0) {
            OrdemServicoDiaconia::create([
                'institution_id' => 5,
                'numero_os' => 'OS-2026/001',
                'titulo' => 'Revisão Preventiva dos Quadros Elétricos',
                'descricao' => 'Inspeção termográfica e reaperto dos disjuntores da nave principal e salas anexas.',
                'tipo_servico' => 'Elétrica',
                'localizacao' => 'Templo Principal & Salão Anexo',
                'prioridade' => 'Alta',
                'status' => 'Concluída',
                'solicitante' => 'Presb. José Carlos',
                'diacono_responsavel' => 'Diác. Roberto Alves',
                'data_solicitacao' => '2026-09-10',
                'data_previsao' => '2026-09-18',
                'data_conclusao' => '2026-09-17',
                'custo_estimado' => 450.00,
                'custo_real' => 420.00,
                'observacoes' => 'Serviço executado por eletricista credenciado. Emitida ART.',
            ]);

            OrdemServicoDiaconia::create([
                'institution_id' => 5,
                'numero_os' => 'OS-2026/002',
                'titulo' => 'Pintura e Reparo de Reboco na Sala das Crianças',
                'descricao' => 'Pintura lavável nas salas de aula 01 e 02 da Escola Dominical.',
                'tipo_servico' => 'Pintura',
                'localizacao' => 'Salas da EBD',
                'prioridade' => 'Média',
                'status' => 'Em Andamento',
                'solicitante' => 'Superintendência da EBD',
                'diacono_responsavel' => 'Diác. Daniel Rocha',
                'data_solicitacao' => '2026-10-01',
                'data_previsao' => '2026-10-15',
                'custo_estimado' => 850.00,
                'custo_real' => 0.00,
                'observacoes' => 'Tinta adquirida pela Junta Diaconal; serviço em execução aos sábados.',
            ]);

            OrdemServicoDiaconia::create([
                'institution_id' => 5,
                'numero_os' => 'OS-2026/003',
                'titulo' => 'Substituição da Válvula de Descarga do Sanitário Masculino',
                'descricao' => 'Vazamento contínuo identificado no banheiro térreo dos visitantes.',
                'tipo_servico' => 'Hidráulica',
                'localizacao' => 'Sanitários Térreo',
                'prioridade' => 'Alta',
                'status' => 'Pendente',
                'solicitante' => 'Equipe de Acolhimento',
                'diacono_responsavel' => 'Diác. Paulo Ferreira',
                'data_solicitacao' => '2026-10-06',
                'data_previsao' => '2026-10-10',
                'custo_estimado' => 120.00,
                'custo_real' => 0.00,
            ]);
        }

        // 4. Escalas de Diáconos
        if (EscalaDiacono::count() === 0) {
            EscalaDiacono::create([
                'institution_id' => 5,
                'data_culto' => '2026-10-11',
                'periodo' => 'Manhã / EBD',
                'recepcao_porta' => 'Diác. Marcos Vinícius, Diác. Paulo Ferreira',
                'recolhimento_ofertas' => 'Diác. Daniel Rocha, Diác. Roberto Alves',
                'apoio_pulpito_ceia' => 'Diác. Marcos Vinícius',
                'seguranca_patio' => 'Diác. André Luiz',
                'diacono_coordenador' => 'Diác. Marcos Vinícius',
                'observacoes' => 'Distribuição de boletins e boas-vindas aos visitantes.',
            ]);

            EscalaDiacono::create([
                'institution_id' => 5,
                'data_culto' => '2026-10-11',
                'periodo' => 'Noite',
                'recepcao_porta' => 'Diác. Daniel Rocha, Diác. André Luiz',
                'recolhimento_ofertas' => 'Diác. Roberto Alves, Diác. Paulo Ferreira',
                'apoio_pulpito_ceia' => 'Diác. Roberto Alves (Mesa da Ceia do Senhor)',
                'seguranca_patio' => 'Diác. Marcos Vinícius',
                'diacono_coordenador' => 'Diác. Daniel Rocha',
                'observacoes' => 'Culto solene de Celebração da Santa Ceia.',
            ]);
        }

        // 5. Cotas Conciliares
        if (CotaConciliar::count() === 0) {
            CotaConciliar::create([
                'institution_id' => 5,
                'ano' => 2026,
                'mes' => 8,
                'base_calculo' => 38500.00,
                'aliquota_presbiterio_pct' => 5.00,
                'aliquota_supremo_concilio_pct' => 5.00,
                'valor_presbiterio' => 1925.00,
                'valor_supremo_concilio' => 1925.00,
                'status_presbiterio' => 'Pago',
                'status_supremo_concilio' => 'Pago',
                'data_pagamento_presbiterio' => '2026-09-10',
                'data_pagamento_sc' => '2026-09-10',
                'comprovante_presbiterio' => 'DOC-PIX-PRB-AGO26',
                'comprovante_sc' => 'DOC-PIX-SC-AGO26',
                'observacoes' => 'Quitado pontualmente conforme prazo regimental.',
            ]);

            CotaConciliar::create([
                'institution_id' => 5,
                'ano' => 2026,
                'mes' => 9,
                'base_calculo' => 41200.00,
                'aliquota_presbiterio_pct' => 5.00,
                'aliquota_supremo_concilio_pct' => 5.00,
                'valor_presbiterio' => 2060.00,
                'valor_supremo_concilio' => 2060.00,
                'status_presbiterio' => 'Pago',
                'status_supremo_concilio' => 'Pendente',
                'data_pagamento_presbiterio' => '2026-10-05',
                'comprovante_presbiterio' => 'DOC-PIX-PRB-SET26',
                'observacoes' => 'Cota do Supremo Concílio com vencimento em 15/10/2026.',
            ]);
        }

        // 6. Linhas do Orçamento Anual Programa 2026
        if (OrcamentoAnualLinha::count() === 0) {
            $linhas = [
                ['departamento_ou_sociedade' => 'Pastoral & Ministério', 'descricao' => 'Congrua Pastoral, Previdência e Benefícios Ministeriais', 'valor' => 84000.00],
                ['departamento_ou_sociedade' => 'Templo & Manutenção', 'descricao' => 'Energia, Água, Conservação e Manutenção Predial', 'valor' => 38000.00],
                ['departamento_ou_sociedade' => 'Escola Dominical (EBD)', 'descricao' => 'Revistas da Editora Cultura Cristã e Materiais Pedagógicos', 'valor' => 14000.00],
                ['departamento_ou_sociedade' => 'Missões & Evangelização', 'descricao' => 'Sustento de Missionários e Plantio de Igrejas no Campo', 'valor' => 28000.00],
                ['departamento_ou_sociedade' => 'Junta Diaconal', 'descricao' => 'Assistência Social, Cestas Básicas e Manutenções Rápidas', 'valor' => 18000.00],
                ['departamento_ou_sociedade' => 'SAF (Sociedade Auxiliadora Feminina)', 'descricao' => 'Projetos de Oração, Visitação e Congresso Distrital', 'valor' => 5000.00],
                ['departamento_ou_sociedade' => 'UPH (Homens)', 'descricao' => 'Encontros de Homens e Evangelização Comunitária', 'valor' => 4500.00],
                ['departamento_ou_sociedade' => 'UMP & UPA (Juventude e Adolescentes)', 'descricao' => 'Acampamentos, Congressos e Louvor', 'valor' => 9000.00],
                ['departamento_ou_sociedade' => 'Música & Liturgia', 'descricao' => 'Instrumentos, Licenciamento de Músicas e Afinação de Pianos', 'valor' => 6500.00],
            ];

            foreach ($linhas as $l) {
                OrcamentoAnualLinha::create([
                    'institution_id' => 5,
                    'ano' => 2026,
                    'departamento_ou_sociedade' => $l['departamento_ou_sociedade'],
                    'descricao' => $l['descricao'],
                    'valor_previsto_anual' => $l['valor'],
                ]);
            }
        }

        // 7. Pareceres da Comissão de Exame de Contas
        if (ParecerExameContas::count() === 0) {
            ParecerExameContas::create([
                'institution_id' => 5,
                'numero_parecer' => 'PAR-2026/01',
                'ano_exercicio' => 2026,
                'periodo' => '1º Trimestre',
                'data_emissao' => '2026-04-12',
                'relator' => 'Diác. Rodrigo Sampaio (Presidente da Comissão)',
                'membros_comissao' => [
                    'Diác. Rodrigo Sampaio',
                    'Irmã Vera Lúcia Magalhães',
                    'Presb. Carlos Eduardo Prado',
                ],
                'resultado' => 'Favorável sem ressalvas',
                'total_receitas_auditado' => 112450.00,
                'total_despesas_auditado' => 98120.00,
                'saldo_apurado' => 14330.00,
                'conformidade_livro_caixa' => true,
                'conformidade_extratos_bancarios' => true,
                'conformidade_comprovantes_fiscais' => true,
                'conformidade_cotas_conciliares' => true,
                'ressalvas_e_recomendacoes' => 'Recomendamos manter o rigor no arquivamento de comprovantes digitais das compras parceladas do cartão corporativo.',
                'texto_conclusao' => 'A Comissão de Exame de Contas, após minucioso exame dos livros da Tesouraria da Igreja, extratos bancários, notas fiscais e comprovantes de pagamentos do 1º Trimestre de 2026, constatou que os registros contábeis encontram-se em perfeita exatidão e conformidade com as normas administrativas e canônicas da Igreja Presbiteriana do Brasil. Portanto, somos de parecer FAVORÁVEL sem ressalvas à sua aprovação pela Assembleia Geral.',
                'status' => 'Concluído',
            ]);
        }
    }
}
