import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/Home_screen.dart' show ChartColors;
import '../../services/auth_api.dart';
import '../../services/vet_api.dart' show ApiException;
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthApi.login(email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចភ្ជាប់ទៅ server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), backgroundColor: ChartColors.rose),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChartColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: ChartColors.tealTint, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.pets_rounded, color: ChartColors.teal, size: 32),
              ),
              const SizedBox(height: 24),
              Text('សូមស្វាគមន៍មកវិញ', style: GoogleFonts.fraunces(fontSize: 30, fontWeight: FontWeight.w700, color: ChartColors.ink)),
              const SizedBox(height: 6),
              const Text('ចូលទៅគណនីគ្លីនិកសត្វពេទ្យរបស់អ្នក', style: TextStyle(color: ChartColors.inkSoft, fontSize: 14)),
              const SizedBox(height: 32),

              _label('អ៊ីមែល'),
              _field(
                controller: _email,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';
                  if (!v.contains('@') || !v.contains('.')) return 'អ៊ីមែលមិនត្រឹមត្រូវ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('ពាក្យសម្ងាត់'),
              _field(
                controller: _password,
                hint: '••••••••',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'សូមបញ្ចូលពាក្យសម្ងាត់' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ChartColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ចូលប្រព័ន្ធ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('មិនទាន់មានគណនី?', style: TextStyle(color: ChartColors.inkSoft, fontSize: 13)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('ចុះឈ្មោះ', style: TextStyle(color: ChartColors.teal, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: const TextStyle(color: ChartColors.ink, fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: ChartColors.inkSoft),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.teal, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.rose)),
        ),
      );
}