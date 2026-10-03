import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Used twice: first-time setup (no [existing], AuthGate swaps to the app once
/// the profile is saved) and editing from the Profile tab (pops when done).
class SkinProfileSetupScreen extends StatefulWidget {
  final UserProfile? existing;
  const SkinProfileSetupScreen({super.key, this.existing});

  @override
  State<SkinProfileSetupScreen> createState() => _SkinProfileSetupScreenState();
}

class _SkinProfileSetupScreenState extends State<SkinProfileSetupScreen> {
  late final _nameController = TextEditingController(
      text: widget.existing?.displayName ?? AuthService.currentUser?.displayName ?? '');
  late String _skinType = widget.existing?.skinType ?? kSkinTypes.first;
  late final Set<String> _concerns = {...?widget.existing?.concerns};
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a display name')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveProfile(
        displayName: name,
        skinType: _skinType,
        concerns: _concerns.toList(),
        photoUrl: AuthService.currentUser?.photoURL,
      );
      if (_isEditing && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit skin profile' : 'Your skin profile'),
        actions: [
          if (!_isEditing)
            const TextButton(onPressed: AuthService.signOut, child: Text('Sign out')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEditing) ...[
              const Text('Tell us about your skin so we can match you with your skin twins.',
                  style: TextStyle(color: Colors.black54, height: 1.4)),
              const SizedBox(height: 24),
            ],
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 28),
            const Text('Skin type', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kSkinTypes
                  .map((type) => ChoiceChip(
                        label: Text(type),
                        selected: _skinType == type,
                        onSelected: (_) => setState(() => _skinType = type),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            const Text('Concerns (pick any)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kConcerns.map((c) {
                return FilterChip(
                  label: Text(c),
                  selected: _concerns.contains(c),
                  onSelected: (val) => setState(() {
                    val ? _concerns.add(c) : _concerns.remove(c);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save changes' : 'Save and continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
