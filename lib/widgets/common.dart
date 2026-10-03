import 'package:flutter/material.dart';
import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class Pill extends StatelessWidget {
  final String text;
  final bool highlight;
  const Pill(this.text, {super.key, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.greenLight : AppColors.field,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: highlight ? AppColors.greenDark : AppColors.muted,
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  const Avatar({super.key, required this.name, this.photoUrl, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greenLight,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.greenDark,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.85,
              ),
            )
          : null,
    );
  }
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${t.day}/${t.month}/${t.year}';
}

/// Compact Facebook-like social controls. Only the icons and counts are shown;
/// the labels are exposed as tooltips for accessibility.
class ReactionBar extends StatelessWidget {
  final Post post;
  final VoidCallback? onCommentTap;
  const ReactionBar({super.key, required this.post, this.onCommentTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostReaction?>(
      stream: FirestoreService.instance.myReactionStream(post.id),
      builder: (context, snapshot) {
        final mine = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReactionIconButton(
              tooltip: 'Agree',
              icon: Icons.thumb_up_outlined,
              selectedIcon: Icons.thumb_up_rounded,
              count: post.agreeCount,
              selected: mine == PostReaction.agree,
              onTap: () => FirestoreService.instance
                  .setReaction(postId: post.id, reaction: PostReaction.agree),
            ),
            const SizedBox(width: 2),
            _ReactionIconButton(
              tooltip: 'Disagree',
              icon: Icons.thumb_down_outlined,
              selectedIcon: Icons.thumb_down_rounded,
              count: post.disagreeCount,
              selected: mine == PostReaction.disagree,
              onTap: () => FirestoreService.instance
                  .setReaction(postId: post.id, reaction: PostReaction.disagree),
            ),
            const SizedBox(width: 2),
            _ReactionIconButton(
              tooltip: 'Comment',
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              count: post.commentCount,
              selected: false,
              onTap: onCommentTap,
            ),
          ],
        );
      },
    );
  }
}

class _ReactionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  const _ReactionIconButton({
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.greenDark : AppColors.muted;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.greenLight : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    key: ValueKey(selected),
                    size: 17,
                    color: color,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final bool showOwnerActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.showOwnerActions = false,
    this.onEdit,
    this.onDelete,
  });

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _open(context),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Avatar(name: post.authorName, radius: 15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${post.authorSkinType} skin',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeAgo(post.createdAt),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11.5),
                    ),
                    if (showOwnerActions)
                      PopupMenuButton<String>(
                        tooltip: 'Post options',
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
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
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('Delete post',
                                  style: TextStyle(color: Colors.redAccent)),
                            ]),
                          ),
                        ],
                      ),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final t in post.tags) Pill('#$t'),
                    ]),
                  ],
                  if (post.hasRoutine) ...[
                    const SizedBox(height: 10),
                    const Pill('Routine', highlight: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 4),
            ReactionBar(post: post, onCommentTap: () => _open(context)),
          ],
        ),
      ),
    );
  }
}
