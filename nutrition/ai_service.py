"""Servicio de IA: reconocimiento de comida en fotos, insights del coach y
chat conversacional (incluye armado de planes de comida reales).

Usa Gemini (Google) — misma API key/modelo que ya se usa en FRfit.
Requiere GEMINI_API_KEY en el .env del backend.
"""
import json
import re

from django.conf import settings

try:
    from google import genai
    from google.genai import types as genai_types
except ImportError:  # pragma: no cover
    genai = None
    genai_types = None


def _get_client():
    if genai is None:
        raise RuntimeError("Falta instalar 'google-genai' en el entorno del backend (pip install google-genai).")
    if not settings.GEMINI_API_KEY:
        raise RuntimeError("Falta GEMINI_API_KEY en el .env del backend para habilitar el escaneo por IA y el coach.")
    return genai.Client(api_key=settings.GEMINI_API_KEY)


def _extract_json(raw_text: str) -> dict:
    text = raw_text.strip()
    if text.startswith("```"):
        text = text.strip("`")
        if text.startswith("json"):
            text = text[4:]
    return json.loads(text)


FOOD_RECOGNITION_PROMPT = """Sos un nutricionista experto analizando una foto de un plato de comida.
Identificá cada alimento visible por separado y estimá su porción y su información nutricional.

Respondé ÚNICAMENTE con JSON válido, sin texto adicional, con esta forma exacta:
{
  "items": [
    {
      "name": "nombre del alimento en español",
      "grams": <número estimado de gramos>,
      "kcal": <número entero>,
      "protein_g": <número>,
      "carbs_g": <número>,
      "fat_g": <número>,
      "fiber_g": <número>,
      "iron_mg": <número>,
      "calcium_mg": <número>,
      "vitamin_c_mg": <número>,
      "vitamin_d_ug": <número>,
      "sodium_mg": <número>,
      "confidence": <número entre 0 y 1>
    }
  ],
  "quality_score": "<una letra de A a D, con opcional + o ->",
  "quality_note": "explicación breve en una oración de por qué ese puntaje"
}
"""


def analyze_food_photo(image_bytes: bytes, media_type: str = "image/jpeg") -> dict:
    """Envía una foto de comida a Gemini y devuelve el desglose nutricional estructurado."""
    client = _get_client()

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=[
            genai_types.Part.from_bytes(data=image_bytes, mime_type=media_type),
            FOOD_RECOGNITION_PROMPT,
        ],
        config=genai_types.GenerateContentConfig(max_output_tokens=1500),
    )
    return _extract_json(response.text or "{}")


COACH_PROMPT_TEMPLATE = """Sos el coach nutricional de la app Nutria. Analizá el historial de los últimos
14 días del usuario y generá entre 2 y 4 insights proactivos, breves y accionables, en español
rioplatense, con un tono cercano pero profesional (nunca alarmista).

Historial (JSON):
{history}

Perfil y objetivo del usuario:
{profile}

Respondé ÚNICAMENTE con JSON válido, sin texto adicional, con esta forma exacta:
{{
  "insights": [
    {{
      "kind": "pattern" | "achievement" | "suggestion" | "weekly_summary",
      "text": "el insight en 1-2 oraciones, específico con números reales del historial",
      "action_label": "texto corto de un botón de acción, o cadena vacía si no aplica"
    }}
  ]
}}
"""


def generate_coach_insights(history: dict, profile: dict) -> list[dict]:
    """Genera insights proactivos a partir del historial real de comidas/agua/peso del usuario."""
    client = _get_client()
    prompt = COACH_PROMPT_TEMPLATE.format(
        history=json.dumps(history, ensure_ascii=False),
        profile=json.dumps(profile, ensure_ascii=False),
    )

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=genai_types.GenerateContentConfig(max_output_tokens=1200),
    )
    return _extract_json(response.text or "{}").get("insights", [])


FOOD_LOOKUP_PROMPT = """Sos un nutricionista experto. Estimá la información nutricional de este alimento
para la porción indicada, de la forma más realista posible.

Alimento: {name}
Cantidad: {grams}g

Respondé ÚNICAMENTE con JSON válido, sin texto adicional, con esta forma exacta:
{{"kcal": <entero>, "protein_g": <número>, "carbs_g": <número>, "fat_g": <número>, "fiber_g": <número>,
"iron_mg": <número>, "calcium_mg": <número>, "vitamin_c_mg": <número>, "vitamin_d_ug": <número>, "sodium_mg": <número>}}
"""


def estimate_food_nutrition(name: str, grams: float) -> dict:
    """Estima kcal y macros de un alimento suelto por nombre + gramos, para no
    tener que cargarlos a mano en el alta manual."""
    client = _get_client()
    prompt = FOOD_LOOKUP_PROMPT.format(name=name, grams=grams)

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=genai_types.GenerateContentConfig(max_output_tokens=400),
    )
    return _extract_json(response.text or "{}")


