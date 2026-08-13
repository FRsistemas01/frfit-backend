from datetime import date, timedelta

from django.conf import settings
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.db.models import Avg, Count
from django.shortcuts import render
from django.urls import reverse
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from . import ai_service
from .models import (
    ChatMessage,
    CoachInsight,
    FastingSession,
    FoodItem,
    Meal,
    NutritionPlan,
    Profile,
    SavedRecipe,
    WaterLog,
    WeightLog,
)
from .serializers import (
    ChatMessageSerializer,
    CoachInsightSerializer,
    FastingSessionSerializer,
    FoodItemSerializer,
    MealSerializer,
    NutritionPlanSerializer,
    ProfileSerializer,
    SavedRecipeSerializer,
    SubscriptionSerializer,
    WaterLogSerializer,
    WeightLogSerializer,
)


def _premium_required_response(reason):
    """402: el cliente sabe que es un paywall, no un error real — puede
    mostrar la pantalla de Premium en vez de un mensaje de error genérico."""
    return Response({"detail": reason, "premium_required": True}, status=402)

GOAL_KCAL_FORMULA = {
    "lose": lambda tdee: round(tdee * 0.8),
    "maintain": lambda tdee: tdee,
    "gain": lambda tdee: round(tdee * 1.15),
}


@api_view(["POST"])
@permission_classes([AllowAny])
def register(request):
    username = request.data.get("username")
    password = request.data.get("password")
    email = (request.data.get("email") or "").strip()
    if not username or not password:
        return Response({"detail": "Usuario y contraseña son requeridos."}, status=400)
    if User.objects.filter(username=username).exists():
        return Response({"detail": "Ese usuario ya existe."}, status=400)
    if email and User.objects.filter(email=email).exists():
        return Response({"detail": "Ya hay una cuenta con ese email."}, status=400)

    try:
        validate_password(password, user=User(username=username))
    except DjangoValidationError as exc:
        return Response({"detail": " ".join(exc.messages)}, status=400)

    user = User.objects.create_user(username=username, password=password, email=email)
    Profile.objects.create(user=user)
    token, _ = Token.objects.get_or_create(user=user)
    return Response({"token": token.key, "user_id": user.id}, status=201)


@api_view(["POST"])
@permission_classes([AllowAny])
def password_reset_request(request):
    """Pide el email y, si existe una cuenta con ese email, manda el link de
    reseteo. Devuelve el mismo mensaje genérico exista o no la cuenta, para no
    filtrar qué emails están registrados."""
    email = (request.data.get("email") or "").strip()
    generic_response = Response({"detail": "Si existe una cuenta con ese email, te mandamos un link para recuperarla."})
    if not email:
        return Response({"detail": "Falta el email."}, status=400)

    user = User.objects.filter(email=email).first()
    if not user:
        return generic_response

    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    reset_path = reverse("password-reset-confirm", kwargs={"uidb64": uid, "token": token})
    reset_url = request.build_absolute_uri(reset_path)

    send_mail(
        subject="Recuperar tu contraseña de FRfit",
        message=f"Entrá a este link para elegir una contraseña nueva:\n\n{reset_url}\n\nSi no pediste esto, ignorá el mail.",
        from_email=None,
        recipient_list=[email],
        fail_silently=True,
    )
    return generic_response


