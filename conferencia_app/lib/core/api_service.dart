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
    Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> notifyContextSwitch(String context) async {
    if (_token == null || _token == 'offline-token') return;
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/switch-context'),
        headers: _authHeaders,
        body: jsonEncode({'context': context}),
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    if (_token == null || _token == 'offline-token') return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/devices'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['devices'] as List?;
        return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      }
    } catch (_) {}
    return [];
  }

  Future<bool> revokeDevice(int deviceId) async {
    if (_token == null || _token == 'offline-token') return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/devices/$deviceId/revoke'),
        headers: _authHeaders,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> revokeOtherDevices() async {
    if (_token == null || _token == 'offline-token') return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/devices/revoke-others'),
        headers: _authHeaders,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyMemberActivation({
    required String cpf,
    required String birthDate,
    int? institutionId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/activate/verify'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'cpf': cpf,
        'birth_date': birthDate,
        if (institutionId != null) 'institution_id': institutionId,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception(data['message'] ?? 'Falha ao verificar dados do membro.');
  }

  Future<UserModel> confirmMemberActivation({
    required String token,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/activate/confirm'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'activation_token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName ?? 'App Concilia-IPB',
        'platform': 'android',
        'client_version': '1.1.3',
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      _token = data['token'];
      _currentUser = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      return _currentUser!;
    }
    throw Exception(data['message'] ?? 'Falha ao ativar conta.');
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

    // Fallback padrão se não tiver nada (76 membros)
    return const [
      MemberModel(id: 10, fullName: 'Alice Costa', envelopeNumber: '110'),
      MemberModel(id: 42, fullName: 'Amanda Rezende', envelopeNumber: '142'),
      MemberModel(id: 2, fullName: 'Ana Clara Souza', envelopeNumber: '102'),
      MemberModel(id: 58, fullName: 'André Luiz Souza', envelopeNumber: '158'),
      MemberModel(id: 7, fullName: 'Arthur Rodrigues', envelopeNumber: '107'),
      MemberModel(id: 12, fullName: 'Beatriz Gomes', envelopeNumber: '112'),
      MemberModel(id: 69, fullName: 'Beatriz Helena Guimarães', envelopeNumber: '169'),
      MemberModel(id: 35, fullName: 'Benício Moraes', envelopeNumber: '135'),
      MemberModel(id: 17, fullName: 'Bernardo Almeida', envelopeNumber: '117'),
      MemberModel(id: 45, fullName: 'Bruno Tavares', envelopeNumber: '145'),
      MemberModel(id: 33, fullName: 'Caio Batista', envelopeNumber: '133'),
      MemberModel(id: 48, fullName: 'Camila Borges', envelopeNumber: '148'),
      MemberModel(id: 71, fullName: 'Camila Siqueira Paiva', envelopeNumber: '171'),
      MemberModel(id: 54, fullName: 'Carlos Eduardo Lima', envelopeNumber: '154'),
      MemberModel(id: 30, fullName: 'Cecília Monteiro', envelopeNumber: '130'),
      MemberModel(id: 61, fullName: 'Cristiane Almeida Nunes', envelopeNumber: '161'),
      MemberModel(id: 31, fullName: 'Daniel Vieira', envelopeNumber: '131'),
      MemberModel(id: 72, fullName: 'Daniela Martins Prado', envelopeNumber: '172'),
      MemberModel(id: 9, fullName: 'Davi Pereira', envelopeNumber: '109'),
      MemberModel(id: 65, fullName: 'Diác. André Luiz Ramos', envelopeNumber: '165'),
      MemberModel(id: 66, fullName: 'Diác. Felipe Mendes Bastos', envelopeNumber: '166'),
      MemberModel(id: 1, fullName: 'Douglas Zioto', envelopeNumber: '101'),
      MemberModel(id: 47, fullName: 'Eduardo Peixoto', envelopeNumber: '147'),
      MemberModel(id: 32, fullName: 'Emanuelly Andrade', envelopeNumber: '132'),
      MemberModel(id: 29, fullName: 'Enzo Freitas', envelopeNumber: '129'),
      MemberModel(id: 40, fullName: 'Esther Azevedo', envelopeNumber: '140'),
      MemberModel(id: 43, fullName: 'Felipe Guimarães', envelopeNumber: '143'),
      MemberModel(id: 55, fullName: 'Fernanda Alves Costa', envelopeNumber: '155'),
      MemberModel(id: 11, fullName: 'Gabriel Martins', envelopeNumber: '111'),
      MemberModel(id: 50, fullName: 'Gabriela Miranda', envelopeNumber: '150'),
      MemberModel(id: 25, fullName: 'Gustavo Moreira', envelopeNumber: '125'),
      MemberModel(id: 27, fullName: 'Heitor Correia', envelopeNumber: '127'),
      MemberModel(id: 8, fullName: 'Helena Alves', envelopeNumber: '108'),
      MemberModel(id: 41, fullName: 'Henrique Lopes', envelopeNumber: '141'),
      MemberModel(id: 22, fullName: 'Isabela Nunes', envelopeNumber: '122'),
      MemberModel(id: 73, fullName: 'José Fernando Peixoto', envelopeNumber: '173'),
      MemberModel(id: 3, fullName: 'João Pedro Santos', envelopeNumber: '103'),
      MemberModel(id: 74, fullName: 'Juliana Freitas Albuquerque', envelopeNumber: '174'),
      MemberModel(id: 57, fullName: 'Juliana Martins Rocha', envelopeNumber: '157'),
      MemberModel(id: 18, fullName: 'Júlia Fernandes', envelopeNumber: '118'),
      MemberModel(id: 6, fullName: 'Laura Ferreira', envelopeNumber: '106'),
      MemberModel(id: 44, fullName: 'Letícia Cavalcante', envelopeNumber: '144'),
      MemberModel(id: 36, fullName: 'Lorena Pinto', envelopeNumber: '136'),
      MemberModel(id: 19, fullName: 'Lucas Araújo', envelopeNumber: '119'),
      MemberModel(id: 68, fullName: 'Lucas Gabriel Rocha', envelopeNumber: '168'),
      MemberModel(id: 24, fullName: 'Luiza Rocha', envelopeNumber: '124'),
      MemberModel(id: 28, fullName: 'Lívia Castro', envelopeNumber: '128'),
      MemberModel(id: 16, fullName: 'Manuela Barbosa', envelopeNumber: '116'),
      MemberModel(id: 52, fullName: 'Marcos Antônio Silva', envelopeNumber: '152'),
      MemberModel(id: 4, fullName: 'Maria Eduarda Lima', envelopeNumber: '104'),
      MemberModel(id: 67, fullName: 'Mariana Castro Silveira', envelopeNumber: '167'),
      MemberModel(id: 26, fullName: 'Mariana Dias', envelopeNumber: '126'),
      MemberModel(id: 21, fullName: 'Matheus Cardoso', envelopeNumber: '121'),
      MemberModel(id: 38, fullName: 'Melissa Farias', envelopeNumber: '138'),
      MemberModel(id: 5, fullName: 'Miguel Oliveira', envelopeNumber: '105'),
      MemberModel(id: 46, fullName: 'Natália Neves', envelopeNumber: '146'),
      MemberModel(id: 37, fullName: 'Nicolas Cunha', envelopeNumber: '137'),
      MemberModel(id: 53, fullName: 'Patrícia Oliveira Santos', envelopeNumber: '153'),
      MemberModel(id: 70, fullName: 'Paulo Henrique Antunes', envelopeNumber: '170'),
      MemberModel(id: 60, fullName: 'Paulo Henrique Ribeiro', envelopeNumber: '160'),
      MemberModel(id: 15, fullName: 'Pedro Henrique Silva', envelopeNumber: '115'),
      MemberModel(id: 63, fullName: 'Presb. Marcos Vinícius Toledo', envelopeNumber: '163'),
      MemberModel(id: 64, fullName: 'Presb. Roberto Alencar Fontes', envelopeNumber: '164'),
      MemberModel(id: 23, fullName: 'Rafael Teixeira', envelopeNumber: '123'),
      MemberModel(id: 59, fullName: 'Renata Ferreira Dias', envelopeNumber: '159'),
      MemberModel(id: 76, fullName: 'Renata Vasconcelos Lima', envelopeNumber: '176'),
      MemberModel(id: 62, fullName: 'Rev. Carlos Eduardo Silveira', envelopeNumber: '162'),
      MemberModel(id: 56, fullName: 'Ricardo Gomes Pereira', envelopeNumber: '156'),
      MemberModel(id: 75, fullName: 'Ricardo Morais Fontes', envelopeNumber: '175'),
      MemberModel(id: 13, fullName: 'Samuel Ribeiro', envelopeNumber: '113'),
      MemberModel(id: 20, fullName: 'Sophia Melo', envelopeNumber: '120'),
      MemberModel(id: 49, fullName: 'Thiago Coelho', envelopeNumber: '149'),
      MemberModel(id: 14, fullName: 'Valentina Carvalho', envelopeNumber: '114'),
      MemberModel(id: 51, fullName: 'Vinícius Duarte', envelopeNumber: '151'),
      MemberModel(id: 39, fullName: 'Vitor Hugo Ramos', envelopeNumber: '139'),
      MemberModel(id: 34, fullName: 'Yasmin Campos', envelopeNumber: '134'),
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

    // Fallback inicial estático (76 membros)
    return {
      'membros': [
        {'id': 10, 'roll_number': 'ROL-0104', 'full_name': 'Alice Costa', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998302-1703', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 42, 'roll_number': 'ROL-0120', 'full_name': 'Amanda Rezende', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997481-1639', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 2, 'roll_number': 'ROL-0128', 'full_name': 'Ana Clara Souza', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 996994-6659', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 58, 'roll_number': 'ROL-0167', 'full_name': 'André Luiz Souza', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998936-9404', 'marital_status': 'Casado(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 7, 'roll_number': 'ROL-0132', 'full_name': 'Arthur Rodrigues', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 999654-3674', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 12, 'roll_number': 'ROL-0105', 'full_name': 'Beatriz Gomes', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'transferencia', 'phone': '(27) 996709-6775', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 69, 'roll_number': 'ROL-0156', 'full_name': 'Beatriz Helena Guimarães', 'canonical_status': 'nao_comungante', 'reception_date': '2021-03-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 992325-1441', 'marital_status': 'Solteiro(a)', 'notes': 'Pedagoga e Professora do Berçário & Maternal'},
        {'id': 35, 'roll_number': 'ROL-0145', 'full_name': 'Benício Moraes', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'transferencia', 'phone': '(27) 997747-2079', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 17, 'roll_number': 'ROL-0136', 'full_name': 'Bernardo Almeida', 'canonical_status': 'nao_comungante', 'reception_date': '2025-11-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 991711-9241', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 45, 'roll_number': 'ROL-0150', 'full_name': 'Bruno Tavares', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992327-8234', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 33, 'roll_number': 'ROL-0144', 'full_name': 'Caio Batista', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994040-2337', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 48, 'roll_number': 'ROL-0123', 'full_name': 'Camila Borges', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 993082-1470', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 71, 'roll_number': 'ROL-0158', 'full_name': 'Camila Siqueira Paiva', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 995785-8200', 'marital_status': 'Solteiro(a)', 'notes': 'Professora da Classe de Juniores'},
        {'id': 54, 'roll_number': 'ROL-0163', 'full_name': 'Carlos Eduardo Lima', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992773-7010', 'marital_status': 'Casado(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 30, 'roll_number': 'ROL-0114', 'full_name': 'Cecília Monteiro', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992673-6262', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 61, 'roll_number': 'ROL-0170', 'full_name': 'Cristiane Almeida Nunes', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 993913-2017', 'marital_status': 'Solteiro(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 31, 'roll_number': 'ROL-0143', 'full_name': 'Daniel Vieira', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998638-8680', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 72, 'roll_number': 'ROL-0159', 'full_name': 'Daniela Martins Prado', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994936-7454', 'marital_status': 'Casado(a)', 'notes': 'Professora da Classe de Primários'},
        {'id': 9, 'roll_number': 'ROL-0133', 'full_name': 'Davi Pereira', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'transferencia', 'phone': '(27) 999484-7965', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 65, 'roll_number': 'ROL-0175', 'full_name': 'Diác. André Luiz Ramos', 'canonical_status': 'sob_disciplina', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 995748-5170', 'marital_status': 'Casado(a)', 'notes': 'Superintendência de Apoio e Logística'},
        {'id': 66, 'roll_number': 'ROL-0176', 'full_name': 'Diác. Felipe Mendes Bastos', 'canonical_status': 'falecido', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 993605-6658', 'marital_status': 'Solteiro(a)', 'notes': 'Superintendência de Apoio e Professor Substituto'},
        {'id': 1, 'roll_number': 'ROL-0101', 'full_name': 'Douglas Zioto', 'canonical_status': 'nao_comungante', 'reception_date': '2020-01-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 994011-1365', 'marital_status': 'Casado(a)', 'notes': 'Membro cadastrado no Rol Oficial.'},
        {'id': 47, 'roll_number': 'ROL-0151', 'full_name': 'Eduardo Peixoto', 'canonical_status': 'nao_comungante', 'reception_date': '2022-05-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 991705-7056', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 32, 'roll_number': 'ROL-0115', 'full_name': 'Emanuelly Andrade', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998638-7137', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 29, 'roll_number': 'ROL-0142', 'full_name': 'Enzo Freitas', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997176-7041', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 40, 'roll_number': 'ROL-0147', 'full_name': 'Esther Azevedo', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997278-6226', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 43, 'roll_number': 'ROL-0121', 'full_name': 'Felipe Guimarães', 'canonical_status': 'nao_comungante', 'reception_date': '2022-05-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 998232-9463', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 55, 'roll_number': 'ROL-0164', 'full_name': 'Fernanda Alves Costa', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994020-9972', 'marital_status': 'Solteiro(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 11, 'roll_number': 'ROL-0134', 'full_name': 'Gabriel Martins', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 996792-8886', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 50, 'roll_number': 'ROL-0124', 'full_name': 'Gabriela Miranda', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998406-1901', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 25, 'roll_number': 'ROL-0140', 'full_name': 'Gustavo Moreira', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998716-8339', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 27, 'roll_number': 'ROL-0141', 'full_name': 'Heitor Correia', 'canonical_status': 'nao_comungante', 'reception_date': '2024-09-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 998461-5282', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 8, 'roll_number': 'ROL-0103', 'full_name': 'Helena Alves', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 991873-8910', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 41, 'roll_number': 'ROL-0148', 'full_name': 'Henrique Lopes', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992959-3247', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 22, 'roll_number': 'ROL-0110', 'full_name': 'Isabela Nunes', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992944-2011', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 73, 'roll_number': 'ROL-0171', 'full_name': 'José Fernando Peixoto', 'canonical_status': 'nao_comungante', 'reception_date': '2024-09-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 994533-9030', 'marital_status': 'Casado(a)', 'notes': 'Membro cadastrado no Rol Oficial.'},
        {'id': 3, 'roll_number': 'ROL-0129', 'full_name': 'João Pedro Santos', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'transferencia', 'phone': '(27) 996155-7476', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 74, 'roll_number': 'ROL-0127', 'full_name': 'Juliana Freitas Albuquerque', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997160-4555', 'marital_status': 'Casado(a)', 'notes': 'Professora da Classe de Adolescentes'},
        {'id': 57, 'roll_number': 'ROL-0166', 'full_name': 'Juliana Martins Rocha', 'canonical_status': 'nao_comungante', 'reception_date': '2025-11-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 994659-6846', 'marital_status': 'Solteiro(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 18, 'roll_number': 'ROL-0108', 'full_name': 'Júlia Fernandes', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992377-4162', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 6, 'roll_number': 'ROL-0102', 'full_name': 'Laura Ferreira', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 999195-3781', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 44, 'roll_number': 'ROL-0149', 'full_name': 'Letícia Cavalcante', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'transferencia', 'phone': '(27) 998953-8923', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 36, 'roll_number': 'ROL-0117', 'full_name': 'Lorena Pinto', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'transferencia', 'phone': '(27) 994878-5064', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 19, 'roll_number': 'ROL-0137', 'full_name': 'Lucas Araújo', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'transferencia', 'phone': '(27) 999258-1649', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 68, 'roll_number': 'ROL-0155', 'full_name': 'Lucas Gabriel Rocha', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994776-5225', 'marital_status': 'Casado(a)', 'notes': 'Líder da Mocidade (UMP) e Professor'},
        {'id': 24, 'roll_number': 'ROL-0111', 'full_name': 'Luiza Rocha', 'canonical_status': 'nao_comungante', 'reception_date': '2024-09-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 995910-4479', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 28, 'roll_number': 'ROL-0113', 'full_name': 'Lívia Castro', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'transferencia', 'phone': '(27) 999561-3977', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 16, 'roll_number': 'ROL-0107', 'full_name': 'Manuela Barbosa', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997939-3405', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 52, 'roll_number': 'ROL-0161', 'full_name': 'Marcos Antônio Silva', 'canonical_status': 'nao_comungante', 'reception_date': '2020-01-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 994207-3035', 'marital_status': 'Casado(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 4, 'roll_number': 'ROL-0130', 'full_name': 'Maria Eduarda Lima', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994434-7368', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 67, 'roll_number': 'ROL-0154', 'full_name': 'Mariana Castro Silveira', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 999039-2678', 'marital_status': 'Solteiro(a)', 'notes': 'Professora da Classe de Casais'},
        {'id': 26, 'roll_number': 'ROL-0112', 'full_name': 'Mariana Dias', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 997230-7587', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 21, 'roll_number': 'ROL-0138', 'full_name': 'Matheus Cardoso', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998273-5927', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 38, 'roll_number': 'ROL-0118', 'full_name': 'Melissa Farias', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992241-1717', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 5, 'roll_number': 'ROL-0131', 'full_name': 'Miguel Oliveira', 'canonical_status': 'nao_comungante', 'reception_date': '2020-01-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 999146-5811', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 46, 'roll_number': 'ROL-0122', 'full_name': 'Natália Neves', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 999726-5921', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 37, 'roll_number': 'ROL-0146', 'full_name': 'Nicolas Cunha', 'canonical_status': 'nao_comungante', 'reception_date': '2023-07-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 997901-3944', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 53, 'roll_number': 'ROL-0162', 'full_name': 'Patrícia Oliveira Santos', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 991366-6343', 'marital_status': 'Solteiro(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 70, 'roll_number': 'ROL-0157', 'full_name': 'Paulo Henrique Antunes', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'transferencia', 'phone': '(27) 993951-8236', 'marital_status': 'Casado(a)', 'notes': 'Professor da Classe Bereana (Adultos)'},
        {'id': 60, 'roll_number': 'ROL-0169', 'full_name': 'Paulo Henrique Ribeiro', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'transferencia', 'phone': '(27) 991340-5495', 'marital_status': 'Casado(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 15, 'roll_number': 'ROL-0126', 'full_name': 'Pedro Henrique Silva', 'canonical_status': 'nao_comungante', 'reception_date': '2021-03-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 992530-2335', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 63, 'roll_number': 'ROL-0173', 'full_name': 'Presb. Marcos Vinícius Toledo', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'transferencia', 'phone': '(27) 999801-5493', 'marital_status': 'Casado(a)', 'notes': 'Superintendente Geral da EBD'},
        {'id': 64, 'roll_number': 'ROL-0174', 'full_name': 'Presb. Roberto Alencar Fontes', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994719-5183', 'marital_status': 'Solteiro(a)', 'notes': 'Superintendente Adjunto e Professor de Adultos'},
        {'id': 23, 'roll_number': 'ROL-0139', 'full_name': 'Rafael Teixeira', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 996492-3419', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 59, 'roll_number': 'ROL-0168', 'full_name': 'Renata Ferreira Dias', 'canonical_status': 'comungante', 'reception_date': '2021-03-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 994792-4419', 'marital_status': 'Solteiro(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 76, 'roll_number': 'ROL-0125', 'full_name': 'Renata Vasconcelos Lima', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'transferencia', 'phone': '(27) 992830-7806', 'marital_status': 'Casado(a)', 'notes': 'Professora Auxiliar dos Primários e Berçário'},
        {'id': 62, 'roll_number': 'ROL-0172', 'full_name': 'Rev. Carlos Eduardo Silveira', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 995790-5418', 'marital_status': 'Solteiro(a)', 'notes': 'Pastor Titular da IP Campo Verde'},
        {'id': 56, 'roll_number': 'ROL-0165', 'full_name': 'Ricardo Gomes Pereira', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'transferencia', 'phone': '(27) 996147-6062', 'marital_status': 'Casado(a)', 'notes': 'Professor fictício para demonstração do sistema.'},
        {'id': 75, 'roll_number': 'ROL-0160', 'full_name': 'Ricardo Morais Fontes', 'canonical_status': 'comungante', 'reception_date': '2025-11-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 991798-3930', 'marital_status': 'Solteiro(a)', 'notes': 'Professor da Classe de Mocidade / Jovens'},
        {'id': 13, 'roll_number': 'ROL-0135', 'full_name': 'Samuel Ribeiro', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998600-2001', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 20, 'roll_number': 'ROL-0109', 'full_name': 'Sophia Melo', 'canonical_status': 'comungante', 'reception_date': '2022-05-10', 'reception_type': 'transferencia', 'phone': '(27) 995696-7886', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 49, 'roll_number': 'ROL-0152', 'full_name': 'Thiago Coelho', 'canonical_status': 'comungante', 'reception_date': '2023-07-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 992495-3445', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 14, 'roll_number': 'ROL-0106', 'full_name': 'Valentina Carvalho', 'canonical_status': 'nao_comungante', 'reception_date': '2025-11-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 993136-8816', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 51, 'roll_number': 'ROL-0153', 'full_name': 'Vinícius Duarte', 'canonical_status': 'comungante', 'reception_date': '2024-09-10', 'reception_type': 'transferencia', 'phone': '(27) 992318-1785', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 39, 'roll_number': 'ROL-0119', 'full_name': 'Vitor Hugo Ramos', 'canonical_status': 'comungante', 'reception_date': '2020-01-10', 'reception_type': 'profissao_fe_batismo', 'phone': '(27) 998891-5689', 'marital_status': 'Casado(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
        {'id': 34, 'roll_number': 'ROL-0116', 'full_name': 'Yasmin Campos', 'canonical_status': 'nao_comungante', 'reception_date': '2023-07-10', 'reception_type': 'batismo_infantil', 'phone': '(27) 997936-9811', 'marital_status': 'Solteiro(a)', 'notes': 'Aluno fictício para demonstração do sistema.'},
      ],
      'stats': {
        'total': 76,
        'comungantes': 59,
        'nao_comungantes': 15,
        'sob_disciplina': 1,
        'jurisdicao_especial': 0,
        'falecidos': 1,
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
