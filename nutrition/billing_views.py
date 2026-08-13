"""Cobro de Premium vía Mercado Pago (Checkout Pro). Pago único por período
— no es una suscripción con renovación automática: el usuario paga 30 o 365
días de Premium, y cuando se vencen tiene que volver a pagar."""

from datetime import timedelta

import mercadopago
from django.conf import settings
from django.db import IntegrityError
from django.shortcuts import render
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import Subscription

PLAN_DAYS = {"monthly": 30, "annual": 365}
PLAN_LABELS = {"monthly": "FRfit Premium — Mensual", "annual": "FRfit Premium — Anual"}


def _sdk():
    if not settings.MERCADOPAGO_ACCESS_TOKEN:
        return None
    return mercadopago.SDK(settings.MERCADOPAGO_ACCESS_TOKEN)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def create_preference(request):
    plan = request.data.get("plan")
    if plan not in PLAN_DAYS:
        return Response({"detail": "Plan inválido."}, status=400)

    sdk = _sdk()
    if sdk is None:
        return Response({"detail": "El cobro todavía no está configurado del lado del servidor."}, status=503)

    price = settings.PREMIUM_PRICE_MONTHLY if plan == "monthly" else settings.PREMIUM_PRICE_ANNUAL

    preference_data = {
        "items": [
            {
                "title": PLAN_LABELS[plan],
                "quantity": 1,
                "unit_price": float(price),
                "currency_id": "ARS",
            }
        ],
        # Le decimos a MP quién pagó y qué plan compró para poder activarlo
        # en el webhook, sin necesidad de otra tabla intermedia.
        "external_reference": f"{request.user.id}:{plan}",
        "back_urls": {
            "success": f"{settings.PUBLIC_BASE_URL}/api/billing/result/?status=success",
            "failure": f"{settings.PUBLIC_BASE_URL}/api/billing/result/?status=failure",
            "pending": f"{settings.PUBLIC_BASE_URL}/api/billing/result/?status=pending",
        },
        "auto_return": "approved",
        "notification_url": f"{settings.PUBLIC_BASE_URL}/api/billing/webhook/",
    }

    result = sdk.preference().create(preference_data)
    pref = result.get("response", {})
    checkout_url = pref.get("init_point") or pref.get("sandbox_init_point")
    if not checkout_url:
        return Response({"detail": "No se pudo iniciar el pago. Probá de nuevo."}, status=502)
    return Response({"checkout_url": checkout_url})


def billing_result(request):
    """Página a la que Mercado Pago redirige el navegador después del pago
    — no es parte de la API, solo le dice al usuario que vuelva a la app."""
    return render(request, "nutrition/billing_result.html", {"status": request.GET.get("status", "pending")})


@api_view(["POST"])
@permission_classes([AllowAny])
def mercadopago_webhook(request):
    """Mercado Pago pega acá cuando cambia el estado de un pago. Siempre
    devolvemos 200 salvo que Mercado Pago mismo no esté configurado — si le
    devolvemos error, reintenta sin parar."""
    sdk = _sdk()
    if sdk is None:
        return Response(status=200)

    payment_id = (request.data.get("data") or {}).get("id") or request.query_params.get("id")
    topic = request.data.get("type") or request.query_params.get("topic")
    if topic != "payment" or not payment_id:
        return Response(status=200)

    payment = sdk.payment().get(payment_id).get("response", {})
    if payment.get("status") != "approved":
        return Response(status=200)

    external_reference = payment.get("external_reference") or ""
    try:
        user_id_str, plan = external_reference.split(":")
        user_id = int(user_id_str)
    except ValueError:
        return Response(status=200)

    if plan not in PLAN_DAYS:
        return Response(status=200)

    # mp_payment_id es unique=True — si MP reintenta el mismo webhook (pasa
    # seguido), el segundo intento no vuelve a sumar días de Premium.
    if Subscription.objects.filter(mp_payment_id=str(payment_id)).exists():
        return Response(status=200)

    sub, _ = Subscription.objects.get_or_create(user_id=user_id)
    # Si todavía le quedaban días de un pago anterior, se los sumamos en vez
    # de pisarlos — pagar antes de que venza no debería hacerle perder días.
    start = sub.current_period_end if sub.current_period_end and sub.current_period_end > timezone.now() else timezone.now()
    sub.status = "active"
    sub.mp_payment_id = str(payment_id)
    sub.current_period_end = start + timedelta(days=PLAN_DAYS[plan])
    try:
        sub.save()
    except IntegrityError:
        pass  # otro request en paralelo ya procesó este mismo pago
    return Response(status=200)
