from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


class Profile(models.Model):
    GOAL_CHOICES = [
        ("lose", "Bajar de peso"),
        ("maintain", "Mantener mi peso"),
        ("gain", "Ganar masa muscular"),
    ]
    SEX_CHOICES = [("m", "Masculino"), ("f", "Femenino")]
    ACTIVITY_CHOICES = [
        ("sedentary", "Sedentario (poco o nada de ejercicio)"),
        ("light", "Actividad leve (1-3 días/semana)"),
        ("moderate", "Actividad moderada (3-5 días/semana)"),
        ("active", "Activo (6-7 días/semana)"),
        ("very_active", "Muy activo (entrenamiento intenso diario)"),
    ]
    ACTIVITY_MULTIPLIERS = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9,
    }

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    goal = models.CharField(max_length=16, choices=GOAL_CHOICES, default="maintain")
    sex = models.CharField(max_length=1, choices=SEX_CHOICES, default="m")
    age = models.PositiveIntegerField(default=30, validators=[MinValueValidator(1)])
    height_cm = models.PositiveIntegerField(default=170, validators=[MinValueValidator(1)])
    activity_level = models.CharField(max_length=16, choices=ACTIVITY_CHOICES, default="moderate")
    daily_kcal_target = models.PositiveIntegerField(default=2000)
    protein_target_g = models.PositiveIntegerField(default=140)
    carbs_target_g = models.PositiveIntegerField(default=220)
    fat_target_g = models.PositiveIntegerField(default=70)
    water_target_glasses = models.PositiveIntegerField(default=8)
    fasting_window_hours = models.PositiveIntegerField(default=16)
    daily_steps_goal = models.PositiveIntegerField(default=8000, validators=[MinValueValidator(1000)])
    current_weight_kg = models.FloatField(null=True, blank=True, validators=[MinValueValidator(1)])
    target_weight_kg = models.FloatField(null=True, blank=True, validators=[MinValueValidator(1)])
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Perfil de {self.user.username}"

    def compute_tdee(self):
        """Mifflin-St Jeor: gasto calórico total estimado a partir de peso/altura/edad/sexo/actividad."""
        if not self.current_weight_kg:
            return None
        bmr = 10 * self.current_weight_kg + 6.25 * self.height_cm - 5 * self.age
        bmr += 5 if self.sex == "m" else -161
        multiplier = self.ACTIVITY_MULTIPLIERS.get(self.activity_level, 1.55)
        return round(bmr * multiplier)

    @property
    def is_premium(self):
        sub = getattr(self.user, "subscription", None)
        return bool(sub and sub.is_active)


