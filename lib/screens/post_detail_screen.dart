import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'create_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final _post = FirestoreService.instance.postStream(widget.postId);
  late final _comments = FirestoreService.instance.commentsStream(widget.postId);
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await FirestoreService.instance.addComment(postId: widget.postId, body: text);
  }

  Future<void> _cloneRoutine(Post post) async {
    await FirestoreService.instance.cloneRoutine(post.routine);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Cloned ${post.authorName}'s routine to your profile")),
    );
  }

  void _edit(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreatePostScreen(existingPost: post)),
    );
  }


  Future<void> _delete(Post post) async {
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
    if (confirmed != true || !mounted) return;
    try {
      await FirestoreService.instance.deletePost(post.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: StreamBuilder<Post?>(
        stream: _post,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snapshot.data;
          if (post == null) return const Center(child: Text('Post not found'));
          final isMine = post.authorId == FirestoreService.instance.myUid;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      Avatar(name: post.authorName, radius: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${post.authorSkinType} skin · ${timeAgo(post.createdAt)}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isMine)
                        PopupMenuButton<String>(
                          tooltip: 'Post options',
                          onSelected: (value) {
                            if (value == 'edit') _edit(post);
                            if (value == 'delete') _delete(post);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Edit post'),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.redAccent),
                                SizedBox(width: 10),
                                Text('Delete post',
                                    style: TextStyle(color: Colors.redAccent)),
                              ]),
                            ),
                          ],
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Text(post.title,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(post.body, style: const TextStyle(height: 1.5)),
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final t in post.tags) Pill('#$t'),
                      ]),
                    ],
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 4),
                    ReactionBar(
                      post: post,
                      onCommentTap: () => _commentFocus.requestFocus(),
                    ),
                    if (post.hasRoutine) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Routine', style: TextStyle(fontWeight: FontWeight.w700)),
                          if (!isMine)
                            FilledButton.icon(
                              onPressed: () => _cloneRoutine(post),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              icon: const Icon(Icons.copy_all, size: 18),
                              label: const Text('Clone routine'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(children: [
                          for (final step in post.routine)
                            ListTile(
                              dense: true,
                              leading: Pill(step.timeOfDay, highlight: step.timeOfDay == 'AM'),
                              title: Text(step.stepName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(step.product),
                            ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('Comments (${post.commentCount})',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Comment>>(
                      stream: _comments,
                      builder: (context, snap) {
                        final comments = snap.data ?? [];
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No comments yet. Be the first to reply.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          );
                        }
                        return Column(children: [
                          for (final c in comments)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Avatar(name: c.authorName, radius: 14),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(c.authorName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(width: 6),
                                          Text(timeAgo(c.createdAt),
                                              style: const TextStyle(
                                                  color: AppColors.muted, fontSize: 11.5)),
                                        ]),
                                        const SizedBox(height: 2),
                                        Text(c.body, style: const TextStyle(height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ]);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        focusNode: _commentFocus,
                        controller: _commentController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.green),
                      onPressed: _sendComment,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
