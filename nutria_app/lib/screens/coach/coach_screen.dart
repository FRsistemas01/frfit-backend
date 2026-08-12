import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/diary_bus.dart';
import '../../services/nutrition_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/skeleton.dart';

const _mealLabels = {'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'snack': 'Merienda', 'dinner': 'Cena'};
const _mealIcons = {'breakfast': '🍳', 'lunch': '🍗', 'snack': '🍎', 'dinner': '🍝'};

const _suggestions = [
  'Armame un plan de comidas para hoy',
  '¿Qué ceno liviano y con proteína?',
  'Tengo pollo y arroz, ¿qué preparo?',
  '¿Cómo voy con mi objetivo esta semana?',
];

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _messages = <CoachChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loadingHistory = true;
  bool _sending = false;
  final Set<int> _savedPlans = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await NutritionRepository.instance.chatHistory();
    if (!mounted) return;
    setState(() {
      _messages.addAll(history);
      _loadingHistory = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _inputCtrl.text).trim();
    if (message.isEmpty || _sending) return;

    setState(() {
      _messages.add(CoachChatMessage(role: 'user', content: message, createdAt: DateTime.now()));
      _inputCtrl.clear();
      _sending = true;
    });
    _scrollToBottom();

    CoachChatMessage? reply;
    PremiumRequiredException? blocked;
    try {
      reply = await NutritionRepository.instance.sendChatMessage(message);
    } on PremiumRequiredException catch (e) {
      blocked = e;
    }
    if (!mounted) return;
    setState(() {
      if (blocked != null) {
        // El mensaje no se guardó del lado del servidor — lo sacamos de la
        // lista local para que no quede como enviado.
        _messages.removeLast();
      } else if (reply != null) {
        _messages.add(reply);
      } else {
        _messages.add(CoachChatMessage(role: 'assistant', content: 'No pude conectarme en este momento — probá de nuevo en un rato.', createdAt: DateTime.now()));
      }
      _sending = false;
    });
    if (blocked != null) showPremiumRequired(context, blocked.message);
    _scrollToBottom();
  }

  Future<void> _savePlan(int msgIndex, List<PlanMeal> plan) async {
    final ok = await NutritionRepository.instance.savePlanToDiary(plan);
    if (ok) DiaryBus.instance.refresh();
    if (!mounted) return;
    if (ok) setState(() => _savedPlans.add(msgIndex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Plan agregado a tu diario 🎉' : 'No se pudo guardar el plan.'),
        backgroundColor: ok ? AppColors.goodSoft : AppColors.warnSoft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu coach', style: Theme.of(context).textTheme.headlineLarge),
                      Text('Preguntale lo que necesites', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _messages.isEmpty
                ? _EmptyState(onSuggestion: _send)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) return const _TypingBubble();
                      final m = _messages[i];
                      return StaggeredEntrance(
                        index: i,
                        child: _ChatBubble(
                          message: m,
                          saved: _savedPlans.contains(i),
                          onSavePlan: m.mealPlan != null ? () => _savePlan(i, m.mealPlan!) : null,
                        ),
                      );
                    },
                  ),
          ),
          if (_messages.isNotEmpty && !_loadingHistory)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _send(_suggestions[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
                      child: Text(_suggestions[i], style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Escribile al coach…',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface2,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: const BorderSide(color: AppColors.accent)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _send(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text('¿En qué te ayudo?', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Pedime un plan de comidas, preguntame sobre tus macros, o contame qué tenés en la heladera.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onSuggestion(s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.saved, this.onSavePlan});
  final CoachChatMessage message;
  final bool saved;
  final VoidCallback? onSavePlan;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? AppColors.accent : AppColors.surface2,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: AppColors.border),
            ),
            child: Text(message.content, style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 13, height: 1.45)),
          ),
          if (message.mealPlan != null) ...[
            const SizedBox(height: 8),
            _PlanCard(plan: message.mealPlan!, saved: saved, onSave: onSavePlan),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.saved, this.onSave});
  final List<PlanMeal> plan;
  final bool saved;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final totalKcal = plan.fold(0, (sum, m) => sum + m.totalKcal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text('PLAN GENERADO', style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const Spacer(),
              Text('$totalKcal kcal', style: AppTypography.numeric(size: 12, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 10),
          ...plan.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_mealIcons[m.mealType] ?? '🍽️'} ${_mealLabels[m.mealType] ?? m.mealType}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ...m.items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(i.name, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                          Text('${i.kcal}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saved ? null : onSave,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
              child: Text(saved ? '✓ Agregado a tu diario' : 'Agregar a mi diario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
            border: Border.all(color: AppColors.border),
          ),
          child: const SizedBox(
            width: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Dot(),
                _Dot(),
                _Dot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle));
  }
}
