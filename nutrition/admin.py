from django.contrib import admin

from .models import (
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

admin.site.register(Profile)
admin.site.register(Meal)
admin.site.register(FoodItem)
admin.site.register(SavedRecipe)
admin.site.register(WaterLog)
admin.site.register(WeightLog)
admin.site.register(FastingSession)
admin.site.register(CoachInsight)


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ["user", "status", "current_period_end", "mp_payment_id"]
    list_filter = ["status"]
    search_fields = ["user__username", "user__email", "mp_payment_id"]


@admin.register(NutritionPlan)
class NutritionPlanAdmin(admin.ModelAdmin):
    """Acá es donde el profesional (o vos en su nombre) carga el plan a medida
    de cada usuario Premium."""

    list_display = ["user", "professional_name", "summary", "is_active", "created_at"]
    list_filter = ["is_active"]
    search_fields = ["user__username", "user__email", "professional_name"]
