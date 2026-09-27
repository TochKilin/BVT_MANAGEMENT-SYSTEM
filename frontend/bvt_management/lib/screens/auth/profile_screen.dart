import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../home/Home_screen.dart' show ChartColors;
import '../../services/auth_api.dart';
import '../../services/vet_api.dart' show ApiException, VetApi;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _uploading = false;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      final user = await AuthApi.getProfile();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      final cached = await AuthApi.getUser();
      if (mounted && cached != null) setState(() => _user = cached);
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  String? _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${VetApi.baseUrl}$cleanPath';
    debugPrint('--> Loading Avatar URL: $fullUrl'); 
    return fullUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final url = await AuthApi.updateAvatar(File(picked.path));
      if (!mounted) return;

      setState(() => _user = {...?_user, 'avatarUrl': url});
      await _loadUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('បានប្តូររូបភាពប្រវត្តិរូបជោគជ័យ'),
          backgroundColor: Color(0xFF0E6B5C),
        ),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចប្តូររូបភាពបានទេ: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFFE05C86),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawAvatarUrl = _user?['avatarUrl']?.toString();
    final fullAvatarUrl = _resolveAvatarUrl(rawAvatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
        title: Text(
          'ប្រវត្តិរូប',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A202C),
          ),
        ),
      ),
      body: SafeArea(
        child: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(fullAvatarUrl),
                    const SizedBox(height: 16),
                    Text(
                      _user?['name']?.toString() ?? '',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?['email']?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Avatar with an upload overlay and a camera button
  Widget _buildAvatar(String? fullAvatarUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // use ClipRRect + Image.network 
        ClipRRect(
          borderRadius: BorderRadius.circular(56),
          child: Container(
            width: 112,
            height: 112,
            color: const Color(0xFFE2E8F0),
            child: fullAvatarUrl != null
                ? Image.network(
                    fullAvatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0E6B5C),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image Load Error: $error');
                      return const Icon(
                        Icons.person_rounded,
                        size: 56,
                        color: Color(0xFF4A5568),
                      );
                    },
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: Color(0xFF4A5568),
                  ),
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0E6B5C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}