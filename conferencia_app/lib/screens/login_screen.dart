import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'main_menu_screen.dart';
import 'personal/member_activation_screen.dart';
import 'personal/personal_shell_screen.dart';

enum LoginProfile { membro, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Padrão obrigatório pelo Prompt Mestre: Área do Membro selecionada por padrão
  LoginProfile _selectedProfile = LoginProfile.membro;

  // Controladores para Área do Membro
  final _memberPhoneController = TextEditingController(text: '27981416770');
  final _memberBirthController = TextEditingController(text: '03051993');

  // Controladores para Administração
  final _adminEmailController = TextEditingController(text: 'douglaszioto@gmail.com');
  final _adminPasswordController = TextEditingController(text: '635241@Ab');

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _memberPhoneController.dispose();
    _memberBirthController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String username;
    String password;

    if (_selectedProfile == LoginProfile.membro) {
      username = _memberPhoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      password = _memberBirthController.text.trim().replaceAll(RegExp(r'[^\d]'), '');

      if (username.isEmpty || password.isEmpty) {
        setState(() => _errorMessage = 'Informe seu Celular/CPF e a Data de Nascimento no formato DDMMAAAA (ex: 15081990).');
        return;
      }

      if (password.length != 8) {
        setState(() => _errorMessage = 'A data de nascimento deve conter exatamente 8 dígitos (DDMMAAAA, ex: 15081990).');
        return;
      }
    } else {
      username = _adminEmailController.text.trim();
      password = _adminPasswordController.text;

      if (username.isEmpty || password.isEmpty) {
        setState(() => _errorMessage = 'Informe o E-mail institucional e a Senha cadastrada da administração.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.instance.login(username, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acesso autorizado: ${user.name}! (${user.role})'),
          backgroundColor: const Color(0xFF047857),
        ),
      );

      // Se for login de membro (ou usuário estritamente membro), direciona para Área do Membro
      // Se for login administrativo com permissão de gestão, abre o MainMenuScreen
      final Widget nextScreen = (_selectedProfile == LoginProfile.admin && user.hasManagementAccess)
          ? const MainMenuScreen()
          : const PersonalShellScreen();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      setState(() {
        _errorMessage = msg;
        _loading = false;
      });
    }
  }

  Future<void> _handleOfflineLogin() async {
    final name = _adminEmailController.text.trim();
    await ApiService.instance.loginOffline(name.isNotEmpty ? name : 'Oficial Diaconia IPB');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo Offline ativado para conferência local de coletas.'),
        backgroundColor: Color(0xFF047857),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Oficial IPB
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/ipb-logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.church_rounded,
                        size: 48,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CONCÍLIA IPB',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF065F46),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Igreja Presbiteriana do Brasil • Gestão & Membresia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card de Login
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Seletor de Perfil de Login (Membro selecionado por padrão)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedProfile = LoginProfile.membro;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedProfile == LoginProfile.membro ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _selectedProfile == LoginProfile.membro
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 18,
                                            color: _selectedProfile == LoginProfile.membro
                                                ? const Color(0xFF047857)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Área do Membro',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedProfile == LoginProfile.membro
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedProfile = LoginProfile.admin;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedProfile == LoginProfile.admin ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _selectedProfile == LoginProfile.admin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings_rounded,
                                            size: 18,
                                            color: _selectedProfile == LoginProfile.admin
                                                ? const Color(0xFF047857)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Administração',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedProfile == LoginProfile.admin
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Mensagem de Erro (se houver)
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Formulário Dinâmico conforme Perfil
                          if (_selectedProfile == LoginProfile.membro) ...[
                            // DICA ÁREA DO MEMBRO
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Color(0xFF047857), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Acesso do membro: informe seu celular (ou CPF) e data de nascimento no formato DDMMAAAA.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Campo Celular / CPF
                            TextField(
                              controller: _memberPhoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Celular ou CPF',
                                hintText: 'Ex: 27981416770',
                                prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF047857)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Campo Data de Nascimento (DDMMAAAA)
                            TextField(
                              controller: _memberBirthController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 8,
                              onSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Data de Nascimento (DDMMAAAA)',
                                hintText: 'Ex: 15081990',
                                counterText: '',
                                prefixIcon: const Icon(Icons.cake_rounded, color: Color(0xFF047857)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ] else ...[
                            // DICA ADMINISTRAÇÃO
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: Color(0xFF334155), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Acesso administrativo: exclusivo para pastores, presbíteros, diáconos e oficiais.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Campo E-mail Administrativo
                            TextField(
                              controller: _adminEmailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'E-mail Cadastrado',
                                hintText: 'Ex: pastor@ipb.org.br',
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF047857)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Campo Senha Administrativa
                            TextField(
                              controller: _adminPasswordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Senha Administrativa',
                                hintText: 'Digite sua senha',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF047857)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Botão Principal de Login
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _loading ? null : _handleLogin,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              _loading
                                  ? 'Autenticando...'
                                  : (_selectedProfile == LoginProfile.membro
                                      ? 'Entrar como Membro'
                                      : 'Acessar Administração'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),

                          // Opções Complementares
                          if (_selectedProfile == LoginProfile.admin) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _handleOfflineLogin,
                              icon: const Icon(Icons.cloud_off_outlined, color: Color(0xFF047857)),
                              label: const Text(
                                'Modo Offline (Conferência Local Diaconia)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            TextButton.icon(
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Color(0xFF047857)),
                              label: const Text(
                                'Primeiro Acesso? Ativar Cadastro de Membro',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF047857)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MemberActivationScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Igreja Presbiteriana do Brasil • Gestão Eclesiástica & Membresia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
