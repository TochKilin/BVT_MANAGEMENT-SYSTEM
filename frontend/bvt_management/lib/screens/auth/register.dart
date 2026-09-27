import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

      // Register 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('បានចុះឈ្មោះជោគជ័យ! សូមចូលប្រព័ន្ធ'),
          backgroundColor: Color(0xFF1F8A8A),
        ),
      );
      Navigator.of(context).pop(); 
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចភ្ជាប់ទៅ server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFFD6455D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2A2E)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'បង្កើតគណនីថ្មី',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2A2E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ចុះឈ្មោះដើម្បីចាប់ផ្តើមគ្រប់គ្រងគ្លីនិករបស់អ្នក',
                  style: TextStyle(color: Color(0xFF6B7479), fontSize: 14),
                ),
                const SizedBox(height: 28),

                // ឈ្មោះ
                _label('ឈ្មោះពេញ'),
                _field(
                  controller: _name,
                  hint: 'ឧ. Dr. Dara',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'សូមបញ្ចូលឈ្មោះ'
                      : null,
                ),
                const SizedBox(height: 16),

                // អ៊ីមែល
                _label('អ៊ីមែល'),
                _field(
                  controller: _email,
                  hint: 'you@example.com',
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'សូមបញ្ចូលអ៊ីមែល';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'អ៊ីមែលមិនត្រឹមត្រូវ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // លេខទូរស័ព្ទ
                _label('លេខទូរស័ព្ទ'),
                _field(
                  controller: _phone,
                  hint: 'ឧ. 0977 123 456',
                  keyboard: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'សូមបញ្ចូលលេខទូរស័ព្ទ'
                      : null,
                ),
                const SizedBox(height: 16),

                // ពាក្យសម្ងាត់
                _label('ពាក្យសម្ងាត់'),
                _field(
                  controller: _password,
                  hint: 'យ៉ាងតិច ៦ តួអក្សរ',
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF6B7479),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'សូមបញ្ចូលពាក្យសម្ងាត់';
                    }
                    if (v.length < 6) {
                      return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // បញ្ជាក់ពាក្យសម្ងាត់
                _label('បញ្ជាក់ពាក្យសម្ងាត់'),
                _field(
                  controller: _confirmPassword,
                  hint: 'វាយបញ្ចូលម្តងទៀត',
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF6B7479),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      (v != _password.text) ? 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ' : null,
                ),
                const SizedBox(height: 28),

                // ប៊ូតុងចុះឈ្មោះ
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      // backgroundColor: const Color(0xFF1F8A8A),//0xFF0E6B5C
                      backgroundColor: const Color(0xFF0E6B5C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFFFFF),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ចុះឈ្មោះ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ទៅ Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'មានគណនីរួចហើយ?',
                      style: TextStyle(color: Color(0xFF6B7479), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'ចូលប្រព័ន្ធ',
                        style: TextStyle(
                          color: Color(0xFF1F8A8A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1F2A2E),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7479)),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(const Color(0xFFD9D5CC)),
        enabledBorder: border(const Color(0xFFD9D5CC)),
        focusedBorder: border(const Color(0xFF1F8A8A), 1.5),
        errorBorder: border(const Color(0xFFD6455D)),
      ),
    );
  }
}