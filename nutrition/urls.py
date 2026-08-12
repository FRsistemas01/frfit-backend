from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token

from . import views

urlpatterns = [
    path("auth/register/", views.register, name="register"),
    path("auth/login/", obtain_auth_token, name="login"),
    path("profile/", views.profile_view, name="profile"),
    path("onboarding/goal/", views.set_goal, name="set-goal"),
    path("today/", views.today_summary, name="today-summary"),
    path("today/weekly-trend/", views.weekly_trend, name="weekly-trend"),
    path("progress/", views.progress_overview, name="progress-overview"),
    path("diary/", views.diary, name="diary"),
    path("diary/item/<int:item_id>/", views.food_item_detail, name="food-item-detail"),
    path("scan-photo/", views.scan_photo, name="scan-photo"),
    path("micronutrients/", views.micronutrients, name="micronutrients"),
    path("recipes/", views.recipes, name="recipes"),
    path("recipes/<int:recipe_id>/", views.delete_recipe, name="delete-recipe"),
    path("recipes/generate/", views.generate_recipe, name="generate-recipe"),
    path("food/lookup/", views.food_lookup, name="food-lookup"),
    path("food/frequent/", views.frequent_foods, name="frequent-foods"),
    path("food/parse-text/", views.parse_meal_text, name="parse-meal-text"),
    path("food/barcode/<str:code>/", views.barcode_lookup, name="barcode-lookup"),
    path("water/", views.log_water, name="log-water"),
    path("weight/", views.weight, name="weight"),
    path("fasting/", views.fasting, name="fasting"),
    path("coach/insights/", views.coach_insights, name="coach-insights"),
    path("coach/chat/", views.coach_chat, name="coach-chat"),
    path("coach/save-plan/", views.save_meal_plan, name="save-meal-plan"),
    path("premium/status/", views.premium_status, name="premium-status"),
    path("premium/plan/", views.premium_plan, name="premium-plan"),
]
