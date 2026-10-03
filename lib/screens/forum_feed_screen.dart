import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'create_post_screen.dart';

class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen> {
  final _posts = FirestoreService.instance.postsStream();
  final _profile = FirestoreService.instance.profileStream();

  bool _skinTwinOnly = false;

  void _changeFilter(bool skinTwinOnly) {
    if (_skinTwinOnly == skinTwinOnly) return;

    setState(() {
      _skinTwinOnly = skinTwinOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,

        // SkinWais branding + filter dropdown
        title: StreamBuilder<UserProfile?>(
          stream: _profile,
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;

            return PopupMenuButton<bool>(
              tooltip: 'Filter posts',
              initialValue: _skinTwinOnly,
              onSelected: _changeFilter,
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<bool>(
                  value: false,
                  child: Row(
                    children: [
                      Icon(
                        !_skinTwinOnly
                            ? Icons.check_circle
                            : Icons.public_outlined,
                        size: 20,
                        color: !_skinTwinOnly
                            ? AppColors.green
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Everyone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<bool>(
                  value: true,
                  child: Row(
                    children: [
                      Icon(
                        _skinTwinOnly
                            ? Icons.check_circle
                            : Icons.people_outline,
                        size: 20,
                        color: _skinTwinOnly
                            ? AppColors.green
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile != null
                              ? 'Skin twins · ${profile.skinType}'
                              : 'Skin twins',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Branding shown in AppBar
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.greenLight,
                    child: Icon(
                      Icons.spa_outlined,
                      color: AppColors.green,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SkinWais',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.green,
                    size: 21,
                  ),
                ],
              ),
            );
          },
        ),
      ),
 
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, profileSnapshot) {
          final me = profileSnapshot.data;

          return StreamBuilder<List<Post>>(
            stream: _posts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load posts.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final allPosts = snapshot.data!;

              final posts = (_skinTwinOnly && me != null)
                  ? allPosts
                      .where(
                        (post) => post.authorSkinType == me.skinType,
                      )
                      .toList()
                  : allPosts;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: posts.isEmpty
                    ? _EmptyFeed(
                        key: ValueKey(_skinTwinOnly),
                        skinTwinOnly: _skinTwinOnly,
                      )
                    : ListView.builder(
                        key: ValueKey(
                          _skinTwinOnly ? 'skin_twins' : 'everyone',
                        ),
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 90,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            post: posts[index],
                          );
                        },
                      ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final bool skinTwinOnly;

  const _EmptyFeed({
    super.key,
    required this.skinTwinOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.greenLight,
              child: Icon(
                Icons.forum_outlined,
                color: AppColors.green,
                size: 31,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              skinTwinOnly
                  ? 'No posts from your Skin Twins yet'
                  : 'No posts yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skinTwinOnly
                  ? 'Tap SkinWais above and switch to Everyone to see all community posts.'
                  : 'Be the first to share something with the SkinWais community.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}