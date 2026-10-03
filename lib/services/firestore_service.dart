import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/routine_step.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  String get myUid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _me => _db.collection('users').doc(myUid);
  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  Stream<UserProfile?> profileStream() =>
      _me.snapshots().map((s) => s.exists ? UserProfile.fromDoc(s) : null);

  Future<UserProfile?> _getProfile() async {
    final s = await _me.get();
    return s.exists ? UserProfile.fromDoc(s) : null;
  }

  Future<void> saveProfile({
    required String displayName,
    required String skinType,
    required List<String> concerns,
    String? photoUrl,
  }) {
    return _me.set({
      'displayName': displayName,
      'skinType': skinType,
      'concerns': concerns,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Post>> postsStream() => _posts
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map(Post.fromDoc).toList());

  Stream<List<Post>> myPostsStream() => postsStream()
      .map((posts) => posts.where((p) => p.authorId == myUid).toList());

  Stream<Post?> postStream(String postId) =>
      _posts.doc(postId).snapshots().map((s) => s.exists ? Post.fromDoc(s) : null);

  Future<void> createPost({
    required String title,
    required String body,
    required List<String> tags,
    required List<RoutineStep> routine,
  }) async {
    final profile = await _getProfile();
    if (profile == null) return;
    await _posts.add({
      'authorId': myUid,
      'authorName': profile.displayName,
      'authorSkinType': profile.skinType,
      'authorConcerns': profile.concerns,
      'title': title,
      'body': body,
      'tags': tags,
      'routine': routine.map((r) => r.toMap()).toList(),
      'commentCount': 0,
      'agreeCount': 0,
      'disagreeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String body,
    required List<String> tags,
    required List<RoutineStep> routine,
  }) async {
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['authorId'] != myUid) {
      throw StateError('You can only edit your own posts.');
    }
    await ref.update({
      'title': title,
      'body': body,
      'tags': tags,
      'routine': routine.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> deletePost(String postId) async {
    final postRef = _posts.doc(postId);
    final snap = await postRef.get();
    if (!snap.exists || snap.data()?['authorId'] != myUid) {
      throw StateError('You can only delete your own posts.');
    }

    // Firestore does not automatically delete subcollections with a document,
    // so remove comments and reactions first to avoid leaving orphaned data.
    await _deleteSubcollection(postRef.collection('comments'));
    await _deleteSubcollection(postRef.collection('reactions'));
    await postRef.delete();
  }

  Future<void> _deleteSubcollection(
      CollectionReference<Map<String, dynamic>> collection) async {
    while (true) {
      final page = await collection.limit(400).get();
      if (page.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (page.docs.length < 400) return;
    }
  }

  Stream<PostReaction?> myReactionStream(String postId) => _posts
      .doc(postId)
      .collection('reactions')
      .doc(myUid)
      .snapshots()
      .map((s) {
    if (!s.exists) return null;
    final value = s.data()?['value'];
    if (value == 'agree') return PostReaction.agree;
    if (value == 'disagree') return PostReaction.disagree;
    return null;
  });

  Future<void> setReaction({
    required String postId,
    required PostReaction reaction,
  }) async {
    final postRef = _posts.doc(postId);
    final reactionRef = postRef.collection('reactions').doc(myUid);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final reactionSnap = await tx.get(reactionRef);
      if (!postSnap.exists) return;

      final oldValue = reactionSnap.data()?['value'] as String?;
      final newValue = reaction == PostReaction.agree ? 'agree' : 'disagree';
      var agreeDelta = 0;
      var disagreeDelta = 0;

      if (oldValue == newValue) {
        if (newValue == 'agree') {
          agreeDelta = -1;
        } else {
          disagreeDelta = -1;
        }
        tx.delete(reactionRef);
      } else {
        if (oldValue == 'agree') agreeDelta--;
        if (oldValue == 'disagree') disagreeDelta--;
        if (newValue == 'agree') agreeDelta++;
        if (newValue == 'disagree') disagreeDelta++;
        tx.set(reactionRef, {
          'userId': myUid,
          'value': newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final data = postSnap.data()!;
      final currentAgree = (data['agreeCount'] ?? 0) as int;
      final currentDisagree = (data['disagreeCount'] ?? 0) as int;
      tx.update(postRef, {
        'agreeCount': (currentAgree + agreeDelta).clamp(0, 1 << 31),
        'disagreeCount': (currentDisagree + disagreeDelta).clamp(0, 1 << 31),
      });
    });
  }

  Stream<List<Comment>> commentsStream(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map(Comment.fromDoc).toList());

  Future<void> addComment({required String postId, required String body}) async {
    final profile = await _getProfile();
    if (profile == null) return;
    final postRef = _posts.doc(postId);
    final batch = _db.batch();
    batch.set(postRef.collection('comments').doc(), {
      'authorId': myUid,
      'authorName': profile.displayName,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> cloneRoutine(List<RoutineStep> routine) =>
      _me.update({'myRoutine': routine.map((r) => r.toMap()).toList()});
}
