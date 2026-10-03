import 'package:cloud_firestore/cloud_firestore.dart';
import 'routine_step.dart';

enum PostReaction { agree, disagree }

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorSkinType;
  final List<String> authorConcerns;
  final String title;
  final String body;
  final List<String> tags;
  final List<RoutineStep> routine;
  final DateTime createdAt;
  final int commentCount;
  final int agreeCount;
  final int disagreeCount;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorSkinType,
    required this.authorConcerns,
    required this.title,
    required this.body,
    required this.tags,
    required this.routine,
    required this.createdAt,
    this.commentCount = 0,
    this.agreeCount = 0,
    this.disagreeCount = 0,
  });

  bool get hasRoutine => routine.isNotEmpty;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Post(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? 'Unknown',
      authorSkinType: d['authorSkinType'] ?? '',
      authorConcerns: List<String>.from(d['authorConcerns'] ?? []),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      routine: routineFromList(d['routine']),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentCount: (d['commentCount'] ?? 0) as int,
      agreeCount: (d['agreeCount'] ?? 0) as int,
      disagreeCount: (d['disagreeCount'] ?? 0) as int,
    );
  }
}

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Comment(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? 'Unknown',
      body: d['body'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