def password_reset_confirm(request, uidb64, token):
    """Página web simple (no es un endpoint de la API) donde el usuario elige
    la contraseña nueva — así no hace falta manejar deep links de vuelta a la
    app Flutter para algo tan puntual."""
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        user = None

    token_valid = user is not None and default_token_generator.check_token(user, token)

    if not token_valid:
        return render(request, "nutrition/password_reset_confirm.html", {"token_valid": False})

    if request.method == "POST":
        password = request.POST.get("password", "")
        password2 = request.POST.get("password2", "")
        if password != password2:
            return render(request, "nutrition/password_reset_confirm.html", {"token_valid": True, "error": "Las contraseñas no coinciden."})
        try:
            validate_password(password, user=user)
        except DjangoValidationError as exc:
            return render(request, "nutrition/password_reset_confirm.html", {"token_valid": True, "error": " ".join(exc.messages)})
        user.set_password(password)
        user.save()
        return render(request, "nutrition/password_reset_confirm.html", {"token_valid": True, "done": True})

    return render(request, "nutrition/password_reset_confirm.html", {"token_valid": True})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def set_goal(request):
    """Onboarding: guarda peso/altura/edad/sexo/actividad y objetivo, y calcula
    el plan diario de kcal/macros real (Mifflin-St Jeor + factor de actividad)."""
    profile, _ = Profile.objects.get_or_create(user=request.user)

    profile.goal = request.data.get("goal", profile.goal)
    profile.sex = request.data.get("sex", profile.sex)
    profile.age = int(request.data.get("age", profile.age))
    profile.height_cm = int(request.data.get("height_cm", profile.height_cm))
    profile.activity_level = request.data.get("activity_level", profile.activity_level)
    weight = request.data.get("weight_kg")
    if weight is not None:
        profile.current_weight_kg = float(weight)
        WeightLog.objects.update_or_create(
            user=request.user, date=date.today(), defaults={"weight_kg": profile.current_weight_kg}
        )
    target_weight = request.data.get("target_weight_kg")
    if target_weight is not None:
        profile.target_weight_kg = float(target_weight) if target_weight != "" else None

    tdee = profile.compute_tdee() or 2100
    target = GOAL_KCAL_FORMULA.get(profile.goal, GOAL_KCAL_FORMULA["maintain"])(tdee)
    profile.daily_kcal_target = target
    profile.protein_target_g = round(target * 0.27 / 4)
    profile.carbs_target_g = round(target * 0.42 / 4)
    profile.fat_target_g = round(target * 0.31 / 9)
    profile.save()

    return Response(ProfileSerializer(profile).data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def profile_view(request):
    profile, _ = Profile.objects.get_or_create(user=request.user)
    data = ProfileSerializer(profile).data
    data["username"] = request.user.username
    return Response(data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def today_summary(request):
    """Resumen del día: consumido vs. objetivo, agua, comidas."""
    profile, _ = Profile.objects.get_or_create(user=request.user)
    today = date.today()
    meals = Meal.objects.filter(user=request.user, logged_at__date=today)

    consumed_kcal = sum(m.total_kcal for m in meals)
    consumed_protein = sum(i.protein_g for m in meals for i in m.items.all())
    consumed_carbs = sum(i.carbs_g for m in meals for i in m.items.all())

    water, _ = WaterLog.objects.get_or_create(user=request.user, date=today, defaults={"glasses": 0})

    # Racha real: días consecutivos (hasta hoy) con al menos una comida registrada.
    logged_dates = {
        timezone.localtime(m.logged_at).date()
        for m in Meal.objects.filter(user=request.user, logged_at__date__gte=today - timedelta(days=60))
    }
    streak = 0
    cursor = today
    while cursor in logged_dates:
        streak += 1
        cursor -= timedelta(days=1)

    return Response(
        {
            "kcal_target": profile.daily_kcal_target,
            "kcal_consumed": consumed_kcal,
            # Puede ser negativo si ya se superó el objetivo — el frontend decide cómo mostrarlo,
            # no lo escondemos acá (antes se clampeaba a 0 y parecía que faltaba comida por sumar).
            "kcal_remaining": profile.daily_kcal_target - consumed_kcal,
            "protein_target_g": profile.protein_target_g,
            "protein_consumed_g": round(consumed_protein, 1),
            "carbs_target_g": profile.carbs_target_g,
            "carbs_consumed_g": round(consumed_carbs, 1),
            "water_glasses": water.glasses,
            "water_target": profile.water_target_glasses,
            "streak_days": streak,
            "meals": MealSerializer(meals, many=True, context={"request": request}).data,
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def weekly_trend(request):
    """Kcal consumidas por día en los últimos 7 días, para el gráfico de tendencia de Hoy."""
    profile, _ = Profile.objects.get_or_create(user=request.user)
    today = date.today()
    since = today - timedelta(days=6)
    meals = Meal.objects.filter(user=request.user, logged_at__date__gte=since)

    by_day = {}
    for m in meals:
        d = timezone.localtime(m.logged_at).date()
        by_day[d] = by_day.get(d, 0) + m.total_kcal

    days = [since + timedelta(days=i) for i in range(7)]
    return Response(
        {
            "target": profile.daily_kcal_target,
            "days": [{"date": str(d), "kcal": by_day.get(d, 0)} for d in days],
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def progress_overview(request):
    """Todo lo que necesita la pantalla de Progreso: peso, calendario de
    adherencia de los últimos 30 días, y estadísticas resumen."""
    profile, _ = Profile.objects.get_or_create(user=request.user)
    today = date.today()
    since_30 = today - timedelta(days=29)

    meals = Meal.objects.filter(user=request.user, logged_at__date__gte=since_30)
    by_day = {}
    for m in meals:
        d = timezone.localtime(m.logged_at).date()
        by_day[d] = by_day.get(d, 0) + m.total_kcal

    target = profile.daily_kcal_target or 1
    calendar = []
    for i in range(30):
        d = since_30 + timedelta(days=i)
        kcal = by_day.get(d)
        status = "future" if d > today else "empty" if kcal is None else "on_track" if 0.85 * target <= kcal <= 1.15 * target else "off_track"
        calendar.append({"date": str(d), "kcal": kcal or 0, "status": status})

    logged_days = len(by_day)
    on_track_days = sum(1 for d, k in by_day.items() if 0.85 * target <= k <= 1.15 * target)

    weights = list(WeightLog.objects.filter(user=request.user, date__gte=today - timedelta(days=90)).order_by("date"))
    weight_change = None
    if len(weights) >= 2:
        weight_change = round(weights[-1].weight_kg - weights[0].weight_kg, 1)

    streak = 0
    cursor = today
    while cursor in by_day:
        streak += 1
        cursor -= timedelta(days=1)

    # Proyección lineal simple: kg por día en base al primer y último peso
    # registrado en la ventana de 90 días, extrapolado hasta el objetivo.
    projected_date = None
    kg_per_week = None
    if len(weights) >= 2 and profile.target_weight_kg:
        span_days = (weights[-1].date - weights[0].date).days
        total_change = weights[-1].weight_kg - weights[0].weight_kg
        if span_days > 0 and total_change != 0:
            rate_per_day = total_change / span_days
            remaining = profile.target_weight_kg - weights[-1].weight_kg
            # Solo proyectamos si la tendencia va en la dirección correcta hacia el objetivo.
            if (rate_per_day < 0 and remaining < 0) or (rate_per_day > 0 and remaining > 0):
                days_left = remaining / rate_per_day
                projected_date = str(today + timedelta(days=round(days_left)))
                kg_per_week = round(rate_per_day * 7, 2)

    total_meals_logged = Meal.objects.filter(user=request.user).count()
    badges = [
        {"id": "streak_3", "label": "3 días seguidos", "icon": "🔥", "achieved": streak >= 3},
        {"id": "streak_7", "label": "Una semana seguida", "icon": "⚡", "achieved": streak >= 7},
        {"id": "streak_30", "label": "Un mes seguido", "icon": "🏆", "achieved": streak >= 30},
        {"id": "weight_1", "label": "Primer -1kg", "icon": "📉", "achieved": (weight_change or 0) <= -1},
        {"id": "weight_5", "label": "-5kg recorridos", "icon": "🎯", "achieved": (weight_change or 0) <= -5},
        {"id": "meals_50", "label": "50 comidas cargadas", "icon": "🍽️", "achieved": total_meals_logged >= 50},
        {"id": "adherence", "label": "80% en objetivo", "icon": "✅", "achieved": (round((on_track_days / logged_days) * 100) if logged_days else 0) >= 80},
    ]

    return Response(
        {
            "streak_days": streak,
            "logged_days_30": logged_days,
            "on_track_days_30": on_track_days,
            "adherence_pct_30": round((on_track_days / logged_days) * 100) if logged_days else 0,
            "avg_kcal_30": round(sum(by_day.values()) / logged_days) if logged_days else 0,
            "weight_change_90d": weight_change,
            "current_weight_kg": profile.current_weight_kg,
            "target_weight_kg": profile.target_weight_kg,
            "projected_date": projected_date,
            "kg_per_week": kg_per_week,
            "calendar": calendar,
            "weights": WeightLogSerializer(weights, many=True).data,
            "badges": badges,
        }
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def diary(request):
    if request.method == "GET":
        day = request.query_params.get("date", str(date.today()))
        meals = Meal.objects.filter(user=request.user, logged_at__date=day)
        return Response(MealSerializer(meals, many=True, context={"request": request}).data)

    serializer = MealSerializer(data=request.data, context={"request": request})
    serializer.is_valid(raise_exception=True)

    # Se validan los items antes de crear nada — así un item inválido (ej.
    # gramos negativos) no deja una comida vacía huérfana en la base.
    item_serializers = [FoodItemSerializer(data=item) for item in request.data.get("items", [])]
    for item_serializer in item_serializers:
        item_serializer.is_valid(raise_exception=True)

    meal = serializer.save(user=request.user)
    for item_serializer in item_serializers:
        item_serializer.save(meal=meal)
    return Response(MealSerializer(meal, context={"request": request}).data, status=201)


@api_view(["PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def food_item_detail(request, item_id):
    item = FoodItem.objects.filter(id=item_id, meal__user=request.user).first()
    if not item:
        return Response({"detail": "No encontrado."}, status=404)

    if request.method == "DELETE":
        meal = item.meal
        item.delete()
        if not meal.items.exists():
            meal.delete()
        return Response(status=204)

    serializer = FoodItemSerializer(item, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def scan_photo(request):
    """Recibe una foto de un plato, la analiza con IA y devuelve el desglose de alimentos."""
    photo = request.FILES.get("photo")
    if not photo:
        return Response({"detail": "Falta el archivo 'photo'."}, status=400)

    profile, _ = Profile.objects.get_or_create(user=request.user)
    if not profile.is_premium:
        today = date.today()
        used_today = Meal.objects.filter(user=request.user, source="photo_ai", logged_at__date=today).count()
        if used_today >= settings.SCAN_PHOTO_FREE_DAILY_LIMIT:
            return _premium_required_response(
                f"Llegaste al límite de {settings.SCAN_PHOTO_FREE_DAILY_LIMIT} fotos con IA por día del plan free."
            )

    try:
        result = ai_service.analyze_food_photo(photo.read(), media_type=photo.content_type or "image/jpeg")
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001 — se expone el error de IA tal cual para debug
        return Response({"detail": f"No se pudo analizar la foto: {exc}"}, status=502)

    return Response(result)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def micronutrients(request):
    today = date.today()
    items = FoodItem.objects.filter(meal__user=request.user, meal__logged_at__date=today)
    totals = {
        "fiber_g": sum(i.fiber_g for i in items),
        "iron_mg": sum(i.iron_mg for i in items),
        "calcium_mg": sum(i.calcium_mg for i in items),
        "vitamin_c_mg": sum(i.vitamin_c_mg for i in items),
        "vitamin_d_ug": sum(i.vitamin_d_ug for i in items),
        "sodium_mg": sum(i.sodium_mg for i in items),
    }
    return Response(totals)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def food_lookup(request):
    """Estima kcal/macros de un alimento por nombre + gramos usando IA, para no
    tener que cargarlos a mano al agregar una comida."""
    name = (request.data.get("name") or "").strip()
    grams = request.data.get("grams", 100)
    if not name:
        return Response({"detail": "Falta el nombre del alimento."}, status=400)

    try:
        result = ai_service.estimate_food_nutrition(name, grams)
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001
        return Response({"detail": f"No se pudo estimar: {exc}"}, status=502)

    return Response(result)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def frequent_foods(request):
    """Alimentos más repetidos en el historial real del usuario, con sus
    promedios — reemplaza cualquier lista fija de 'frecuentes'."""
    items = (
        FoodItem.objects.filter(meal__user=request.user)
        .values("name")
        .annotate(
            count=Count("id"),
            avg_kcal=Avg("kcal"),
            avg_grams=Avg("grams"),
            avg_protein=Avg("protein_g"),
            avg_carbs=Avg("carbs_g"),
            avg_fat=Avg("fat_g"),
        )
        .order_by("-count")[:8]
    )
    return Response(list(items))


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def recipes(request):
    if request.method == "GET":
        return Response(SavedRecipeSerializer(request.user.recipes.all(), many=True).data)

    profile, _ = Profile.objects.get_or_create(user=request.user)
    if not profile.is_premium and request.user.recipes.count() >= settings.RECIPES_FREE_LIMIT:
        return _premium_required_response(
            f"El plan free guarda hasta {settings.RECIPES_FREE_LIMIT} recetas. Borrá alguna o pasate a Premium."
        )

    serializer = SavedRecipeSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save(user=request.user)
    return Response(serializer.data, status=201)


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def delete_recipe(request, recipe_id):
    recipe = SavedRecipe.objects.filter(id=recipe_id, user=request.user).first()
    if not recipe:
        return Response({"detail": "No encontrada."}, status=404)
    recipe.delete()
    return Response(status=204)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def generate_recipe(request):
    """Genera un borrador de receta real (ingredientes + preparación) con IA, sin guardarla todavía."""
    prompt = (request.data.get("prompt") or "").strip()
    if not prompt:
        return Response({"detail": "Falta describir qué receta querés."}, status=400)

    profile, _ = Profile.objects.get_or_create(user=request.user)
    try:
        result = ai_service.generate_recipe(prompt, ProfileSerializer(profile).data)
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001
        return Response({"detail": f"No se pudo generar la receta: {exc}"}, status=502)

    return Response(result)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def parse_meal_text(request):
    """Convierte una descripción libre (texto o dictado por voz vía teclado) en ítems de comida."""
    text = (request.data.get("text") or "").strip()
    if not text:
        return Response({"detail": "Falta la descripción."}, status=400)

    try:
        result = ai_service.parse_meal_text(text)
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001
        return Response({"detail": f"No se pudo interpretar: {exc}"}, status=502)

    return Response(result)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def barcode_lookup(request, code):
    """Busca un producto por código de barras en OpenFoodFacts (gratis, sin API key)."""
    import json as _json
    import urllib.error
    import urllib.request

    url = f"https://world.openfoodfacts.org/api/v2/product/{code}.json"
    try:
        with urllib.request.urlopen(url, timeout=8) as resp:
            data = _json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return Response({"detail": "Producto no encontrado."}, status=404)
        return Response({"detail": "No se pudo consultar la base de productos."}, status=502)
    except (urllib.error.URLError, TimeoutError):
        return Response({"detail": "No se pudo consultar la base de productos."}, status=502)

    if data.get("status") != 1:
        return Response({"detail": "Producto no encontrado."}, status=404)

    product = data["product"]
    nutriments = product.get("nutriments", {})
    return Response(
        {
            "name": product.get("product_name") or product.get("generic_name") or "Producto sin nombre",
            "brand": product.get("brands", ""),
            "grams": 100,
            "kcal": round(nutriments.get("energy-kcal_100g", 0) or 0),
            "protein_g": nutriments.get("proteins_100g", 0) or 0,
            "carbs_g": nutriments.get("carbohydrates_100g", 0) or 0,
            "fat_g": nutriments.get("fat_100g", 0) or 0,
            "fiber_g": nutriments.get("fiber_100g", 0) or 0,
            "sodium_mg": (nutriments.get("sodium_100g", 0) or 0) * 1000,
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def log_water(request):
    today = date.today()
    glasses = int(request.data.get("glasses", 1))
    water, _ = WaterLog.objects.get_or_create(user=request.user, date=today)
    water.glasses = glasses
    water.save()
    return Response(WaterLogSerializer(water).data)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def weight(request):
    if request.method == "GET":
        since = date.today() - timedelta(days=90)
        logs = WeightLog.objects.filter(user=request.user, date__gte=since)
        return Response(WeightLogSerializer(logs, many=True).data)

    serializer = WeightLogSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    # update_or_create: ya puede existir un registro para ese día (ej. el que
    # crea el onboarding/perfil al guardar peso) — un segundo alta el mismo día
    # actualiza el valor en vez de romper la restricción única user+date.
    log, _ = WeightLog.objects.update_or_create(
        user=request.user,
        date=serializer.validated_data["date"],
        defaults={"weight_kg": serializer.validated_data["weight_kg"]},
    )

    # Un peso nuevo recalcula el objetivo diario de calorías/macros automáticamente.
    profile, _ = Profile.objects.get_or_create(user=request.user)
    profile.current_weight_kg = log.weight_kg
    tdee = profile.compute_tdee()
    if tdee:
        target = GOAL_KCAL_FORMULA.get(profile.goal, GOAL_KCAL_FORMULA["maintain"])(tdee)
        profile.daily_kcal_target = target
        profile.protein_target_g = round(target * 0.27 / 4)
        profile.carbs_target_g = round(target * 0.42 / 4)
        profile.fat_target_g = round(target * 0.31 / 9)
    profile.save()

    return Response(WeightLogSerializer(log).data, status=201)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def fasting(request):
    if request.method == "GET":
        active = FastingSession.objects.filter(user=request.user, ended_at__isnull=True).first()
        history = FastingSession.objects.filter(user=request.user)[:7]
        return Response(
            {
                "active": FastingSessionSerializer(active).data if active else None,
                "history": FastingSessionSerializer(history, many=True).data,
            }
        )

    action = request.data.get("action")
    if action == "start":
        profile, _ = Profile.objects.get_or_create(user=request.user)
        session = FastingSession.objects.create(
            user=request.user,
            started_at=request.data.get("started_at"),
            target_hours=profile.fasting_window_hours,
        )
        return Response(FastingSessionSerializer(session).data, status=201)

    if action == "end":
        session = FastingSession.objects.filter(user=request.user, ended_at__isnull=True).first()
        if not session:
            return Response({"detail": "No hay un ayuno activo."}, status=404)
        session.ended_at = request.data.get("ended_at")
        session.save()
        return Response(FastingSessionSerializer(session).data)

    return Response({"detail": "action debe ser 'start' o 'end'."}, status=400)


def _coach_stats(user, profile, today, since):
    meals = Meal.objects.filter(user=user, logged_at__date__gte=since)
    by_day = {}
    for m in meals:
        d = timezone.localtime(m.logged_at).date()
        by_day[d] = by_day.get(d, 0) + m.total_kcal

    logged_days = len(by_day)
    avg_kcal = round(sum(by_day.values()) / logged_days) if logged_days else 0
    target = profile.daily_kcal_target or 1
    on_track = sum(1 for k in by_day.values() if 0.85 * target <= k <= 1.15 * target)
    adherence_pct = round((on_track / logged_days) * 100) if logged_days else 0

    streak = 0
    cursor = today
    while cursor in by_day:
        streak += 1
        cursor -= timedelta(days=1)

    return {"avg_kcal": avg_kcal, "adherence_pct": adherence_pct, "streak_days": streak, "logged_days": logged_days}


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def coach_insights(request):
    """Genera (o devuelve cacheados de hoy) los insights del coach con IA, junto
    con estadísticas rápidas de la última semana. ?refresh=true fuerza regenerar."""
    today = date.today()
    since = today - timedelta(days=14)
    profile, _ = Profile.objects.get_or_create(user=request.user)
    stats = _coach_stats(request.user, profile, today, today - timedelta(days=7))

    force_refresh = request.query_params.get("refresh") == "true"
    existing = CoachInsight.objects.filter(user=request.user, created_at__date=today, dismissed=False)
    if existing.exists() and not force_refresh:
        return Response({"insights": CoachInsightSerializer(existing, many=True).data, "stats": stats})
    if force_refresh:
        existing.update(dismissed=True)

    meals = Meal.objects.filter(user=request.user, logged_at__date__gte=since)
    history = {
        "meals": [
            {
                "date": str(timezone.localtime(m.logged_at).date()),
                "type": m.meal_type,
                "kcal": m.total_kcal,
                "fiber_g": sum(i.fiber_g for i in m.items.all()),
                "protein_g": sum(i.protein_g for i in m.items.all()),
            }
            for m in meals
        ],
        "weight_logs": [
            {"date": str(w["date"]), "weight_kg": w["weight_kg"]}
            for w in WeightLog.objects.filter(user=request.user, date__gte=since).values("date", "weight_kg")
        ],
    }

    try:
        raw_insights = ai_service.generate_coach_insights(history, ProfileSerializer(profile).data)
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001
        return Response({"detail": f"No se pudieron generar insights: {exc}"}, status=502)

    created = [
        CoachInsight.objects.create(
            user=request.user,
            kind=item.get("kind", "suggestion"),
            text=item.get("text", ""),
            action_label=item.get("action_label", ""),
        )
        for item in raw_insights
    ]
    return Response({"insights": CoachInsightSerializer(created, many=True).data, "stats": stats})


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def coach_chat(request):
    """Chat libre con el coach. GET devuelve el historial guardado; POST manda
    un mensaje nuevo y devuelve la respuesta de la IA (con plan de comidas si aplica)."""
    if request.method == "GET":
        messages = ChatMessage.objects.filter(user=request.user).order_by("created_at")[:50]
        return Response(ChatMessageSerializer(messages, many=True).data)

    message = (request.data.get("message") or "").strip()
    if not message:
        return Response({"detail": "Falta el mensaje."}, status=400)

    profile, _ = Profile.objects.get_or_create(user=request.user)
    today = date.today()
    if not profile.is_premium:
        sent_today = ChatMessage.objects.filter(user=request.user, role="user", created_at__date=today).count()
        if sent_today >= settings.COACH_CHAT_FREE_DAILY_LIMIT:
            return _premium_required_response(
                f"Llegaste al límite de {settings.COACH_CHAT_FREE_DAILY_LIMIT} mensajes por día del plan free."
            )

    ChatMessage.objects.create(user=request.user, role="user", content=message)

    history = [
        {"role": m.role, "content": m.content}
        for m in ChatMessage.objects.filter(user=request.user).order_by("-created_at")[1:13][::-1]
    ]

    todays_meals = Meal.objects.filter(user=request.user, logged_at__date=today)
    today_context = {
        "kcal_target": profile.daily_kcal_target,
        "kcal_consumed_today": sum(m.total_kcal for m in todays_meals),
        "goal": profile.goal,
    }

    try:
        result = ai_service.chat_with_coach(message, history, ProfileSerializer(profile).data, today_context)
    except RuntimeError as exc:
        return Response({"detail": str(exc)}, status=503)
    except Exception as exc:  # noqa: BLE001
        return Response({"detail": f"Hubo un error hablando con el coach: {exc}"}, status=502)

    assistant_msg = ChatMessage.objects.create(
        user=request.user, role="assistant", content=result["reply"], meal_plan=result.get("meal_plan")
    )
    return Response(ChatMessageSerializer(assistant_msg).data, status=201)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def save_meal_plan(request):
    """Guarda un plan de comidas generado por el coach como comidas reales del día."""
    meals_data = request.data.get("meals", [])
    if not meals_data:
        return Response({"detail": "El plan no tiene comidas."}, status=400)

    created_meals = []
    now = timezone.now()
    for meal_data in meals_data:
        meal = Meal.objects.create(
            user=request.user,
            meal_type=meal_data.get("meal_type", "snack"),
            source="search",
            logged_at=now,
        )
        for item in meal_data.get("items", []):
            FoodItem.objects.create(
                meal=meal,
                name=item.get("name", ""),
                grams=item.get("grams"),
                kcal=item.get("kcal", 0),
                protein_g=item.get("protein_g", 0),
                carbs_g=item.get("carbs_g", 0),
                fat_g=item.get("fat_g", 0),
            )
        created_meals.append(meal)

    return Response(MealSerializer(created_meals, many=True, context={"request": request}).data, status=201)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def premium_status(request):
    """Estado de la suscripción + cuánto le queda del free-tier hoy, para que
    la app decida cuándo mostrar la pantalla de Premium."""
    profile, _ = Profile.objects.get_or_create(user=request.user)
    sub = getattr(request.user, "subscription", None)
    today = date.today()

    if profile.is_premium:
        usage = {
            "coach_chat": {"used": None, "limit": None},
            "scan_photo": {"used": None, "limit": None},
            "recipes_saved": {"used": None, "limit": None},
        }
    else:
        usage = {
            "coach_chat": {
                "used": ChatMessage.objects.filter(user=request.user, role="user", created_at__date=today).count(),
                "limit": settings.COACH_CHAT_FREE_DAILY_LIMIT,
            },
            "scan_photo": {
                "used": Meal.objects.filter(user=request.user, source="photo_ai", logged_at__date=today).count(),
                "limit": settings.SCAN_PHOTO_FREE_DAILY_LIMIT,
            },
            "recipes_saved": {
                "used": request.user.recipes.count(),
                "limit": settings.RECIPES_FREE_LIMIT,
            },
        }

    return Response(
        {
            "is_premium": profile.is_premium,
            "subscription": SubscriptionSerializer(sub).data if sub else None,
            "usage": usage,
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def premium_plan(request):
    """Plan de nutrición armado por el profesional — exclusivo Premium."""
    profile, _ = Profile.objects.get_or_create(user=request.user)
    if not profile.is_premium:
        return _premium_required_response("El plan armado por el profesional es exclusivo de Premium.")

    plan = NutritionPlan.objects.filter(user=request.user, is_active=True).first()
    if not plan:
        return Response({"detail": "Todavía no tenés un plan armado por el profesional."}, status=404)

    return Response(NutritionPlanSerializer(plan).data)
