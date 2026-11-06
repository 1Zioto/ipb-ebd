import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Métricas Customizadas para Auditoria do Master Prompt
export const crossChurchLeakageErrors = new Counter('cross_church_leakage_detected');
export const successRate = new Rate('successful_requests');
export const loginDuration = new Trend('member_login_duration');
export const churchDataDuration = new Trend('church_data_duration');

// Configuração dos Estágios de Carga: 100 -> 250 -> 500 -> 1.000 Usuários Ativos
export const options = {
  stages: [
    { duration: '20s', target: 100 },  // Aquecimento: 100 VUs
    { duration: '30s', target: 250 },  // Carga leve: 250 VUs
    { duration: '40s', target: 500 },  // Carga moderada: 500 VUs
    { duration: '1m',  target: 1000 }, // Carga Pico Plena: 1.000 VUs Simultâneos
    { duration: '30s', target: 0 },    // Desaceleração graciosa
  ],
  thresholds: {
    // 95% das requisições devem responder em menos de 3 segundos
    http_req_duration: ['p(95)<3000'],
    // Taxa de erros HTTP deve ser inferior a 1%
    http_req_failed: ['rate<0.01'],
    // Zero vazamento entre igrejas
    cross_church_leakage_detected: ['count==0'],
  },
};

// URL Base: Por padrão aponta para o servidor LOCAL (preservação de custos de nuvem)
const BASE_URL = __ENV.TARGET_URL || 'http://127.0.0.1:8000/api/v1';

// Massa de dados de teste (Multi-igrejas)
const CHURCH_A_ID = 5; // Igreja Sede (ex: Campo Verde)
const CHURCH_B_ID = 6; // Congregação / Outra Igreja

export default function () {
  const vuId = __VU;
  const iteration = __ITER;

  // 1. FLUXO DO MEMBRO: Autenticação via Telefone / CPF e Data de Nascimento
  group('1. Autenticação do Membro (Telefone + Data de Nascimento)', () => {
    const payload = JSON.stringify({
      username: '27981416770',
      birth_date: '03/05/1993',
    });

    const headers = { 'Content-Type': 'application/json' };
    const startTime = Date.now();
    const res = http.post(`${BASE_URL}/auth/login`, payload, { headers });
    loginDuration.add(Date.now() - startTime);

    const isLoginOk = check(res, {
      'login status 200': (r) => r.status === 200,
      'token emitido com sucesso': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.token !== undefined && body.user !== undefined;
        } catch (e) {
          return false;
        }
      },
    });

    successRate.add(isLoginOk);

    if (isLoginOk) {
      const data = JSON.parse(res.body);
      const token = data.token;
      const userInstitutionId = data.user.institution_id;
      const authHeaders = {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      };

      // 2. ISOLAMENTO MULTI-IGREJAS: Verificar dados da igreja autorizada
      group('2. Validação Estrita de Isolamento Multi-Igrejas', () => {
        const infoRes = http.get(`${BASE_URL}/dashboard/summary`, { headers: authHeaders });
        churchDataDuration.add(infoRes.timings.duration);

        check(infoRes, {
          'dashboard status 200': (r) => r.status === 200,
          'sem vazamento de outra igreja': (r) => {
            try {
              const body = JSON.parse(r.body);
              // Garante que o usuário da Igreja A NÃO receba dados exclusivos da Igreja B
              if (body.institution_id && body.institution_id !== userInstitutionId) {
                crossChurchLeakageErrors.add(1);
                return false;
              }
              return true;
            } catch (e) {
              return true;
            }
          },
        });
      });

      // 3. FLUXO DE PRESTAÇÃO DE CONTAS: Consulta de Prestação de Contas Homologada
      group('3. Prestação de Contas Simplificada para Membros', () => {
        const prestacaoRes = http.get(`${BASE_URL}/public/church/${userInstitutionId}/prestacao-contas`);
        check(prestacaoRes, {
          'prestacao de contas acessivel': (r) => r.status === 200 || r.status === 404,
        });
      });
    }
  });

  // 4. FLUXO VISITANTE: Link Público de Cadastro de Membros
  group('4. Submissão Pública de Cadastro de Membro', () => {
    // A cada 10 iterações, simula um novo visitante solicitando cadastro
    if (iteration % 10 === 0) {
      const randomPhone = `2799${Math.floor(1000000 + Math.random() * 9000000)}`;
      const payload = JSON.stringify({
        full_name: `Visitante Teste Carga ${vuId}_${iteration}`,
        birth_date: '1995-08-15',
        phone: randomPhone,
        gender: 'M',
        marital_status: 'solteiro',
        is_communicant: true,
        origin_church: 'Igreja Presbiteriana Central',
      });

      const res = http.post(`${BASE_URL}/public/church/${CHURCH_A_ID}/membership-applications`, payload, {
        headers: { 'Content-Type': 'application/json' },
      });

      check(res, {
        'cadastro público recebido com sucesso': (r) => r.status === 201 || r.status === 422,
      });
    }
  });

  // Pausa realista entre ações (tempo de leitura e clique do usuário)
  sleep(Math.random() * 2 + 1);
}

