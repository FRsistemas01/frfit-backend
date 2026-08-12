import '../models/models.dart';

class MockData {
  MockData._();

  static Profile profileForGoal(String goal) {
    final maintenance = 2100;
    final target = switch (goal) {
      'lose' => (maintenance * 0.8).round(),
      'gain' => (maintenance * 1.15).round(),
      _ => maintenance,
    };
    return Profile(
      goal: goal,
      dailyKcalTarget: target,
      proteinTargetG: (target * 0.27 / 4).round(),
      carbsTargetG: (target * 0.42 / 4).round(),
      fatTargetG: (target * 0.31 / 9).round(),
      waterTargetGlasses: 8,
      fastingWindowHours: 16,
    );
  }

  static final todaySummary = TodaySummary(
    kcalTarget: 2100,
    kcalConsumed: 1240,
    kcalRemaining: 860,
    proteinTargetG: 140,
    proteinConsumedG: 82,
    carbsTargetG: 220,
    carbsConsumedG: 120,
    waterGlasses: 5,
    waterTarget: 8,
    meals: [
      Meal(
        mealType: 'breakfast',
        loggedAt: DateTime.now(),
        items: [FoodItem(name: 'Café con leche', kcal: 90), FoodItem(name: 'Medialuna', kcal: 290)],
      ),
      Meal(
        mealType: 'lunch',
        loggedAt: DateTime.now(),
        items: [FoodItem(name: 'Milanesa + puré', kcal: 590), FoodItem(name: 'Ensalada', kcal: 20)],
      ),
    ],
  );

  static final diaryMeals = [
    Meal(
      mealType: 'breakfast',
      loggedAt: DateTime.now(),
      items: [FoodItem(name: 'Café con leche', kcal: 90), FoodItem(name: 'Medialuna', kcal: 290)],
    ),
    Meal(
      mealType: 'lunch',
      loggedAt: DateTime.now(),
      items: [FoodItem(name: 'Milanesa de pollo', kcal: 410), FoodItem(name: 'Puré de papas', kcal: 180), FoodItem(name: 'Ensalada mixta', kcal: 60)],
    ),
    Meal(mealType: 'snack', loggedAt: DateTime.now(), items: const []),
    Meal(mealType: 'dinner', loggedAt: DateTime.now(), items: const []),
  ];

  static final recipes = [
    SavedRecipe(name: 'Bowl proteico', kcal: 420),
    SavedRecipe(name: 'Tarta de verdura', kcal: 310),
    SavedRecipe(name: 'Batido post-gym', kcal: 260),
  ];

  static final frequentItems = [
    SavedRecipe(name: 'Café con leche', kcal: 90),
    SavedRecipe(name: 'Tostado jamón y queso', kcal: 340),
    SavedRecipe(name: 'Manzana', kcal: 80),
  ];

  static final micronutrients = Micronutrients(
    fiberG: 18,
    ironMg: 9,
    calciumMg: 720,
    vitaminCMg: 70,
    vitaminDUg: 3,
    sodiumMg: 2400,
  );

  static final coachStats = CoachStats(avgKcal: 1980, adherencePct: 71, streakDays: 4, loggedDays: 6);

  static final coachInsightsList = [
    CoachInsight(
      kind: 'suggestion',
      text: 'Te faltó fibra casi todos los días esta semana. Sumar legumbres 2-3 veces por semana lo resuelve fácil.',
      actionLabel: 'Ver recetas con legumbres',
    ),
    CoachInsight(
      kind: 'achievement',
      text: 'Superaste tu objetivo de proteína 5 días seguidos — tu mejor racha del mes.',
    ),
    CoachInsight(
      kind: 'pattern',
      text: 'Los domingos tendés a superar tu objetivo calórico en un 30%. ¿Planificamos algo liviano para la noche?',
      actionLabel: 'Ajustar plan del domingo',
    ),
  ];

  static CoachResponse coachInsights() => CoachResponse(insights: coachInsightsList, stats: coachStats);

  static FastingState fastingState() => FastingState(
        active: FastingSession(startedAt: DateTime.now().subtract(const Duration(hours: 14, minutes: 22)), targetHours: 16),
        history: [
          for (final done in [true, true, true, false, true, true, true])
            FastingSession(
              startedAt: DateTime.now().subtract(const Duration(days: 1)),
              endedAt: done ? DateTime.now() : null,
              targetHours: 16,
            ),
        ],
      );

  static final weightHistory = [
    {'date': '2026-07-15', 'weight_kg': 78.4},
    {'date': '2026-07-22', 'weight_kg': 77.9},
    {'date': '2026-07-29', 'weight_kg': 77.3},
    {'date': '2026-08-05', 'weight_kg': 76.8},
    {'date': '2026-08-11', 'weight_kg': 76.0},
  ];

  static final scanResult = FoodScanResult(
    items: [
      FoodItem(name: 'Milanesa de pollo', grams: 220, kcal: 410, proteinG: 38, carbsG: 12, fatG: 22, confidence: 0.97),
      FoodItem(name: 'Puré de papas', grams: 150, kcal: 180, proteinG: 3, carbsG: 34, fatG: 4, confidence: 0.93),
      FoodItem(name: 'Ensalada mixta', grams: 80, kcal: 60, proteinG: 1, carbsG: 6, fatG: 3, confidence: 0.9),
    ],
    qualityScore: 'B+',
    qualityNote: 'Plato balanceado, alto en proteína.',
  );
}
