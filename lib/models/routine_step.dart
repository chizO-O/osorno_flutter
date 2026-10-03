/// A single step in a skincare routine, e.g. "Cleanser" -> "CeraVe Foaming Wash".
class RoutineStep {
  final String stepName;
  final String product;
  final String timeOfDay; // "AM" or "PM"

  RoutineStep({
    required this.stepName,
    required this.product,
    required this.timeOfDay,
  });

  factory RoutineStep.fromMap(Map<String, dynamic> map) => RoutineStep(
        stepName: map['stepName'] ?? '',
        product: map['product'] ?? '',
        timeOfDay: map['timeOfDay'] ?? 'AM',
      );

  Map<String, dynamic> toMap() => {
        'stepName': stepName,
        'product': product,
        'timeOfDay': timeOfDay,
      };
}

List<RoutineStep> routineFromList(dynamic raw) => (raw as List? ?? [])
    .map((e) => RoutineStep.fromMap(Map<String, dynamic>.from(e as Map)))
    .toList();
