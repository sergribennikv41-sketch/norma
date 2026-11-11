import 'nutrients.dart';

class DailyTargets {
  const DailyTargets({
    required this.bmr,
    required this.tdee,
    required this.nutrients,
  });

  final double bmr;
  final double tdee;
  final Nutrients nutrients;
}
