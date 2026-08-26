import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/Home_screen.dart' show ChartColors;
import '../../services/auth_api.dart';
import '../../services/vet_api.dart' show ApiException;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthApi.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      // Register មិន auto-login ទេ → ត្រូវអោយ user ចូល login ដោយខ្លួនឯង
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('បានចុះឈ្មោះជោគជ័យ! សូមចូលប្រព័ន្ធ'), backgroundColor: ChartColors.teal),
      );
      Navigator.of(context).pop(); // ត្រឡប់ទៅ LoginScreen
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
      appBar: AppBar(backgroundColor: ChartColors.bg, elevation: 0, iconTheme: const IconThemeData(color: ChartColors.ink)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('បង្កើតគណនីថ្មី', style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700, color: ChartColors.ink)),
              const SizedBox(height: 6),
              const Text('ចុះឈ្មោះដើម្បីចាប់ផ្តើមគ្រប់គ្រងគ្លីនិករបស់អ្នក', style: TextStyle(color: ChartColors.inkSoft, fontSize: 14)),
              const SizedBox(height: 28),

              _label('ឈ្មោះពេញ'),
              _field(
                controller: _name,
                hint: 'ឧ. Dr. Dara',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'សូមបញ្ចូលឈ្មោះ' : null,
              ),
              const SizedBox(height: 16),

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

              _label('លេខទូរស័ព្ទ'),
              _field(
                controller: _phone,
                hint: 'ឧ. 0977 123 456',
                keyboard: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'សូមបញ្ចូលលេខទូរស័ព្ទ' : null,
              ),
              const SizedBox(height: 16),

              _label('ពាក្យសម្ងាត់'),
              _field(
                controller: _password,
                hint: 'យ៉ាងតិច ៦ តួអក្សរ',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
                  if (v.length < 6) return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('បញ្ជាក់ពាក្យសម្ងាត់'),
              _field(
                controller: _confirmPassword,
                hint: 'វាយបញ្ចូលម្តងទៀត',
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) => (v != _password.text) ? 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ' : null,
              ),
              const SizedBox(height: 28),

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
                      : const Text('ចុះឈ្មោះ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('មានគណនីរួចហើយ?', style: TextStyle(color: ChartColors.inkSoft, fontSize: 13)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ចូលប្រព័ន្ធ', style: TextStyle(color: ChartColors.teal, fontWeight: FontWeight.w700, fontSize: 13)),
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