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
      body: jsonEncode({}),
    );

    return coletaId;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
