import 'package:cloud_firestore/cloud_firestore.dart';
import 'routine_step.dart';

/// Fixed lists make the "Skin Twin" filter a simple equality check.
const List<String> kSkinTypes = ['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal'];

const List<String> kConcerns = [
  'Acne',
  'Redness',
  'Dryness',
  'Aging',
  'Hyperpigmentation',
  'Sensitivity',
  'Melasma'
];

class UserProfile {
  final String uid;
  final String displayName;
  final String skinType;
  final List<String> concerns;
  final List<RoutineStep> myRoutine;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.skinType,
    required this.concerns,
    this.myRoutine = const [],
    this.photoUrl,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] ?? '',
      skinType: d['skinType'] ?? kSkinTypes.first,
      concerns: List<String>.from(d['concerns'] ?? []),
      myRoutine: routineFromList(d['myRoutine']),
      photoUrl: d['photoUrl'],
    );
  }
}
