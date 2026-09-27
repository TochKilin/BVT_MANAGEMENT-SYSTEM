import 'package:flutter/material.dart';
import '../../services/auth_api.dart';

const _resetGreen = Color(0xFF0E806F);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _contact = TextEditingController();

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_contact.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបញ្ចូលអ៊ីមែល ឬលេខទូរស័ព្ទ')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(contact: _contact.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ResetPage(
    title: 'ភ្លេចពាក្យសម្ងាត់',
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'សូមបញ្ចូលអ៊ីមែល ឬលេខទូរស័ព្ទ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 42),
        const Text('អ៊ីមែល ឬលេខទូរស័ព្ទ'),
        const SizedBox(height: 10),
        _ResetField(controller: _contact),
        const SizedBox(height: 24),
        _ResetButton(label: 'ផ្ញើ Code', onPressed: _sendCode),
      ],
    ),
  );
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.contact, super.key});

  final String contact;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _verify() {
    if (!RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបញ្ចូលលេខកូដ ៦ ខ្ទង់')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SetPasswordScreen(contact: widget.contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ResetPage(
    title: 'បញ្ចូលកូដសម្ងាត់',
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('បញ្ចូលលេខកូដ ៦ ខ្ទង់', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 44),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _ResetButton(label: 'ផ្ទៀងផ្ទាត់ Code', onPressed: _verify),
        const SizedBox(height: 14),
        const Text('សាកល្បង៖ អាចបញ្ចូលលេខកូដណាក៏បាន'),
      ],
    ),
  );
}

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({required this.contact, super.key});

  final String contact;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 6 || _password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមពិនិត្យពាក្យសម្ងាត់ (យ៉ាងតិច ៦ តួ និងត្រូវគ្នា)')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthApi.resetPassword(
        contact: widget.contact,
        newPassword: _password.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('បានប្ដូរពាក្យសម្ងាត់។ សូមចូលប្រព័ន្ធ។')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ប្ដូរពាក្យសម្ងាត់មិនបានសម្រេច: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ResetPage(
    title: 'កំណត់ Password',
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text('កំណត់ Password ថ្មី', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 36),
        const Text('ពាក្យសម្ងាត់ថ្មី'),
        const SizedBox(height: 8),
        _ResetField(controller: _password, obscure: true),
        const SizedBox(height: 22),
        const Text('បញ្ជាក់ពាក្យសម្ងាត់'),
        const SizedBox(height: 8),
        _ResetField(controller: _confirm, obscure: true),
        const SizedBox(height: 28),
        _ResetButton(
          label: _saving ? 'កំពុងរក្សាទុក...' : 'កំណត់ពាក្យសម្ងាត់ថ្មី',
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}

class _ResetPage extends StatelessWidget {
  const _ResetPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(title, style: const TextStyle(color: Colors.black)),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
        child: SizedBox(height: MediaQuery.sizeOf(context).height * .68, child: child),
      ),
    ),
  );
}

class _ResetField extends StatelessWidget {
  const _ResetField({required this.controller, this.obscure = false});

  final TextEditingController controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    decoration: const InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    ),
  );
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 62,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _resetGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 17)),
    ),
  );
}