RECIPE_PROMPT = """Sos un chef y nutricionista. Armá UNA receta real y concreta a partir de este pedido,
pensada para que alguien la pueda cocinar de verdad en su casa.

Pedido del usuario: {prompt}

Perfil nutricional del usuario (ajustá porciones si es razonable, pero priorizá que la receta tenga sentido):
{profile}

Respondé ÚNICAMENTE con JSON válido, sin texto adicional, con esta forma exacta:
{{
  "name": "Nombre apetecible de la receta",
  "meal_type": "breakfast" | "lunch" | "snack" | "dinner" | "any",
  "ingredients": [
    {{"name": "Pechuga de pollo", "grams": 200, "kcal": 330, "protein_g": 62, "carbs_g": 0, "fat_g": 7}}
  ],
  "instructions": "Pasos de preparación numerados, en 3-6 pasos, en español rioplatense, separados por saltos de línea."
}}

Estimá kcal y macros de cada ingrediente de forma realista según su cantidad. Incluí entre 3 y 8 ingredientes.
"""


def generate_recipe(prompt: str, profile: dict) -> dict:
    """Genera una receta real (ingredientes + preparación) a partir de un pedido en lenguaje natural."""
    client = _get_client()
    full_prompt = RECIPE_PROMPT.format(prompt=prompt, profile=json.dumps(profile, ensure_ascii=False))

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=full_prompt,
        config=genai_types.GenerateContentConfig(max_output_tokens=1500),
    )
    return _extract_json(response.text or "{}")


PARSE_MEAL_PROMPT = """Un usuario describió con sus palabras (por texto o dictado por voz) lo que comió.
Extraé cada alimento por separado con su información nutricional estimada.

Descripción: "{text}"

Respondé ÚNICAMENTE con JSON válido, sin texto adicional, con esta forma exacta:
{{
  "meal_type_guess": "breakfast" | "lunch" | "snack" | "dinner",
  "items": [
    {{"name": "nombre del alimento", "grams": <número estimado>, "kcal": <entero>, "protein_g": <número>, "carbs_g": <número>, "fat_g": <número>}}
  ]
}}

Si la descripción menciona una hora o comida específica (ej. "en el desayuno"), usala para meal_type_guess;
si no, inferí por el tipo de alimentos. Separá cada alimento mencionado en su propio ítem.
"""


def parse_meal_text(text: str) -> dict:
    """Convierte una descripción libre ('comí dos huevos y una tostada con palta') en ítems estructurados."""
    client = _get_client()
    prompt = PARSE_MEAL_PROMPT.format(text=text)

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=prompt,
        config=genai_types.GenerateContentConfig(max_output_tokens=800),
    )
    return _extract_json(response.text or "{}")


CHAT_SYSTEM_PROMPT = """Sos el Coach de Nutria, una app de nutrición y conteo de calorías. Hablás en
español rioplatense (Argentina), tono cercano, directo y motivador, sin vueltas. Ayudás con dudas de
nutrición, hábitos, y sobre todo armando PLANES DE COMIDAS reales y concretos cuando el usuario los pide.

Perfil del usuario:
{profile}

Contexto nutricional de hoy:
{today_context}

Cuando el usuario pida un plan de comidas (para el día, una comida puntual, o con alguna restricción/objetivo),
respondé con una explicación breve en texto y agregá SIEMPRE al final un bloque con este formato EXACTO,
sin texto extra adentro ni comentarios:

```plan-json
{{"meals": [{{"meal_type": "breakfast", "items": [{{"name": "Avena con banana", "grams": 200, "kcal": 320, "protein_g": 10, "carbs_g": 55, "fat_g": 6}}]}}]}}
```

"meal_type" debe ser exactamente uno de: breakfast, lunch, snack, dinner. Estimá kcal y macros de forma
realista para cada ítem. Ajustá el total del plan al objetivo calórico diario del usuario si tenés esa info.
Incluí solo las comidas que el usuario pidió (si pide "el día completo", incluí breakfast/lunch/snack/dinner;
si pide "algo para la cena", incluí solo dinner).

Para preguntas sueltas que no son un pedido de plan, respondé directo en texto, sin ningún bloque JSON.
No inventes datos médicos ni reemplaces a un profesional de la salud ante consultas serias — para eso,
sugerí consultar a un nutricionista.
"""


def _extract_plan_block(text: str):
    match = re.search(r"```plan-json\s*(\{.*?\})\s*```", text, re.DOTALL)
    if not match:
        return None, text
    try:
        plan = json.loads(match.group(1))
    except json.JSONDecodeError:
        return None, text
    clean_text = (text[: match.start()] + text[match.end() :]).strip()
    return plan, clean_text or "Acá tenés tu plan 👇"


def chat_with_coach(message: str, history: list[dict], profile: dict, today_context: dict) -> dict:
    """Conversación libre con el coach. Si el usuario pide un plan de comidas,
    devuelve también la estructura del plan lista para guardar en el diario."""
    client = _get_client()

    system = CHAT_SYSTEM_PROMPT.format(
        profile=json.dumps(profile, ensure_ascii=False),
        today_context=json.dumps(today_context, ensure_ascii=False),
    )

    contents = []
    for m in history:
        role = "model" if m["role"] == "assistant" else "user"
        contents.append({"role": role, "parts": [{"text": m["content"]}]})
    contents.append({"role": "user", "parts": [{"text": message}]})

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=contents,
        config=genai_types.GenerateContentConfig(system_instruction=system, max_output_tokens=2000),
    )
    raw_text = response.text or ""
    plan, reply_text = _extract_plan_block(raw_text)

    return {"reply": reply_text, "meal_plan": plan}
