import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/Home_screen.dart' show ChartColors;
import '../../services/auth_api.dart';
import '../../services/vet_api.dart' show ApiException;


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmNewPassword = TextEditingController();

  bool _loadingProfile = true;
  bool _savingInfo = false;
  bool _savingPassword = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmNewPassword.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await AuthApi.getProfile();
      _name.text = profile['name']?.toString() ?? '';
      _email.text = profile['email']?.toString() ?? '';
      _phone.text = profile['phone']?.toString() ?? '';
    } catch (_) {
      // បើទាញព័ត៌មានមិនបាន អ្នកប្រើនៅតែអាចបំពេញដោយដៃបាន
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveInfo() async {
    if (!_infoFormKey.currentState!.validate()) return;
    setState(() => _savingInfo = true);
    try {
      await AuthApi.updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      _snack('បានកែប្រព័ត៌មានប្រវត្តិរូបជោគជ័យ', isError: false);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចភ្ជាប់ទៅ server: $e');
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await AuthApi.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmNewPassword.clear();
      _snack('បានប្តូរពាក្យសម្ងាត់ជោគជ័យ', isError: false);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចភ្ជាប់ទៅ server: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _snack(String text, {bool isError = true}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), backgroundColor: isError ? ChartColors.rose : ChartColors.teal),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChartColors.bg,
      appBar: AppBar(
        backgroundColor: ChartColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: ChartColors.ink),
        title: Text('កែសម្រួលប្រវត្តិរូប', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: ChartColors.ink)),
      ),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatar(),
                    const SizedBox(height: 28),

                    // ---------- ព័ត៌មានទូទៅ ----------
                    _sectionLabel('ព័ត៌មានទូទៅ'),
                    const SizedBox(height: 14),
                    Form(
                      key: _infoFormKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel('ឈ្មោះពេញ'),
                        _field(
                          controller: _name,
                          hint: 'ឧ. Dr. Dara',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'សូមបញ្ចូលឈ្មោះ' : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('អ៊ីមែល'),
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

                        _fieldLabel('លេខទូរស័ព្ទ'),
                        _field(
                          controller: _phone,
                          hint: 'ឧ. 0977 123 456',
                          keyboard: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'សូមបញ្ចូលលេខទូរស័ព្ទ' : null,
                        ),
                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _savingInfo ? null : _saveInfo,
                            style: FilledButton.styleFrom(
                              backgroundColor: ChartColors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: _savingInfo
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('រក្សាទុកព័ត៌មាន', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 34),
                    Container(height: 1, color: ChartColors.line),
                    const SizedBox(height: 26),

                    // ---------- ប្តូរពាក្យសម្ងាត់ ----------
                    _sectionLabel('ប្តូរពាក្យសម្ងាត់'),
                    const SizedBox(height: 14),
                    Form(
                      key: _passwordFormKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel('ពាក្យសម្ងាត់បច្ចុប្បន្ន'),
                        _field(
                          controller: _currentPassword,
                          hint: '••••••••',
                          obscure: _obscureCurrent,
                          suffix: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'សូមបញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្ន' : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('ពាក្យសម្ងាត់ថ្មី'),
                        _field(
                          controller: _newPassword,
                          hint: 'យ៉ាងតិច ៦ តួអក្សរ',
                          obscure: _obscureNew,
                          suffix: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់ថ្មី';
                            if (v.length < 6) return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('បញ្ជាក់ពាក្យសម្ងាត់ថ្មី'),
                        _field(
                          controller: _confirmNewPassword,
                          hint: 'វាយបញ្ចូលម្តងទៀត',
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ChartColors.inkSoft, size: 20),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) => (v != _newPassword.text) ? 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ' : null,
                        ),
                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _savingPassword ? null : _savePassword,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ChartColors.teal,
                              side: const BorderSide(color: ChartColors.teal, width: 1.4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: _savingPassword
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: ChartColors.teal, strokeWidth: 2))
                                : const Text('ប្តូរពាក្យសម្ងាត់', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _avatar() => Center(
        child: Column(children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: ChartColors.tealTint, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.person_rounded, color: ChartColors.teal, size: 40),
          ),
          const SizedBox(height: 10),
          Text(_name.text.isEmpty ? 'អ្នកប្រើប្រាស់' : _name.text, style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: ChartColors.ink)),
        ]),
      );

  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: ChartColors.ink));

  Widget _fieldLabel(String text) => Padding(
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