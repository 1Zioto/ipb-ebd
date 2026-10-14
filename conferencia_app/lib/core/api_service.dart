import 'dart:convert';
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

  String? _token;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isOffline => _currentUser?.isOffline ?? false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
  }

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _token = data['token'] ?? data['access_token'];
        final userData = data['user'] ?? {'name': username, 'role': 'Oficial / Membro'};
        _currentUser = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

        return _currentUser!;
      } else {
        throw ApiException(data['message']?.toString() ?? 'Credenciais inválidas.');
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
          final listData = body['data'] is List ? body['data'] : (body is List ? body : []);
          final members = (listData as List)
              .map((item) => MemberModel.fromJson(item))
              .toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              _membersCacheKey, jsonEncode(members.map((m) => {'id': m.id, 'full_name': m.fullName, 'envelope_number': m.envelopeNumber}).toList()));

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
      MemberModel(id: 1, fullName: 'Carlos Eduardo Silva', envelopeNumber: '101'),
      MemberModel(id: 2, fullName: 'Marcos Vinícius Barbosa', envelopeNumber: '102'),
      MemberModel(id: 3, fullName: 'Roberto Santos Lima', envelopeNumber: '103'),
      MemberModel(id: 4, fullName: 'Ana Beatriz Rocha', envelopeNumber: '104'),
      MemberModel(id: 5, fullName: 'Lucas Ferreira Costa', envelopeNumber: '105'),
      MemberModel(id: 6, fullName: 'Pr. Marcos Antônio', envelopeNumber: '001'),
    ];
  }

  // --- MÓDULO DE CONFERÊNCIAS DE DÍZIMOS E OFERTAS ---

  Future<List<ColetaModel>> getConferencias({String? status, String? search}) async {
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

        final uri = Uri.parse('$baseUrl/dizimos/coletas').replace(queryParameters: queryParams);
        final res = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final listData = body['data'] is List ? body['data'] : (body is List ? body : []);
          final list = (listData as List).map((j) => ColetaModel.fromJson(j)).toList();

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
        throw ApiException(err['message']?.toString() ?? 'Falha ao criar conferência.');
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
        final rawLanc = data['lancamentos'] is List ? data['lancamentos'] as List : [];
        var entries = rawLanc.map((l) => EnvelopeEntry.fromJson(l)).toList();

        if (entries.isEmpty) {
          try {
            final comp = await getComprovante(coletaId);
            if (comp['dizimos'] is Map && comp['dizimos']['itens'] is List) {
              final compItens = comp['dizimos']['itens'] as List;
              entries = compItens.map((l) => EnvelopeEntry.fromJson(l)).toList();
            } else if (comp['lancamentos'] is List) {
              final compItens = comp['lancamentos'] as List;
              entries = compItens.map((l) => EnvelopeEntry.fromJson(l)).toList();
            }
          } catch (_) {}
        }

        return {
          'coleta': coleta,
          'entries': entries,
        };
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
        throw DuplicateEntryException(data['message']?.toString() ?? 'Envelope já registrado.');
      } else if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(data['message']?.toString() ?? 'Erro ao adicionar envelope.');
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

  Future<void> deleteEnvelopeLancamento(int coletaId, int lancamentoId, {String? reason}) async {
    if (_token != null && !isOffline) {
      final res = await http.delete(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId/lancamentos/$lancamentoId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reason': reason ?? 'Remoção na conferência móvel'}),
      );

      if (res.statusCode >= 300) {
        final err = jsonDecode(res.body);
        throw ApiException(err['message']?.toString() ?? 'Falha ao excluir lançamento.');
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
        throw ApiException(err['message']?.toString() ?? 'Falha ao salvar ofertas avulsas.');
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
        throw ApiException(data['message']?.toString() ?? 'Falha ao encerrar conferência.');
      }

      return data;
    }

    return {
      'message': 'Conferência encerrada localmente (modo offline).',
    };
  }

  Future<Map<String, dynamic>> getComprovante(int coletaId, {bool reimprimir = false}) async {
    if (_token != null && !isOffline) {
      final endpoint = reimprimir
          ? '$baseUrl/dizimos/coletas/$coletaId/reimprimir'
          : '$baseUrl/dizimos/coletas/$coletaId/comprovante';

      final res = reimprimir
          ? await http.post(Uri.parse(endpoint), headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'})
          : await http.get(Uri.parse(endpoint), headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'});

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
    if (_token == null || isOffline) {
      throw ApiException('Conecte-se com sua conta online para enviar à API.');
    }

    final today = DateTime.now().toIso8601String().split('T')[0];

    // 1. Criar coleta
    final resColeta = await http.post(
      Uri.parse('$baseUrl/dizimos/coletas'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'date': today,
        'service_meeting': culto,
        'description': 'Conferência Móvel IPB ($conferente1 e $conferente2)',
        'notes': 'Batimento: Físico R\$ ${totalFisico.toStringAsFixed(2)} | Oferta Solta R\$ ${diferencaDinheiro.toStringAsFixed(2)}',
      }),
    );

    if (resColeta.statusCode < 200 || resColeta.statusCode >= 300) {
      throw ApiException('Falha ao abrir coleta na API: ${resColeta.body}');
    }

    final dataColeta = jsonDecode(resColeta.body);
    final int coletaId = dataColeta['id'];

    // 2. Lançar envelopes
    for (final e in entries) {
      await http.post(
        Uri.parse('$baseUrl/dizimos/coletas/$coletaId/lancamentos'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'person_id': e.personId,
          'amount': e.valor,
          'contribution_type': e.destinacao,
          'payment_method': e.forma,
          'envelope_number': e.envelopeNumber,
          'contribuinte_nome': e.membro,
          'is_unidentified': e.personId == null,
          'notes': '${e.membro} (${e.forma})',
        }),
      );
    }

    // 3. Fechar coleta
    await http.post(
      Uri.parse('$baseUrl/dizimos/coletas/$coletaId/fechar'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'oferta_dinheiro': diferencaDinheiro > 0 ? diferencaDinheiro : 0,
      }),
    );

    return coletaId;
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