class Meal(models.Model):
    MEAL_TYPES = [
        ("breakfast", "Desayuno"),
        ("lunch", "Almuerzo"),
        ("snack", "Merienda"),
        ("dinner", "Cena"),
    ]
    SOURCE_CHOICES = [
        ("photo_ai", "Foto con IA"),
        ("barcode", "Código de barras"),
        ("search", "Búsqueda"),
        ("voice", "Voz"),
        ("saved_recipe", "Receta guardada"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="meals")
    meal_type = models.CharField(max_length=16, choices=MEAL_TYPES)
    source = models.CharField(max_length=16, choices=SOURCE_CHOICES, default="search")
    logged_at = models.DateTimeField()
    photo = models.ImageField(upload_to="meal_photos/", null=True, blank=True)
    ai_confidence = models.FloatField(null=True, blank=True)
    quality_score = models.CharField(max_length=4, blank=True)

    class Meta:
        ordering = ["-logged_at"]

    def __str__(self):
        return f"{self.get_meal_type_display()} · {self.user.username} · {self.logged_at:%Y-%m-%d %H:%M}"

    @property
    def total_kcal(self):
        return sum(item.kcal for item in self.items.all())


class FoodItem(models.Model):
    meal = models.ForeignKey(Meal, on_delete=models.CASCADE, related_name="items")
    name = models.CharField(max_length=120)
    grams = models.FloatField(null=True, blank=True, validators=[MinValueValidator(0)])
    kcal = models.PositiveIntegerField()
    protein_g = models.FloatField(default=0, validators=[MinValueValidator(0)])
    carbs_g = models.FloatField(default=0, validators=[MinValueValidator(0)])
    fat_g = models.FloatField(default=0, validators=[MinValueValidator(0)])
    fiber_g = models.FloatField(default=0, validators=[MinValueValidator(0)])
    iron_mg = models.FloatField(default=0, validators=[MinValueValidator(0)])
    calcium_mg = models.FloatField(default=0, validators=[MinValueValidator(0)])
    vitamin_c_mg = models.FloatField(default=0, validators=[MinValueValidator(0)])
    vitamin_d_ug = models.FloatField(default=0, validators=[MinValueValidator(0)])
    sodium_mg = models.FloatField(default=0, validators=[MinValueValidator(0)])
    detection_confidence = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"{self.name} ({self.kcal} kcal)"


class SavedRecipe(models.Model):
    MEAL_TYPES = [
        ("breakfast", "Desayuno"),
        ("lunch", "Almuerzo"),
        ("snack", "Merienda"),
        ("dinner", "Cena"),
        ("any", "Cualquier momento"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="recipes")
    name = models.CharField(max_length=120)
    meal_type = models.CharField(max_length=16, choices=MEAL_TYPES, default="any")
    instructions = models.TextField(blank=True)
    # Lista de ingredientes: [{"name","grams","kcal","protein_g","carbs_g","fat_g"}, ...]
    ingredients = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # Totales cacheados (se calculan a partir de ingredients al guardar).
    kcal = models.PositiveIntegerField(default=0)
    protein_g = models.FloatField(default=0)
    carbs_g = models.FloatField(default=0)
    fat_g = models.FloatField(default=0)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.name

    def recompute_totals(self):
        self.kcal = sum(i.get("kcal", 0) for i in self.ingredients)
        self.protein_g = sum(i.get("protein_g", 0) for i in self.ingredients)
        self.carbs_g = sum(i.get("carbs_g", 0) for i in self.ingredients)
        self.fat_g = sum(i.get("fat_g", 0) for i in self.ingredients)


class WaterLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="water_logs")
    date = models.DateField()
    glasses = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ["user", "date"]


class WeightLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="weight_logs")
    date = models.DateField()
    weight_kg = models.FloatField(validators=[MinValueValidator(1)])

    class Meta:
        ordering = ["date"]
        unique_together = ["user", "date"]


class FastingSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="fasting_sessions")
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)
    target_hours = models.PositiveIntegerField(default=16)

    class Meta:
        ordering = ["-started_at"]


class ChatMessage(models.Model):
    ROLE_CHOICES = [("user", "Usuario"), ("assistant", "Asistente")]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="chat_messages")
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    content = models.TextField()
    meal_plan = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.role}: {self.content[:40]}"


class CoachInsight(models.Model):
    KIND_CHOICES = [
        ("pattern", "Patrón detectado"),
        ("achievement", "Logro"),
        ("suggestion", "Sugerencia"),
        ("weekly_summary", "Resumen semanal"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="insights")
    kind = models.CharField(max_length=20, choices=KIND_CHOICES)
    text = models.TextField()
    action_label = models.CharField(max_length=80, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    dismissed = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]


class Subscription(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pendiente de pago"),
        ("active", "Activa"),
        ("cancelled", "Cancelada"),
        ("expired", "Vencida"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="subscription")
    status = models.CharField(max_length=12, choices=STATUS_CHOICES, default="pending")
    current_period_end = models.DateTimeField(null=True, blank=True)
    # unique=True + null=True: si Mercado Pago reintenta el mismo webhook (pasa
    # seguido), el segundo intento choca contra este constraint en vez de
    # activar la suscripción dos veces — mismo bug que ya hubo una vez en
    # FRfit-Web por no tener esta protección desde el arranque.
    mp_payment_id = models.CharField(max_length=64, blank=True, null=True, unique=True)
    mp_preference_id = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} · {self.get_status_display()}"

    @property
    def is_active(self):
        return (
            self.status == "active"
            and self.current_period_end is not None
            and self.current_period_end > timezone.now()
        )


class NutritionPlan(models.Model):
    """Plan de comidas armado a mano por el profesional de nutrición
    contactado — se carga desde el admin de Django y se muestra en la app
    solo a usuarios Premium. No se genera con IA."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="nutrition_plans")
    professional_name = models.CharField(max_length=120, blank=True)
    summary = models.CharField(max_length=200, blank=True)
    content = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Plan de {self.user.username} · {self.created_at:%Y-%m-%d}"
