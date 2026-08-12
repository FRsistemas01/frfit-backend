from rest_framework import serializers

from .models import (
    ChatMessage,
    CoachInsight,
    FastingSession,
    FoodItem,
    Meal,
    NutritionPlan,
    Profile,
    SavedRecipe,
    Subscription,
    WaterLog,
    WeightLog,
)


class ProfileSerializer(serializers.ModelSerializer):
    is_premium = serializers.ReadOnlyField()

    class Meta:
        model = Profile
        fields = [
            "goal",
            "sex",
            "age",
            "height_cm",
            "activity_level",
            "daily_kcal_target",
            "protein_target_g",
            "carbs_target_g",
            "fat_target_g",
            "water_target_glasses",
            "fasting_window_hours",
            "current_weight_kg",
            "target_weight_kg",
            "is_premium",
        ]


class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = [
            "id",
            "name",
            "grams",
            "kcal",
            "protein_g",
            "carbs_g",
            "fat_g",
            "fiber_g",
            "iron_mg",
            "calcium_mg",
            "vitamin_c_mg",
            "vitamin_d_ug",
            "sodium_mg",
            "detection_confidence",
        ]


class MealSerializer(serializers.ModelSerializer):
    items = FoodItemSerializer(many=True, read_only=True)
    total_kcal = serializers.ReadOnlyField()

    class Meta:
        model = Meal
        fields = [
            "id",
            "meal_type",
            "source",
            "logged_at",
            "photo",
            "ai_confidence",
            "quality_score",
            "items",
            "total_kcal",
        ]


class SavedRecipeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedRecipe
        fields = ["id", "name", "meal_type", "instructions", "ingredients", "kcal", "protein_g", "carbs_g", "fat_g", "created_at"]

    def create(self, validated_data):
        recipe = SavedRecipe(**validated_data)
        # Si viene una lista de ingredientes (receta generada con IA), esos
        # totales mandan. Si no (alta rápida de un solo ítem), se respetan
        # los kcal/macros que mandó el cliente tal cual.
        if recipe.ingredients:
            recipe.recompute_totals()
        recipe.save()
        return recipe


class WaterLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WaterLog
        fields = ["date", "glasses"]


class WeightLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeightLog
        fields = ["date", "weight_kg"]


class FastingSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = FastingSession
        fields = ["id", "started_at", "ended_at", "target_hours"]


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ["id", "role", "content", "meal_plan", "created_at"]


class CoachInsightSerializer(serializers.ModelSerializer):
    class Meta:
        model = CoachInsight
        fields = ["id", "kind", "text", "action_label", "created_at", "dismissed"]


class SubscriptionSerializer(serializers.ModelSerializer):
    is_active = serializers.ReadOnlyField()

    class Meta:
        model = Subscription
        fields = ["status", "is_active", "current_period_end"]


class NutritionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = NutritionPlan
        fields = ["id", "professional_name", "summary", "content", "created_at"]
