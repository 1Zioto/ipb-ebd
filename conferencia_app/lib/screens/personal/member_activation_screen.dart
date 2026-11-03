import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/context_controller.dart';
import 'personal_shell_screen.dart';

class MemberActivationScreen extends StatefulWidget {
  const MemberActivationScreen({super.key});

  @override
  State<MemberActivationScreen> createState() => _MemberActivationScreenState();
}

class _MemberActivationScreenState extends State<MemberActivationScreen> {
  int _step = 1; // 1: Identificação por CPF/Nascimento, 2: Senha
  bool _loading = false;

  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String? _activationToken;
  String? _memberName;
  String? _churchName;
  String? _errorMessage;

  Future<void> _verifyMember() async {
    final cpf = _cpfController.text.trim();
    final birth = _birthDateController.text.trim();

    if (cpf.isEmpty || birth.isEmpty) {
      setState(() => _errorMessage = 'Preencha o CPF e a Data de Nascimento.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.verifyMemberActivation(
        cpf: cpf,
        birthDate: birth,
      );

      setState(() {
        _activationToken = res['activation_token'];
        _memberName = res['member_name'];
        _churchName = res['church_name'];
        _step = 2;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _confirmActivation() async {
    final pass = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (pass.length < 8) {
      setState(() => _errorMessage = 'A senha deve conter no mínimo 8 caracteres.');
      return;
    }

    if (pass != confirm) {
      setState(() => _errorMessage = 'A confirmação de senha não confere.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.instance.confirmMemberActivation(
        token: _activationToken!,
        password: pass,
        passwordConfirmation: confirm,
      );

      await ContextController.instance.init();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta ativada com sucesso! Bem-vindo ao Concilia-IPB.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PersonalShellScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeiro Acesso / Ativação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF047857), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ativação segura de conta para membros previamente cadastrados no Rol de Membros da IPB.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              ),

            if (_step == 1) ...[
              const Text('Informe seus dados cadastrais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Seus dados serão verificados com o registro da secretaria.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              TextField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CPF (apenas números)',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento (AAAA-MM-DD)',
                  hintText: 'Ex: 1985-06-20',
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _verifyMember,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Localizar Cadastro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ] else ...[
              Text('Olá, $_memberName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF047857))),
              const SizedBox(height: 4),
              Text('Igreja: $_churchName', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              const Text('Crie sua senha de acesso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova Senha (mínimo 8 caracteres)',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirme a Nova Senha',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _confirmActivation,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Concluir Ativação e Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

