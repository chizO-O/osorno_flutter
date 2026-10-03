import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'skin_profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profile = FirestoreService.instance.profileStream();

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in with email or Google any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Avatar(name: profile.displayName, photoUrl: profile.photoUrl, radius: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          Pill('${profile.skinType} skin', highlight: true),
                          for (final c in profile.concerns) Pill(c),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.tune, color: AppColors.muted),
                title: const Text('Edit skin profile'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SkinProfileSetupScreen(existing: profile))),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_outlined, color: AppColors.muted),
                title: const Text('Saved routine'),
                trailing: Text('${profile.myRoutine.length} steps',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                onTap: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: Colors.white,
                  builder: (_) => _SavedRoutineSheet(profile: profile),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.muted),
                title: const Text('FAQs and help'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () {
                  // Wire this up to a static FAQ screen when you build one.
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Log out',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _confirmLogout,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedRoutineSheet extends StatelessWidget {
  final UserProfile profile;
  const _SavedRoutineSheet({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My routine',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            if (profile.myRoutine.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No routine saved yet. Clone one from a post.',
                    style: TextStyle(color: AppColors.muted)),
              )
            else
              for (final step in profile.myRoutine)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Pill(step.timeOfDay, highlight: step.timeOfDay == 'AM'),
                  title: Text(step.stepName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(step.product),
                ),
          ],
        ),
      ),
    );
  }
}
