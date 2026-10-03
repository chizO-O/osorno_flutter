import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'create_post_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  void _create(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  void _edit(BuildContext context, Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreatePostScreen(existingPost: post)),
    );
  }

  Future<void> _delete(BuildContext context, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently delete the post, its comments, and its reactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await FirestoreService.instance.deletePost(post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        actions: [
          IconButton(
            tooltip: 'Create post',
            onPressed: () => _create(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: FirestoreService.instance.myPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load your posts.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.greenLight,
                      child: Icon(Icons.article_outlined, color: AppColors.green),
                    ),
                    const SizedBox(height: 16),
                    const Text('No posts yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 6),
                    const Text(
                      'Everything you post will be saved here so you can find, edit, or delete it easily.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _create(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create a post'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 6, bottom: 88),
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(
              post: posts[i],
              showOwnerActions: true,
              onEdit: () => _edit(context, posts[i]),
              onDelete: () => _delete(context, posts[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
