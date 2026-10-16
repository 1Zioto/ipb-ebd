import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  static const String baseUrl = 'https://ebd-api-five.vercel.app/api/v1';

  static const _tokenKey = 'ipb_auth_token';
  static const _userKey = 'ipb_current_user';
  static const _membersCacheKey = 'ipb_members_cache';
  static const _offlineQueueKey = 'ipb_offline_coleta_queue_v1';
  static const _deviceIdKey = 'ipb_offline_device_id_v1';

  String? _token;
  UserModel? _currentUser;
  Map<String, bool> _screenToggles = {};

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isOffline => _currentUser?.isOffline ?? false;
  Map<String, bool> get screenToggles => _screenToggles;

  bool isScreenEnabled(String screenKey) {
    return _screenToggles[screenKey] ?? true;
  }

  Future<void> fetchScreenConfigs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/screen-configs'),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final togglesRaw = data['toggles'];
        if (togglesRaw is Map) {
          final instId = _currentUser?.institutionId ?? 5;
          dynamic churchToggles = togglesRaw[instId.toString()] ?? togglesRaw[instId] ?? togglesRaw['5'];
          if (churchToggles == null && togglesRaw.isNotEmpty) {
            churchToggles = togglesRaw.values.first;
          }
          if (churchToggles is Map) {
            _screenToggles = churchToggles.map(
              (k, v) => MapEntry(k.toString(), v == true),
            );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ipb_screen_toggles_cache', jsonEncode(_screenToggles));
          }
        }
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('ipb_screen_toggles_cache');
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          _screenToggles = decoded.map((k, v) => MapEntry(k, v == true));
        } catch (_) {}
      }
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    final cachedToggles = prefs.getString('ipb_screen_toggles_cache');
    if (cachedToggles != null) {
      try {
        final decoded = jsonDecode(cachedToggles) as Map<String, dynamic>;
        _screenToggles = decoded.map((k, v) => MapEntry(k, v == true));
      } catch (_) {}
    }
    // Sincroniza em background
    fetchScreenConfigs();
  }

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username.trim(), 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _token = data['token'] ?? data['access_token'];
        final userData =
            data['user'] ?? {'name': username, 'role': 'Oficial / Membro'};
        _currentUser = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

        // A successful online login is a safe opportunity to retry immutable
        // mobile lots. Retries are idempotent on the API by operation id.
        try {
          await submitPendingOfflineColetas();
          await refreshOfflineColetaStatuses();
        } catch (_) {}

        return _currentUser!;
      } else {
        throw ApiException(
          data['message']?.toString() ?? 'Credenciais inválidas.',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Falha ao conectar com o servidor da IPB: $e');
    }
  }

  Future<UserModel> loginOffline(String name) async {
    _token = 'offline-token';
    _currentUser = UserModel(
      name: name.trim().isEmpty ? 'Oficial IPB (Offline)' : name.trim(),
      role: 'Modo Offline / Contingência',
      isOffline: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

    return _currentUser!;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<List<MemberModel>> getMembers() async {
    // Tenta carregar da API se tiver token online
    if (_token != null && !isOffline) {
      try {
        final res = await http.get(
          Uri.parse('$baseUrl/people?per_page=100'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final listData = body['data'] is List
              ? body['data']
              : (body is List ? body : []);
          final members = (listData as List)
              .map((item) => MemberModel.fromJson(item))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _membersCacheKey,
            jsonEncode(
              members
                  .map(
                    (m) => {
                      'id': m.id,
                      'full_name': m.fullName,
                      'envelope_number': m.envelopeNumber,
                    },
                  )
                  .toList(),
            ),
          );

          return members;
        }
      } catch (_) {}
    }

    // Fallback: cache local
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_membersCacheKey);
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        return list.map((m) => MemberModel.fromJson(m)).toList();
      } catch (_) {}
    }

    // Fallback padrão se não tiver nada
    return const [
      MemberModel(
        id: 1,
        fullName: 'Carlos Eduardo Silva',
        envelopeNumber: '101',
      ),
      MemberModel(
        id: 2,
        fullName: 'Marcos Vinícius Barbosa',
        envelopeNumber: '102',
      ),
      MemberModel(
        id: 3,
        fullName: 'Roberto Santos Lima',
        envelopeNumber: '103',
      ),
      MemberModel(id: 4, fullName: 'Ana Beatriz Rocha', envelopeNumber: '104'),
      MemberModel(
        id: 5,
        fullName: 'Lucas Ferreira Costa',
        envelopeNumber: '105',
      ),
      MemberModel(id: 6, fullName: 'Pr. Marcos Antônio', envelopeNumber: '001'),
    ];
  }

  // --- SECRETARIA: ROL DE MEMBROS ---
  static const _rolMembrosCacheKey = 'ipb_rol_membros_cache_v2';

  Future<Map<String, dynamic>> getRolMembros({
    String? status,
    String? search,
    int perPage = 250,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null && !isOffline) {
      try {
        final queryParams = <String, String>{
          'per_page': perPage.toString(),
        };
        if (status != null && status.isNotEmpty && status.toLowerCase() != 'todos') {
          queryParams['status'] = status.toLowerCase();
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }

        final uri = Uri.parse('$baseUrl/secretaria/membros').replace(queryParameters: queryParams);
        final res = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          List<dynamic> listRaw = [];
          if (body['membros'] != null) {
            if (body['membros'] is Map && body['membros']['data'] is List) {
              listRaw = body['membros']['data'];
            } else if (body['membros'] is List) {
              listRaw = body['membros'];
            }
          } else if (body['data'] is List) {
            listRaw = body['data'];
          }

          final membros = listRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          final stats = body['stats'] is Map ? Map<String, dynamic>.from(body['stats'] as Map) : <String, dynamic>{};

          final result = {
            'membros': membros,
            'stats': stats,
          };

          await prefs.setString(_rolMembrosCacheKey, jsonEncode(result));
          return result;
        }
      } catch (_) {}
    }

    // Fallback: cache local
    final cached = prefs.getString(_rolMembrosCacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        if (data is Map) {
          final membros = (data['membros'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
          final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : <String, dynamic>{};
          return {
            'membros': membros,
            'stats': stats,
          };
        }
      } catch (_) {}
    }

    // Fallback inicial estático
    return {
      'membros': [
        {'id': 1, 'roll_number': '001', 'full_name': 'Rev. Antônio Carlos Silva', 'canonical_status': 'comungante', 'reception_date': '2018-02-02', 'reception_type': 'Designação Presbiterial', 'phone': '(81) 98765-4321', 'marital_status': 'Casado', 'spouse_name': 'Maria Auxiliadora Silva', 'notes': 'Pastor Titular da Igreja.'},
        {'id': 2, 'roll_number': '002', 'full_name': 'Presb. Paulo Roberto Albuquerque', 'canonical_status': 'comungante', 'reception_date': '2015-05-15', 'reception_type': 'profissao_fe_batismo', 'phone': '(81) 99876-1122', 'marital_status': 'Casado', 'spouse_name': 'Helena Albuquerque', 'notes': 'Vice-Presidente do Conselho.'},
        {'id': 3, 'roll_number': '003', 'full_name': 'Diác. Carlos Eduardo Nogueira', 'canonical_status': 'comungante', 'reception_date': '2016-08-20', 'reception_type': 'transferencia', 'phone': '(81) 98123-4567', 'marital_status': 'Casado', 'spouse_name': 'Juliana Nogueira', 'notes': 'Presidente da Junta Diaconal.'},
        {'id': 4, 'roll_number': '004', 'full_name': 'Débora Neves de Lima', 'canonical_status': 'comungante', 'reception_date': '2019-10-12', 'reception_type': 'profissao_fe', 'phone': '(81) 99234-5678', 'marital_status': 'Casada', 'spouse_name': 'Marcos Lima', 'notes': 'Professora do Departamento Infantil.'},
        {'id': 5, 'roll_number': '005', 'full_name': 'Gabriel Henrique Braga', 'canonical_status': 'comungante', 'reception_date': '2021-11-14', 'reception_type': 'profissao_fe', 'phone': '(81) 98877-6655', 'marital_status': 'Solteiro', 'notes': 'Líder da UMP Mocidade.'},
        {'id': 6, 'roll_number': '006', 'full_name': 'Lucas Ferreira da Silva', 'canonical_status': 'comungante', 'reception_date': '2022-03-05', 'reception_type': 'transferencia', 'phone': '(81) 99112-3344', 'marital_status': 'Solteiro', 'notes': 'Membro da equipe de Louvor e EBD.'},
        {'id': 7, 'roll_number': '007', 'full_name': 'Beatriz Vasconcelos', 'canonical_status': 'comungante', 'reception_date': '2020-06-18', 'reception_type': 'profissao_fe', 'phone': '(81) 99876-5432', 'marital_status': 'Solteira', 'notes': 'Auxiliar da EBD e SAF.'},
        {'id': 8, 'roll_number': '008', 'full_name': 'Esther Ramos Peixoto', 'canonical_status': 'nao_comungante', 'reception_date': '2023-01-10', 'reception_type': 'batismo_infantil', 'phone': '(81) 98711-2233', 'marital_status': 'Solteira', 'notes': 'Batizada na infância.'},
      ],
      'stats': {
        'total': 8,
        'comungantes': 7,
        'nao_comungantes': 1,
        'sob_disciplina': 0,
        'jurisdicao_especial': 0,
        'falecidos': 0,
      }
    };
  }

  Future<Map<String, dynamic>> updateMembroCanonical(int id, Map<String, dynamic> data) async {
    if (_token != null && !isOffline) {
      final res = await http.put(
        Uri.parse('$baseUrl/secretaria/membros/$id'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        try {
          final err = jsonDecode(res.body);
          throw ApiException(err['message']?.toString() ?? 'Falha ao atualizar dados do membro.');
        } catch (e) {
          if (e is ApiException) rethrow;
          throw ApiException('Erro na atualização (${res.statusCode})');
        }
      }
    }
    return data;
  }

  // --- CENTRAL DE INTELIGÊNCIA ECLESIÁSTICA ---
  Future<Map<String, dynamic>> getIntelligenceOverview({int? year, bool consolidated = false}) async {
    final y = year ?? DateTime.now().year;
    if (_token != null && !isOffline) {
      try {
        final uri = Uri.parse('$baseUrl/intelligence/overview').replace(queryParameters: {
          'ano': y.toString(),
          'consolidated': consolidated ? '1' : '0',
        });
        final res = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    // Fallback estruturado
    return {
      'ano': y,
      'kpis': {
        'total_pessoas': 184,
        'total_membros': 172,
        'comungantes': 142,
        'nao_comungantes': 30,
        'sob_disciplina': 0,
        'total_familias': 68,
        'total_alunos_ebd': 86,
        'total_professores': 12,
        'total_superintendentes': 3,
        'total_dizimistas': 94,
        'admissoes_ano': 8,
        'saidas_ano': 2,
        'crescimento_liquido': 6,
        'media_idade': 38.4,
        'mediana_idade': 36.0,
        'aniversariantes_mes': 14,
        'frequencia_ebd_media': 82.5,
      },
      'age_distribution': {
        'infantil': 28,
        'adolescentes': 22,
        'jovens': 48,
        'adultos': 62,
        'melhor_idade': 24,
      },
      'canonical_chart': {
        'labels': ['Comungantes', 'Não Comungantes', 'Sob Disciplina'],
        'data': [142, 30, 0],
      },
    };
  }

  // --- MÓDULO DE CONFERÊNCIAS DE DÍZIMOS E OFERTAS ---

  Future<List<ColetaModel>> getConferencias({
    String? status,
    String? search,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'ipb_conferencias_list_cache';

    if (_token != null && !isOffline) {
      try {
        final queryParams = <String, String>{'per_page': '50'};
        if (status != null && status.isNotEmpty && status != 'todos') {
          final s = status.toLowerCase().trim();
          if (s == 'aberta' || s == 'em_andamento' || s == 'em andamento') {
            queryParams['status'] = 'em_andamento';
          } else if (s == 'fechada' || s == 'encerrada' || s == 'encerradas') {
            queryParams['status'] = 'encerrada';
          } else {
            queryParams['status'] = status;
          }
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }

        final uri = Uri.parse(
          '$baseUrl/dizimos/coletas',
        ).replace(queryParameters: queryParams);
        final res = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final listData = body['data'] is List
              ? body['data']
              : (body is List ? body : []);
          final list = (listData as List)
              .map((j) => ColetaModel.fromJson(j))
              .toList();

          await prefs.setString(cacheKey, jsonEncode(listData));
          return list;
        }
      } catch (_) {}
    }

    // Cache local / Fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        var entries = list.map((j) => ColetaModel.fromJson(j)).toList();
        if (status != null && status.isNotEmpty && status != 'todos') {
          final s = status.toLowerCase().trim();
          if (s == 'aberta' || s == 'em_andamento') {
            entries = entries.where((c) => c.isAberta).toList();
          } else if (s == 'fechada' || s == 'encerrada') {
            entries = entries.where((c) => !c.isAberta).toList();
          }
        }
        return entries;
      } catch (_) {}
    }

    return const [];
  }

  Future<ColetaModel> createConferencia({
    required String date,
    required String serviceMeeting,
    String? description,
    String? notes,
  }) async {
    if (_token != null && !isOffline) {
      final res = await http.post(
        Uri.parse('$baseUrl/dizimos/coletas'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'date': date,
          'service_meeting': serviceMeeting,
          'description': description,
          'notes': notes,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        return ColetaModel.fromJson(data);
      } else {
        final err = jsonDecode(res.body);
        throw ApiException(
          err['message']?.toString() ?? 'Falha ao criar conferência.',
        );
      }
    }

    // Modo contingência offline
    final fakeId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ColetaModel(
      id: fakeId,
      code: 'CONF-${fakeId.toString().padLeft(6, '0')}',
      date: date,
      serviceMeeting: serviceMeeting,
      description: description,
      status: 'Aberta',
      creatorName: _currentUser?.name ?? 'Diácono Responsável',
      entryCount: 0,
      totalAmount: 0.0,
      totalDizimos: 0.0,
      ofertaDinheiro: 0.0,
      ofertaPix: 0.0,
      ofertaTransferencia: 0.0,
      totalOfertas: 0.0,
      totalGeral: 0.0,
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> getConferenciaDetails(int coletaId) async {
    if (_token != null && !isOffline) {
      final res = await http.get(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final coleta = ColetaModel.fromJson(data);
        final rawLanc = data['lancamentos'] is List
            ? data['lancamentos'] as List
            : [];
        var entries = rawLanc.map((l) => EnvelopeEntry.fromJson(l)).toList();

        if (entries.isEmpty) {
          try {
            final comp = await getComprovante(coletaId);
            if (comp['dizimos'] is Map && comp['dizimos']['itens'] is List) {
              final compItens = comp['dizimos']['itens'] as List;
              entries = compItens
                  .map((l) => EnvelopeEntry.fromJson(l))
                  .toList();
            } else if (comp['lancamentos'] is List) {
              final compItens = comp['lancamentos'] as List;
              entries = compItens
                  .map((l) => EnvelopeEntry.fromJson(l))
                  .toList();
            }
          } catch (_) {}
        }

        return {'coleta': coleta, 'entries': entries};
      }
    }
    return {};
  }

  Future<EnvelopeEntry> addEnvelopeLancamento(
    int coletaId, {
    int? personId,
    required double amount,
    required String forma,
    String? envelopeNumber,
    String? membro,
    String? destinacao,
    bool force = false,
  }) async {
    if (_token != null && !isOffline) {
      final res = await http.post(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId/lancamentos'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'person_id': personId,
          'amount': amount,
          'contribution_type': destinacao ?? 'dizimo',
          'payment_method': forma,
          'envelope_number': envelopeNumber,
          'contribuinte_nome': membro,
          'is_unidentified': personId == null,
          'force': force,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 409) {
        throw DuplicateEntryException(
          data['message']?.toString() ?? 'Envelope já registrado.',
        );
      } else if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(
          data['message']?.toString() ?? 'Erro ao adicionar envelope.',
        );
      }

      return EnvelopeEntry.fromJson(data['lancamento']);
    }

    // Offline entry
    return EnvelopeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      personId: personId,
      membro: membro ?? 'Contribuinte',
      envelopeNumber: envelopeNumber,
      valor: amount,
      destinacao: destinacao ?? 'dizimo',
      forma: forma,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<void> deleteEnvelopeLancamento(
    int coletaId,
    int lancamentoId, {
    String? reason,
  }) async {
    if (_token != null && !isOffline) {
      final res = await http.delete(
        Uri.parse(
          '$baseUrl/dizimos/coletas/$coletaId/lancamentos/$lancamentoId',
        ),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reason': reason ?? 'Remoção na conferência móvel'}),
      );

      if (res.statusCode >= 300) {
        final err = jsonDecode(res.body);
        throw ApiException(
          err['message']?.toString() ?? 'Falha ao excluir lançamento.',
        );
      }
    }
  }

  Future<void> saveOfertasAvulsas(
    int coletaId, {
    required double dinheiro,
    required double pix,
    required double transferencia,
  }) async {
    if (_token != null && !isOffline) {
      final res = await http.post(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId/ofertas'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'oferta_dinheiro': dinheiro,
          'oferta_pix': pix,
          'oferta_transferencia': transferencia,
        }),
      );

      if (res.statusCode >= 300) {
        final err = jsonDecode(res.body);
        throw ApiException(
          err['message']?.toString() ?? 'Falha ao salvar ofertas avulsas.',
        );
      }
    }
  }

  Future<Map<String, dynamic>> closeConferencia(
    int coletaId, {
    double? dinheiro,
    double? pix,
    double? transferencia,
  }) async {
    if (_token != null && !isOffline) {
      final res = await http.post(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId/fechar'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'oferta_dinheiro': dinheiro ?? 0,
          'oferta_pix': pix ?? 0,
          'oferta_transferencia': transferencia ?? 0,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(
          data['message']?.toString() ?? 'Falha ao encerrar conferência.',
        );
      }

      return data;
    }

    throw const ApiException(
      'Uma conferência offline não pode ser encerrada no dispositivo. Envie o lote para análise e aguarde aprovação.',
    );
  }

  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<List<OfflineColetaQueueItem>> getOfflineColetaQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineQueueKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final items = jsonDecode(raw) as List;
      return items
          .whereType<Map>()
          .map(
            (item) => OfflineColetaQueueItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      // Do not discard an unreadable audit queue automatically. A later
      // version or support process can still recover the preferences value.
      return const [];
    }
  }

  Future<void> _saveOfflineColetaQueue(
    List<OfflineColetaQueueItem> queue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _offlineQueueKey,
      jsonEncode(queue.map((item) => item.toJson()).toList()),
    );
  }

  Future<OfflineColetaQueueItem> enqueueOfflineColeta({
    required List<EnvelopeEntry> entries,
    required String date,
    required String serviceMeeting,
    String? description,
    String? notes,
    double ofertaDinheiro = 0,
    double ofertaPix = 0,
    double ofertaTransferencia = 0,
  }) async {
    if (entries.isEmpty) {
      throw const ApiException(
        'Inclua ao menos um lançamento antes de enviar a conferência para análise.',
      );
    }

    final capturedAt = DateTime.now().toUtc().toIso8601String();
    final item = OfflineColetaQueueItem(
      operationId: await _newUuid(),
      deviceId: await deviceId(),
      capturedAt: capturedAt,
      coleta: {
        'date': date,
        'service_meeting': serviceMeeting,
        'description': description,
        'notes': notes,
        'oferta_dinheiro': ofertaDinheiro,
        'oferta_pix': ofertaPix,
        'oferta_transferencia': ofertaTransferencia,
      },
      // Copy the list immediately so subsequent screen changes cannot alter
      // the auditable batch that was captured at this point in time.
      entries: List<EnvelopeEntry>.unmodifiable(entries),
      status: 'pending_upload',
    );

    final queue = await getOfflineColetaQueue();
    await _saveOfflineColetaQueue([...queue, item]);
    return item;
  }

  Future<List<OfflineColetaQueueItem>> submitPendingOfflineColetas() async {
    if (_token == null || isOffline) return getOfflineColetaQueue();

    var queue = await getOfflineColetaQueue();
    var changed = false;
    for (var index = 0; index < queue.length; index++) {
      final item = queue[index];
      if (!item.awaitsUpload) continue;

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/dizimos/offline-syncs'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(item.toServerPayload()),
        );
        final body = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode < 200 || response.statusCode >= 300) {
          queue[index] = item.copyWith(attempts: item.attempts + 1);
          changed = true;
          continue;
        }

        final server = Map<String, dynamic>.from(
          body['data'] as Map? ?? const {},
        );
        queue[index] = item.copyWith(
          status: server['status']?.toString() ?? 'pending_review',
          serverId: server['id'] == null ? null : asInt(server['id']),
          reviewNotes: server['review_notes']?.toString(),
          attempts: item.attempts + 1,
        );
        changed = true;
      } catch (_) {
        queue[index] = item.copyWith(attempts: item.attempts + 1);
        changed = true;
      }
    }
    if (changed) await _saveOfflineColetaQueue(queue);
    return queue;
  }

  Future<List<OfflineColetaQueueItem>> refreshOfflineColetaStatuses() async {
    if (_token == null || isOffline) return getOfflineColetaQueue();

    final response = await http.get(
      Uri.parse('$baseUrl/dizimos/offline-syncs?per_page=100'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) return getOfflineColetaQueue();

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['data'] is List ? body['data'] as List : const [];
    final serverByOperation = <String, Map<String, dynamic>>{};
    for (final value in raw.whereType<Map>()) {
      final server = Map<String, dynamic>.from(value);
      final operationId = server['client_operation_id']?.toString();
      if (operationId != null) serverByOperation[operationId] = server;
    }

    final queue = await getOfflineColetaQueue();
    var changed = false;
    final refreshed = queue.map((item) {
      final server = serverByOperation[item.operationId];
      if (server == null) return item;
      changed = true;
      return item.copyWith(
        status: server['status']?.toString() ?? item.status,
        serverId: server['id'] == null ? item.serverId : asInt(server['id']),
        reviewNotes: server['review_notes']?.toString(),
      );
    }).toList();
    if (changed) await _saveOfflineColetaQueue(refreshed);
    return refreshed;
  }

  Future<String> _newUuid() async {
    // UUID v4 generated locally so the same operation id survives all retry
    // attempts, even when the first HTTP response was lost.
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Map<String, dynamic>> getComprovante(
    int coletaId, {
    bool reimprimir = false,
  }) async {
    if (_token != null && !isOffline) {
      final endpoint = reimprimir
          ? '$baseUrl/dizimos/coletas/$coletaId/reimprimir'
          : '$baseUrl/dizimos/coletas/$coletaId/comprovante';

      final res = reimprimir
          ? await http.post(
              Uri.parse(endpoint),
              headers: {
                'Authorization': 'Bearer $_token',
                'Accept': 'application/json',
              },
            )
          : await http.get(
              Uri.parse(endpoint),
              headers: {
                'Authorization': 'Bearer $_token',
                'Accept': 'application/json',
              },
            );

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<int> syncColeta({
    required List<EnvelopeEntry> entries,
    required double totalFisico,
    required double diferencaDinheiro,
    required String conferente1,
    required String conferente2,
    required String culto,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final queued = await enqueueOfflineColeta(
      entries: entries,
      date: today,
      serviceMeeting: culto,
      description: 'Conferência Móvel IPB ($conferente1 e $conferente2)',
      notes:
          'Batimento: Físico R\$ ${totalFisico.toStringAsFixed(2)} | Oferta Solta R\$ ${diferencaDinheiro.toStringAsFixed(2)}',
      ofertaDinheiro: diferencaDinheiro > 0 ? diferencaDinheiro : 0,
    );
    final queue = await submitPendingOfflineColetas();
    final synced = queue
        .where((item) => item.operationId == queued.operationId)
        .first;
    return synced.serverId ?? -1;
  }
}

class DuplicateEntryException implements Exception {
  final String message;
  const DuplicateEntryException(this.message);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
