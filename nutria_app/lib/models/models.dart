class Profile {
  Profile({
    this.username = '',
    required this.goal,
    this.sex = 'm',
    this.age = 30,
    this.heightCm = 170,
    this.activityLevel = 'moderate',
    required this.dailyKcalTarget,
    required this.proteinTargetG,
    required this.carbsTargetG,
    required this.fatTargetG,
    required this.waterTargetGlasses,
    required this.fastingWindowHours,
    this.dailyStepsGoal = 8000,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final String username;
  final String goal;
  final String sex;
  final int age;
  final int heightCm;
  final String activityLevel;
  final int dailyKcalTarget;
  final int proteinTargetG;
  final int carbsTargetG;
  final int fatTargetG;
  final int waterTargetGlasses;
  final int fastingWindowHours;
  final int dailyStepsGoal;
  final double? currentWeightKg;
  final double? targetWeightKg;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        username: j['username'] ?? '',
        goal: j['goal'] ?? 'maintain',
        sex: j['sex'] ?? 'm',
        age: j['age'] ?? 30,
        heightCm: j['height_cm'] ?? 170,
        activityLevel: j['activity_level'] ?? 'moderate',
        dailyKcalTarget: j['daily_kcal_target'] ?? 2100,
        proteinTargetG: j['protein_target_g'] ?? 140,
        carbsTargetG: j['carbs_target_g'] ?? 220,
        fatTargetG: j['fat_target_g'] ?? 70,
        waterTargetGlasses: j['water_target_glasses'] ?? 8,
        fastingWindowHours: j['fasting_window_hours'] ?? 16,
        dailyStepsGoal: j['daily_steps_goal'] ?? 8000,
        currentWeightKg: (j['current_weight_kg'] as num?)?.toDouble(),
        targetWeightKg: (j['target_weight_kg'] as num?)?.toDouble(),
      );
}

class FoodItem {
  FoodItem({
    this.id,
    required this.name,
    this.grams,
    required this.kcal,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.ironMg = 0,
    this.calciumMg = 0,
    this.vitaminCMg = 0,
    this.vitaminDUg = 0,
    this.sodiumMg = 0,
    this.confidence,
  });

  final int? id;
  final String name;
  final double? grams;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double ironMg;
  final double calciumMg;
  final double vitaminCMg;
  final double vitaminDUg;
  final double sodiumMg;
  final double? confidence;

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: j['id'],
        name: j['name'] ?? '',
        grams: (j['grams'] as num?)?.toDouble(),
        kcal: (j['kcal'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (j['fiber_g'] as num?)?.toDouble() ?? 0,
        ironMg: (j['iron_mg'] as num?)?.toDouble() ?? 0,
        calciumMg: (j['calcium_mg'] as num?)?.toDouble() ?? 0,
        vitaminCMg: (j['vitamin_c_mg'] as num?)?.toDouble() ?? 0,
        vitaminDUg: (j['vitamin_d_ug'] as num?)?.toDouble() ?? 0,
        sodiumMg: (j['sodium_mg'] as num?)?.toDouble() ?? 0,
        confidence: (j['confidence'] as num?)?.toDouble() ?? (j['detection_confidence'] as num?)?.toDouble(),
      );
}

class Meal {
  Meal({required this.mealType, required this.loggedAt, required this.items, this.qualityScore = ''});

  final String mealType;
  final DateTime loggedAt;
  final List<FoodItem> items;
  final String qualityScore;

  int get totalKcal => items.fold(0, (sum, i) => sum + i.kcal);

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        mealType: j['meal_type'] ?? 'snack',
        loggedAt: DateTime.tryParse(j['logged_at'] ?? '') ?? DateTime.now(),
        items: (j['items'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
        qualityScore: j['quality_score'] ?? '',
      );
}

class TodaySummary {
  TodaySummary({
    required this.kcalTarget,
    required this.kcalConsumed,
    required this.kcalRemaining,
    required this.proteinTargetG,
    required this.proteinConsumedG,
    required this.carbsTargetG,
    required this.carbsConsumedG,
    required this.waterGlasses,
    required this.waterTarget,
    this.streakDays = 0,
    required this.meals,
  });

  final int kcalTarget;
  final int kcalConsumed;
  final int kcalRemaining;
  final int proteinTargetG;
  final double proteinConsumedG;
  final int carbsTargetG;
  final double carbsConsumedG;
  final int waterGlasses;
  final int waterTarget;
  final int streakDays;
  final List<Meal> meals;

  factory TodaySummary.fromJson(Map<String, dynamic> j) => TodaySummary(
        kcalTarget: j['kcal_target'] ?? 2100,
        kcalConsumed: j['kcal_consumed'] ?? 0,
        kcalRemaining: j['kcal_remaining'] ?? 0,
        proteinTargetG: j['protein_target_g'] ?? 140,
        proteinConsumedG: (j['protein_consumed_g'] as num?)?.toDouble() ?? 0,
        carbsTargetG: j['carbs_target_g'] ?? 220,
        carbsConsumedG: (j['carbs_consumed_g'] as num?)?.toDouble() ?? 0,
        waterGlasses: j['water_glasses'] ?? 0,
        waterTarget: j['water_target'] ?? 8,
        streakDays: j['streak_days'] ?? 0,
        meals: (j['meals'] as List? ?? []).map((e) => Meal.fromJson(e)).toList(),
      );
}

class CoachInsight {
  CoachInsight({required this.kind, required this.text, this.actionLabel = ''});

  final String kind;
  final String text;
  final String actionLabel;

  factory CoachInsight.fromJson(Map<String, dynamic> j) => CoachInsight(
        kind: j['kind'] ?? 'suggestion',
        text: j['text'] ?? '',
        actionLabel: j['action_label'] ?? '',
      );
}

class SavedRecipe {
  SavedRecipe({
    this.id,
    required this.name,
    this.mealType = 'any',
    this.instructions = '',
    this.ingredients = const [],
    required this.kcal,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final int? id;
  final String name;
  final String mealType;
  final String instructions;
  final List<FoodItem> ingredients;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory SavedRecipe.fromJson(Map<String, dynamic> j) => SavedRecipe(
        id: j['id'],
        name: j['name'] ?? '',
        mealType: j['meal_type'] ?? 'any',
        instructions: j['instructions'] ?? '',
        ingredients: (j['ingredients'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
        kcal: (j['kcal'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'meal_type': mealType,
        'instructions': instructions,
        'ingredients': ingredients
            .map((i) => {'name': i.name, 'grams': i.grams, 'kcal': i.kcal, 'protein_g': i.proteinG, 'carbs_g': i.carbsG, 'fat_g': i.fatG})
            .toList(),
      };
}

class FrequentFood {
  FrequentFood({required this.name, required this.count, required this.avgKcal, this.avgGrams, required this.avgProtein, required this.avgCarbs, required this.avgFat});
  final String name;
  final int count;
  final int avgKcal;
  final double? avgGrams;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;

  factory FrequentFood.fromJson(Map<String, dynamic> j) => FrequentFood(
        name: j['name'] ?? '',
        count: j['count'] ?? 0,
        avgKcal: ((j['avg_kcal'] as num?) ?? 0).round(),
        avgGrams: (j['avg_grams'] as num?)?.toDouble(),
        avgProtein: (j['avg_protein'] as num?)?.toDouble() ?? 0,
        avgCarbs: (j['avg_carbs'] as num?)?.toDouble() ?? 0,
        avgFat: (j['avg_fat'] as num?)?.toDouble() ?? 0,
      );
}

class Micronutrients {
  Micronutrients({
    required this.fiberG,
    required this.ironMg,
    required this.calciumMg,
    required this.vitaminCMg,
    required this.vitaminDUg,
    required this.sodiumMg,
  });

  final double fiberG;
  final double ironMg;
  final double calciumMg;
  final double vitaminCMg;
  final double vitaminDUg;
  final double sodiumMg;

  factory Micronutrients.fromJson(Map<String, dynamic> j) => Micronutrients(
        fiberG: (j['fiber_g'] as num?)?.toDouble() ?? 0,
        ironMg: (j['iron_mg'] as num?)?.toDouble() ?? 0,
        calciumMg: (j['calcium_mg'] as num?)?.toDouble() ?? 0,
        vitaminCMg: (j['vitamin_c_mg'] as num?)?.toDouble() ?? 0,
        vitaminDUg: (j['vitamin_d_ug'] as num?)?.toDouble() ?? 0,
        sodiumMg: (j['sodium_mg'] as num?)?.toDouble() ?? 0,
      );
}

class FastingSession {
  FastingSession({required this.startedAt, this.endedAt, required this.targetHours});
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetHours;

  bool get completed => endedAt != null;

  factory FastingSession.fromJson(Map<String, dynamic> j) => FastingSession(
        startedAt: DateTime.parse(j['started_at']).toLocal(),
        endedAt: j['ended_at'] != null ? DateTime.parse(j['ended_at']).toLocal() : null,
        targetHours: j['target_hours'] ?? 16,
      );
}

class FastingState {
  FastingState({this.active, required this.history});
  final FastingSession? active;
  final List<FastingSession> history;

  factory FastingState.fromJson(Map<String, dynamic> j) => FastingState(
        active: j['active'] != null ? FastingSession.fromJson(j['active']) : null,
        history: (j['history'] as List? ?? []).map((e) => FastingSession.fromJson(e)).toList(),
      );
}

class CoachStats {
  CoachStats({required this.avgKcal, required this.adherencePct, required this.streakDays, required this.loggedDays});
  final int avgKcal;
  final int adherencePct;
  final int streakDays;
  final int loggedDays;

  factory CoachStats.fromJson(Map<String, dynamic> j) => CoachStats(
        avgKcal: j['avg_kcal'] ?? 0,
        adherencePct: j['adherence_pct'] ?? 0,
        streakDays: j['streak_days'] ?? 0,
        loggedDays: j['logged_days'] ?? 0,
      );
}

class CoachResponse {
  CoachResponse({required this.insights, required this.stats});
  final List<CoachInsight> insights;
  final CoachStats stats;
}

class PlanMeal {
  PlanMeal({required this.mealType, required this.items});
  final String mealType;
  final List<FoodItem> items;

  int get totalKcal => items.fold(0, (sum, i) => sum + i.kcal);

  factory PlanMeal.fromJson(Map<String, dynamic> j) => PlanMeal(
        mealType: j['meal_type'] ?? 'snack',
        items: (j['items'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'meal_type': mealType,
        'items': items
            .map((i) => {'name': i.name, 'grams': i.grams, 'kcal': i.kcal, 'protein_g': i.proteinG, 'carbs_g': i.carbsG, 'fat_g': i.fatG})
            .toList(),
      };
}

class CoachChatMessage {
  CoachChatMessage({required this.role, required this.content, this.mealPlan, required this.createdAt});
  final String role; // 'user' | 'assistant'
  final String content;
  final List<PlanMeal>? mealPlan;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory CoachChatMessage.fromJson(Map<String, dynamic> j) => CoachChatMessage(
        role: j['role'] ?? 'assistant',
        content: j['content'] ?? '',
        mealPlan: j['meal_plan'] != null
            ? ((j['meal_plan']['meals'] as List?) ?? []).map((e) => PlanMeal.fromJson(e)).toList()
            : null,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class ParsedMeal {
  ParsedMeal({required this.items, required this.mealTypeGuess});
  final List<FoodItem> items;
  final String mealTypeGuess;

  factory ParsedMeal.fromJson(Map<String, dynamic> j) => ParsedMeal(
        items: (j['items'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
        mealTypeGuess: j['meal_type_guess'] ?? 'lunch',
      );
}

class WeeklyTrend {
  WeeklyTrend({required this.target, required this.days});
  final int target;
  final List<({DateTime date, int kcal})> days;

  factory WeeklyTrend.fromJson(Map<String, dynamic> j) => WeeklyTrend(
        target: j['target'] ?? 2100,
        days: (j['days'] as List? ?? [])
            .map((e) => (date: DateTime.parse(e['date']), kcal: (e['kcal'] as num?)?.toInt() ?? 0))
            .toList(),
      );
}

class CalendarDay {
  CalendarDay({required this.date, required this.kcal, required this.status});
  final DateTime date;
  final int kcal;
  final String status; // 'on_track' | 'off_track' | 'empty' | 'future'

  factory CalendarDay.fromJson(Map<String, dynamic> j) => CalendarDay(
        date: DateTime.parse(j['date']),
        kcal: j['kcal'] ?? 0,
        status: j['status'] ?? 'empty',
      );
}

class Achievement {
  Achievement({required this.id, required this.label, required this.icon, required this.achieved});
  final String id;
  final String label;
  final String icon;
  final bool achieved;

  factory Achievement.fromJson(Map<String, dynamic> j) =>
      Achievement(id: j['id'] ?? '', label: j['label'] ?? '', icon: j['icon'] ?? '🏅', achieved: j['achieved'] ?? false);
}

class ProgressOverview {
  ProgressOverview({
    required this.streakDays,
    required this.loggedDays30,
    required this.onTrackDays30,
    required this.adherencePct30,
    required this.avgKcal30,
    this.weightChange90d,
    this.currentWeightKg,
    this.targetWeightKg,
    this.projectedDate,
    this.kgPerWeek,
    required this.calendar,
    required this.weights,
    required this.badges,
  });

  final int streakDays;
  final int loggedDays30;
  final int onTrackDays30;
  final int adherencePct30;
  final int avgKcal30;
  final double? weightChange90d;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final DateTime? projectedDate;
  final double? kgPerWeek;
  final List<CalendarDay> calendar;
  final List<({DateTime date, double weightKg})> weights;
  final List<Achievement> badges;

  factory ProgressOverview.fromJson(Map<String, dynamic> j) => ProgressOverview(
        streakDays: j['streak_days'] ?? 0,
        loggedDays30: j['logged_days_30'] ?? 0,
        onTrackDays30: j['on_track_days_30'] ?? 0,
        adherencePct30: j['adherence_pct_30'] ?? 0,
        avgKcal30: j['avg_kcal_30'] ?? 0,
        weightChange90d: (j['weight_change_90d'] as num?)?.toDouble(),
        currentWeightKg: (j['current_weight_kg'] as num?)?.toDouble(),
        targetWeightKg: (j['target_weight_kg'] as num?)?.toDouble(),
        projectedDate: j['projected_date'] != null ? DateTime.tryParse(j['projected_date']) : null,
        kgPerWeek: (j['kg_per_week'] as num?)?.toDouble(),
        calendar: (j['calendar'] as List? ?? []).map((e) => CalendarDay.fromJson(e)).toList(),
        weights: (j['weights'] as List? ?? [])
            .map((e) => (date: DateTime.parse(e['date']), weightKg: (e['weight_kg'] as num).toDouble()))
            .toList(),
        badges: (j['badges'] as List? ?? []).map((e) => Achievement.fromJson(e)).toList(),
      );
}

class FoodScanResult {
  FoodScanResult({required this.items, required this.qualityScore, required this.qualityNote});
  final List<FoodItem> items;
  final String qualityScore;
  final String qualityNote;

  int get totalKcal => items.fold(0, (sum, i) => sum + i.kcal);

  factory FoodScanResult.fromJson(Map<String, dynamic> j) => FoodScanResult(
        items: (j['items'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
        qualityScore: j['quality_score'] ?? '',
        qualityNote: j['quality_note'] ?? '',
      );
}
