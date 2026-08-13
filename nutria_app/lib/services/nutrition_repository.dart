import 'dart:io';

import '../models/models.dart';
import 'api_client.dart';

/// Repositorio sobre el backend real. Todos los métodos de lectura devuelven
/// null cuando la request falla (sin internet, sesión vencida, servidor
/// caído) — la pantalla que llama es responsable de mostrar un estado de
/// error/reintentar, nunca de tratar un null como "no hay datos todavía".
/// A propósito no hay fallback a datos de ejemplo: en una app que muestra
/// comidas, calorías y análisis de fotos reales, mostrar un dato inventado
/// como si fuera real es peor que mostrar un error.
class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository instance = NutritionRepository._();

  final _api = ApiClient.instance;

  Future<Profile?> setGoal({
    required String goal,
    required double weightKg,
    required int heightCm,
    required int age,
    required String sex,
    required String activityLevel,
    double? targetWeightKg,
  }) async {
    final res = await _api.post('/onboarding/goal/', {
      'goal': goal,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age': age,
      'sex': sex,
      'activity_level': activityLevel,
      'target_weight_kg': ?targetWeightKg,
    });
    if (res == null) return null;
    return Profile.fromJson(res);
  }

  Future<ProgressOverview?> progressOverview() async {
    final res = await _api.get('/progress/');
    if (res != null) return ProgressOverview.fromJson(res);
    return null;
  }

  Future<WeeklyTrend?> weeklyTrend() async {
    final res = await _api.get('/today/weekly-trend/');
    if (res != null) return WeeklyTrend.fromJson(res);
    return null;
  }

  Future<bool> logWater(int glasses) async {
    final res = await _api.post('/water/', {'glasses': glasses});
    return res != null;
  }

  Future<Profile?> getProfile() async {
    final res = await _api.get('/profile/');
    if (res != null) return Profile.fromJson(res);
    return null;
  }

  Future<Profile?> updateStepsGoal(int steps) async {
    final res = await _api.patch('/profile/', {'daily_steps_goal': steps});
    if (res == null) return null;
    return Profile.fromJson(res);
  }

  Future<bool> updateFoodItem(
    int id, {
    required String name,
    double? grams,
    required int kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final res = await _api.patch('/diary/item/$id/', {
      'name': name,
      'grams': grams,
      'kcal': kcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    });
    return res != null;
  }

  Future<List<Map<String, dynamic>>?> weightHistory() async {
    final list = await _api.getList('/weight/');
    if (list == null) return null;
    return list.cast<Map<String, dynamic>>();
  }

  Future<bool> logWeight(double weightKg) async {
    final res = await _api.post('/weight/', {
      'date': DateTime.now().toIso8601String().split('T').first,
      'weight_kg': weightKg,
    });
    return res != null;
  }

  Future<bool> addScannedMeal({required String mealType, required List<FoodItem> items, String qualityScore = ''}) async {
    final res = await _api.post('/diary/', {
      'meal_type': mealType,
      'source': 'photo_ai',
      'logged_at': DateTime.now().toIso8601String(),
      'quality_score': qualityScore,
      'items': items
          .map(
            (i) => {
              'name': i.name,
              'grams': i.grams,
              'kcal': i.kcal,
              'protein_g': i.proteinG,
              'carbs_g': i.carbsG,
              'fat_g': i.fatG,
              'fiber_g': i.fiberG,
              'iron_mg': i.ironMg,
              'calcium_mg': i.calciumMg,
              'vitamin_c_mg': i.vitaminCMg,
              'vitamin_d_ug': i.vitaminDUg,
              'sodium_mg': i.sodiumMg,
            },
          )
          .toList(),
    });
    return res != null;
  }

  Future<bool> addManualMeal({
    required String mealType,
    required String name,
    required int kcal,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
  }) async {
    final res = await _api.post('/diary/', {
      'meal_type': mealType,
      'source': 'search',
      'logged_at': DateTime.now().toIso8601String(),
      'items': [
        {'name': name, 'kcal': kcal, 'protein_g': proteinG, 'carbs_g': carbsG, 'fat_g': fatG},
      ],
    });
    return res != null;
  }

  Future<TodaySummary?> today() async {
    final res = await _api.get('/today/');
    if (res == null) return null;
    return TodaySummary.fromJson(res);
  }

  Future<bool> deleteFoodItem(int itemId) => _api.delete('/diary/item/$itemId/');

  Future<List<Meal>?> diary(DateTime day) async {
    final list = await _api.getList(
      '/diary/',
      query: {'date': day.toIso8601String().split('T').first},
    );
    if (list == null) return null;
    return list.map((e) => Meal.fromJson(e)).toList();
  }

  Future<List<SavedRecipe>?> recipes() async {
    final list = await _api.getList('/recipes/');
    if (list == null) return null;
    return list.map((e) => SavedRecipe.fromJson(e)).toList();
  }

  Future<bool> saveRecipe({required String name, required int kcal, double proteinG = 0, double carbsG = 0, double fatG = 0}) async {
    final res = await _api.post('/recipes/', {'name': name, 'kcal': kcal, 'protein_g': proteinG, 'carbs_g': carbsG, 'fat_g': fatG});
    return res != null;
  }

  Future<SavedRecipe?> generateRecipe(String prompt) async {
    final res = await _api.post('/recipes/generate/', {'prompt': prompt});
    if (res == null) return null;
    return SavedRecipe(
      name: res['name'] ?? 'Receta',
      mealType: res['meal_type'] ?? 'any',
      instructions: res['instructions'] ?? '',
      ingredients: (res['ingredients'] as List? ?? []).map((e) => FoodItem.fromJson(e)).toList(),
      kcal: ((res['ingredients'] as List? ?? []).fold<num>(0, (sum, e) => sum + (e['kcal'] ?? 0))).toInt(),
    );
  }

  Future<SavedRecipe?> saveFullRecipe(SavedRecipe recipe) async {
    final res = await _api.post('/recipes/', recipe.toJson());
    if (res == null) return null;
    return SavedRecipe.fromJson(res);
  }

  Future<bool> deleteRecipe(int id) => _api.delete('/recipes/$id/');

  Future<bool> addRecipeToDiary(SavedRecipe recipe, {String? mealType}) {
    return addMealWithItems(mealType: mealType ?? (recipe.mealType == 'any' ? _inferMealType() : recipe.mealType), items: recipe.ingredients, source: 'saved_recipe');
  }

  Future<ParsedMeal?> parseMealText(String text) async {
    final res = await _api.post('/food/parse-text/', {'text': text});
    if (res == null) return null;
    return ParsedMeal.fromJson(res);
  }

  Future<FoodItem?> barcodeLookup(String code) async {
    final res = await _api.get('/food/barcode/$code/');
    if (res == null) return null;
    return FoodItem(
      name: res['name'] ?? 'Producto',
      grams: (res['grams'] as num?)?.toDouble() ?? 100,
      kcal: (res['kcal'] as num?)?.toInt() ?? 0,
      proteinG: (res['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (res['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (res['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (res['fiber_g'] as num?)?.toDouble() ?? 0,
      sodiumMg: (res['sodium_mg'] as num?)?.toDouble() ?? 0,
    );
  }

  String _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    if (hour < 19) return 'snack';
    return 'dinner';
  }

  Future<List<FrequentFood>> frequentFoods() async {
    final list = await _api.getList('/food/frequent/');
    if (list != null) return list.map((e) => FrequentFood.fromJson(e)).toList();
    return [];
  }

  /// Estima kcal/macros de un alimento por nombre + gramos con IA. Devuelve
  /// null si no se pudo estimar (el usuario completa a mano en ese caso).
  Future<FoodItem?> lookupFood(String name, double grams) async {
    final res = await _api.post('/food/lookup/', {'name': name, 'grams': grams});
    if (res == null) return null;
    return FoodItem(
      name: name,
      grams: grams,
      kcal: (res['kcal'] as num?)?.toInt() ?? 0,
      proteinG: (res['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (res['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (res['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (res['fiber_g'] as num?)?.toDouble() ?? 0,
      ironMg: (res['iron_mg'] as num?)?.toDouble() ?? 0,
      calciumMg: (res['calcium_mg'] as num?)?.toDouble() ?? 0,
      vitaminCMg: (res['vitamin_c_mg'] as num?)?.toDouble() ?? 0,
      vitaminDUg: (res['vitamin_d_ug'] as num?)?.toDouble() ?? 0,
      sodiumMg: (res['sodium_mg'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<bool> addMealWithItems({required String mealType, required List<FoodItem> items, String source = 'search'}) async {
    final res = await _api.post('/diary/', {
      'meal_type': mealType,
      'source': source,
      'logged_at': DateTime.now().toIso8601String(),
      'items': items
          .map((i) => {'name': i.name, 'grams': i.grams, 'kcal': i.kcal, 'protein_g': i.proteinG, 'carbs_g': i.carbsG, 'fat_g': i.fatG})
          .toList(),
    });
    return res != null;
  }

  Future<Micronutrients?> micronutrients() async {
    final res = await _api.get('/micronutrients/');
    if (res == null) return null;
    return Micronutrients.fromJson(res);
  }

  Future<CoachResponse?> coachInsights({bool refresh = false}) async {
    final res = await _api.get('/coach/insights/', query: refresh ? {'refresh': 'true'} : null);
    if (res == null) return null;
    return CoachResponse(
      insights: (res['insights'] as List? ?? []).map((e) => CoachInsight.fromJson(e)).toList(),
      stats: CoachStats.fromJson(res['stats'] ?? {}),
    );
  }

  Future<FastingState?> fastingState() async {
    final res = await _api.get('/fasting/');
    if (res == null) return null;
    return FastingState.fromJson(res);
  }

  Future<bool> startFasting() async {
    final res = await _api.post('/fasting/', {'action': 'start', 'started_at': DateTime.now().toIso8601String()});
    return res != null;
  }

  Future<bool> endFasting() async {
    final res = await _api.post('/fasting/', {'action': 'end', 'ended_at': DateTime.now().toIso8601String()});
    return res != null;
  }

  Future<List<CoachChatMessage>> chatHistory() async {
    final list = await _api.getList('/coach/chat/');
    if (list != null) return list.map((e) => CoachChatMessage.fromJson(e)).toList();
    return [];
  }

  Future<CoachChatMessage?> sendChatMessage(String message) async {
    final res = await _api.post('/coach/chat/', {'message': message});
    if (res != null) return CoachChatMessage.fromJson(res);
    return null;
  }

  Future<bool> savePlanToDiary(List<PlanMeal> meals) async {
    final res = await _api.postList('/coach/save-plan/', {'meals': meals.map((m) => m.toJson()).toList()});
    return res != null;
  }

  Future<FoodScanResult?> scanPhoto(File photo) async {
    final res = await _api.uploadPhoto('/scan-photo/', photo);
    if (res == null) return null;
    return FoodScanResult.fromJson(res);
  }

  /// Estado real de la suscripción + cuánto le queda del free-tier hoy.
  /// Devuelve null si no hay conexión (la pantalla de Premium debe manejarlo
  /// mostrando el plan sin datos de uso, no un error).
  Future<Map<String, dynamic>?> premiumStatus() => _api.get('/premium/status/');

  /// El plan armado por el profesional — 404 si Premium pero todavía no se le
  /// cargó uno, o null si no hay conexión.
  Future<Map<String, dynamic>?> premiumPlan() => _api.get('/premium/plan/');

  bool get isConnected => _api.isConnected;
}
