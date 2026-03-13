// nutrition_screen.dart — SunnahStride v1.0 — Bilingual + Profile-synced goals
import 'package:flutter/material.dart'; import'package:flutter_riverpod/flutter_riverpod.dart'; import'package:fl_chart/fl_chart.dart'; import'package:go_router/go_router.dart'; import'../../core/theme.dart'; import'../../core/providers.dart'; import'../../data/models/models.dart'; import'../../core/ai_service.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override ConsumerState<NutritionScreen> createState() => _NutritionState();
}

class _NutritionState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _editingGoal = false;
  final _goalCtrl     = TextEditingController();
  final _proteinCtrl  = TextEditingController();
  final _carbsCtrl    = TextEditingController();
  final _fatCtrl      = TextEditingController(); String _foodSearch  ='';
  final _nameCtrl   = TextEditingController();
  final _kcalCtrl   = TextEditingController();
  bool _aiLoading   = false;
  String? _aiResult;
  final _aiCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose(); _goalCtrl.dispose(); _nameCtrl.dispose();
    _kcalCtrl.dispose(); _aiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang    = ref.watch(languageProvider); final isAr    = lang =='ar';
    final isDark  = ref.watch(themeProvider);
    final profile = ref.watch(userProfileProvider);
    String t(String ar, String en) => isAr ? ar : en;

    return Scaffold(
      appBar: AppBar( title: Text(t('التغذية 🌿', 'Nutrition 🌿')),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.barakahGold, labelStyle: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 11), unselectedLabelStyle: const TextStyle(fontFamily:'Cairo', fontSize: 11),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [ Tab(text: t('السعرات', 'Calories')), Tab(text: t('الوصفات', 'Recipes')), Tab(text: t('مخطط AI', 'AI Planner')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildCalories(isAr, isDark, profile),
          _buildRecipes(isAr, isDark),
          _buildAIPlanner(isAr, isDark, profile),
        ],
      ),
    );
  }

  // ── TAB 1: CALORIES ──────────────────────────────────────
  Widget _buildCalories(bool isAr, bool isDark, dynamic profile) {
    final cals  = ref.watch(caloriesProvider);
    final calBg = isDark ? AppColors.darkCard : Colors.white;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final calCol = cals.total > cals.goal
        ? AppColors.haramRed
        : cals.percent > 0.85 ? AppColors.doubtOrange : AppColors.halalGreen;
    String t(String ar, String en) => isAr ? ar : en;

    return ListView(padding: const EdgeInsets.all(14), children: [
      // ── Calorie ring + stats ──────────────────────────────
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: calBg, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(children: [
          // Profile-synced note
          if (profile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(
                isAr ?'🎯 الهدف مخصص لك: ${profile.calorieGoalKcal.toInt()} سعرة (${isAr ? profile.primaryGoal.nameAr() : profile.primaryGoal.nameEn()})' :'🎯 Personalized goal: ${profile.calorieGoalKcal.toInt()} kcal (${profile.primaryGoal.nameEn()})', style: const TextStyle(fontFamily:'Cairo', fontSize: 11, color: AppColors.sunnahGreen),
              ),
            ),
          SizedBox(
            height: 160,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: cals.percent.clamp(0.0, 1.0),
                strokeWidth: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(calCol),
                strokeCap: StrokeCap.round,
              )),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Text('${cals.total}', style: TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: calCol)), Text(t('مُستهلك', 'consumed'), style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _statPill(t('مُستهلك','Consumed'), '${cals.total}', calCol), _statPill(t('متبقي','Remaining'), '${cals.remaining}', AppColors.halalGreen), _statPill(t('الهدف','Goal'), '${cals.goal}', AppColors.sunnahGreen),
          ]),
          const SizedBox(height: 14),
          // Macro bars from profile
          if (profile != null) ...[ _macroBar(t('🍚 كربوهيدرات','🍚 Carbs'), profile.carbsGrams.toInt(), (profile.calorieGoalKcal / 4).toInt(), AppColors.waterBlue),
            const SizedBox(height: 6), _macroBar(t('🥩 بروتين','🥩 Protein'), profile.proteinGrams.toInt(), (profile.proteinGrams * 1.3).toInt(), AppColors.halalGreen),
            const SizedBox(height: 6), _macroBar(t('🧈 دهون','🧈 Fat'), profile.fatGrams.toInt(), (profile.calorieGoalKcal / 9 * 0.45).toInt(), AppColors.barakahGold),
            const SizedBox(height: 14),
          ],
          // Edit goal row
          if (_editingGoal) Row(children: [
            Expanded(child: TextField( controller: _goalCtrl..text ='${cals.goal}',
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration( labelText: t('الهدف اليومي (سعرة)','Daily Goal (kcal)'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              ),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final g = int.tryParse(_goalCtrl.text);
                if (g != null && g > 0) ref.read(caloriesProvider.notifier).setGoal(g);
                setState(() => _editingGoal = false);
              }, child: Text(t('حفظ','Save'), style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ]) else GestureDetector(
            onTap: () => setState(() => _editingGoal = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.4)), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.edit_outlined, size: 14, color: AppColors.sunnahGreen),
                const SizedBox(width: 6), Text(t('✏️ تعديل الهدف','✏️ Edit Goal'), style: const TextStyle(fontFamily:'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sunnahGreen)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // ── Macro rings (actual consumed today) ─────────────────
      if (cals.proteinTotal + cals.carbsTotal + cals.fatTotal > 0)
        _macroRingsCard(isAr, isDark, calBg, muted, cals),

      const SizedBox(height: 14),

      // ── Weekly calorie chart ──────────────────────────────
      _weeklyCalChart(isAr, isDark, calBg, muted),
      const SizedBox(height: 14),

      // ── Add meal button ───────────────────────────────────
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => _showAddMealSheet(context, isAr, isDark),
        icon: const Icon(Icons.add, color: Colors.white), label: Text(t('+ أضف وجبة','+ Add Meal'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen, padding: const EdgeInsets.symmetric(vertical: 13)),
      )),
      const SizedBox(height: 14),

      // ── Meals list ────────────────────────────────────────
      if (cals.entries.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(20),
          child: Column(children: [ const Text('🍽️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8), Text(t('لم تُسجّل أي وجبات اليوم','No meals logged today'), style: TextStyle(fontFamily:'Cairo', fontSize: 13, color: muted)),
          ]),
        ))
      else ...[ Text(t('وجبات اليوم','Today\'s Meals'), style: TextStyle(fontFamily:'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 10),
        ...cals.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: calBg, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Row(children: [ const Text('🍽️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(e.name, style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 13)), Text('${_timeStr(e.time)}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: muted)),
            ])), Text('${e.kcal} kcal', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.halalGreen)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => ref.read(caloriesProvider.notifier).removeEntry(e.id),
              child: const Icon(Icons.close, size: 16, color: AppColors.lightMuted)),
          ]),
        )),
      ],
      const SizedBox(height: 14),
    ]);
  }

  void _showAddMealSheet(BuildContext context, bool isAr, bool isDark) {
    _nameCtrl.clear(); _kcalCtrl.clear();
    String t(String ar, String en) => isAr ? ar : en;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14), Text(t('إضافة سريعة','Quick Add'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            StatefulBuilder(builder: (ctx, setS) => Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                textDirection: TextDirection.ltr,
                decoration: InputDecoration( hintText: t('ابحث عن طعام...', 'Search food...'),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _foodSearch.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { setState(() => _foodSearch ='');
                          setS(() {});
                        })
                      : null,
                  isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) { setState(() => _foodSearch = v); setS(() {}); },
              ),
              const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: kQuickFoods.map((f) => GestureDetector(
              onTap: () {
                ref.read(caloriesProvider.notifier).addEntry(f.name, f.kcal);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.3))), child: Text('${f.name}  ${f.kcal}kcal', style: const TextStyle(fontFamily:'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sunnahGreen)),
              ),
            )).toList()),
              ])),
            const Divider(height: 24), Text(t('إدخال مخصص','Custom Entry'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, decoration: InputDecoration(labelText: t('اسم الطعام','Food Name'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kcalCtrl, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t('السعرات الحرارية','Calories (kcal)'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _proteinCtrl, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText:'P (g)', border: const OutlineInputBorder()),
              )),
              const SizedBox(width: 6),
              Expanded(child: TextField(
                controller: _carbsCtrl, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText:'C (g)', border: const OutlineInputBorder()),
              )),
              const SizedBox(width: 6),
              Expanded(child: TextField(
                controller: _fatCtrl, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText:'F (g)', border: const OutlineInputBorder()),
              )),
            ]),
            const SizedBox(height: 4), Text(t('بروتين / كربوهيدرات / دهون (اختياري)', 'Protein / Carbs / Fat (optional)'), style: const TextStyle(fontFamily:'Cairo', fontSize: 10, color: AppColors.lightMuted)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                final name = _nameCtrl.text.trim();
                final kcal = int.tryParse(_kcalCtrl.text);
                if (name.isNotEmpty && kcal != null && kcal > 0) {
                  final p = double.tryParse(_proteinCtrl.text) ?? 0;
                  final c = double.tryParse(_carbsCtrl.text) ?? 0;
                  final f = double.tryParse(_fatCtrl.text) ?? 0;
                  ref.read(caloriesProvider.notifier).addEntry(name, kcal, proteinG: p, carbsG: c, fatG: f);
                  _proteinCtrl.clear(); _carbsCtrl.clear(); _fatCtrl.clear();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen), child: Text(t('✓ أضف للعداد','✓ Add to Tracker'), style: const TextStyle(fontFamily:'Cairo', color: Colors.white)),
            )),
          ]),
        ),
      ),
    );
  }

  // ── TAB 2: RECIPES ───────────────────────────────────────
  Widget _buildRecipes(bool isAr, bool isDark) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final bg    = isDark ? AppColors.darkCard  : Colors.white;
    String t(String ar, String en) => isAr ? ar : en;
    return ListView(padding: EdgeInsets.all(14), children: [ Text(t('وصفات سنية 🌿','Sunnah Recipes 🌿'), style: TextStyle(fontFamily:'Cairo', fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 4), Text(t('مبنية على سنة النبي ﷺ','Based on the Prophet\'s ﷺ Sunnah'), style: TextStyle(fontFamily:'Cairo', fontSize: 11, color: muted)),
      const SizedBox(height: 14),
      ...kRecipes.map((r) {
        final isOpen = ref.read(caloriesProvider).entries.isEmpty ? false : false;
        return _recipeCard(r, isAr, isDark, bg, muted);
      }),
    ]);
  }

  Widget _recipeCard(Recipe r, bool isAr, bool isDark, Color bg, Color muted) {
    final StateProvider<bool> expandProv = StateProvider((_) => false);
    return Consumer(builder: (ctx, wRef, _) {
      final isOpen = wRef.watch(expandProv);
      String t(String ar, String en) => isAr ? ar : en;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => wRef.read(expandProv.notifier).state = !isOpen,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(r.nameAr, style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [ _chip('⏱️ ${r.timeMins}${t("د","m")}', AppColors.waterBlue), _chip('💰 ${r.costEGP} EGP', AppColors.barakahGold), _chip('🔥 ${r.kcal} ${t("ك.ح","kcal")}', AppColors.haramRed),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: r.sunnahIngredients.map((s) => _chip('🌿 $s', AppColors.halalGreen)).toList()),
              ])),
              AnimatedRotation(turns: isOpen ? 0.5 : 0, duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.keyboard_arrow_down, color: AppColors.lightMuted)),
            ]),
          ),
          AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
            child: isOpen ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 18), Text(t('المكونات:','Ingredients:'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.sunnahGreen)),
              ...r.ingredients.map((ing) => Padding(padding: const EdgeInsets.only(top: 3, right: 10, left: 10), child: Text('• $ing', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)))),
              const SizedBox(height: 10), Text(t('طريقة التحضير:','Steps:'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.sunnahGreen)),
              ...r.steps.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(top: 4, right: 10, left: 10), child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, height: 1.5)))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () {
                  ref.read(caloriesProvider.notifier).addEntry(r.nameAr, r.kcal); // fire-and-forget ok
                  wRef.read(expandProv.notifier).state = false;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar( content: Text(isAr ?'✓ تمت الإضافة' : '✓ Added to tracker', style: const TextStyle(fontFamily:'Cairo')),
                    backgroundColor: AppColors.sunnahGreen,
                    duration: const Duration(seconds: 2),
                  ));
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.sunnahGreen, side: const BorderSide(color: AppColors.sunnahGreen)), child: Text(t('+ أضف للعداد','+ Add to Tracker'), style: const TextStyle(fontFamily: 'Cairo')),
              )),
            ]) : const SizedBox.shrink()),
        ])),
      );
    });
  }

  // ── TAB 3: AI PLANNER ────────────────────────────────────
  Widget _buildAIPlanner(bool isAr, bool isDark, dynamic profile) {
    final isPremium = ref.watch(premiumProvider);
    final bg        = isDark ? AppColors.darkCard : Colors.white;
    final muted     = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    String t(String ar, String en) => isAr ? ar : en;

    if (!isPremium) {
      return Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const Text('🤖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16), Text(t('مخطط الوجبات بالذكاء الاصطناعي','AI Meal Planner'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Text(t('يُخصّص خطة وجبات كاملة بناءً على جسمك وأهدافك وتفضيلاتك الحلالية', 'Creates a complete meal plan based on your body, goals & halal preferences'),
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 13, color: muted, height: 1.7)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: ElevatedButton( onPressed: () => context.push('/paywall'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.barakahGold, padding: const EdgeInsets.symmetric(vertical: 14)), child: Text(t('🔓 افتح بريميوم','🔓 Unlock Premium'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
        )),
      ])));
    }

    return ListView(padding: const EdgeInsets.all(14), children: [
      if (profile != null) Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Text(
          isAr ?'🤖 AI يعرف: وزنك ${profile.weightKg}كجم • هدفك: ${profile.primaryGoal.nameAr()} • سعراتك: ${profile.calorieGoalKcal.toInt()} • نظامك: ${profile.dietPreference.nameAr()}' :'🤖 AI knows: ${profile.weightKg}kg • Goal: ${profile.primaryGoal.nameEn()} • Calories: ${profile.calorieGoalKcal.toInt()} • Diet: ${profile.dietPreference.nameEn()}', style: const TextStyle(fontFamily:'Cairo', fontSize: 11, color: AppColors.sunnahGreen),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(t('اطلب خطة وجبات مخصصة:','Request a Personalized Meal Plan:'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: _aiCtrl,
            maxLines: 3,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: isAr ?'مثال: أريد خطة ٣ وجبات لخسارة الوزن مع تجنب الأرز...' :'e.g. I want a 3-meal plan for weight loss avoiding rice...', hintStyle: TextStyle(fontFamily:'Cairo', fontSize: 12, color: muted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _aiLoading ? null : _generatePlan,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _aiLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(t('🤖 ولّد الخطة','🤖 Generate Plan'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
          )),
        ]),
      ),
      if (_aiResult != null) ...[
        const SizedBox(height: 14),
        _buildAIResult(isAr, isDark, bg, muted),
      ],
      const SizedBox(height: 14),
    ]);
  }

  Widget _buildAIResult(bool isAr, bool isDark, Color bg, Color muted) {
    String t(String ar, String en) => isAr ? ar : en;
    final profile  = ref.read(userProfileProvider);
    final cGoal    = profile?.calorieGoalKcal.toInt() ?? 2000;
    final bf       = (cGoal * 0.25 / 3).toInt();
    final lGoal    = (cGoal * 0.35).toInt();
    final dGoal    = (cGoal * 0.40).toInt();
    // If real AI response, show it directly final isRealAI = _aiResult != null && _aiResult !='fallback';
    // Show error state for fallback if (_aiResult =='fallback') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.doubtOrange.withOpacity(0.08),
          border: Border.all(color: AppColors.doubtOrange.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [ const Text('⚠️', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(isAr ?'تعذّر الاتصال بـ AI. تأكد من اتصالك بالإنترنت وحاول مجدداً.' :'Could not reach AI. Check your internet connection and try again.',
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 12, color: muted, height: 1.5)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() { _aiResult = null; _aiCtrl.clear(); }), child: Text(isAr ?'↺ حاول مجدداً' : '↺ Try Again', style: const TextStyle(fontFamily:'Cairo', color: AppColors.sunnahGreen)),
          ),
        ]),
      );
    }
    if (isRealAI) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sunnahGreen.withOpacity(0.05),
          border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [ const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8), Text(t('خطتك الشخصية من AI', 'Your AI Personalized Plan'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.sunnahGreen)),
          ]),
          const SizedBox(height: 12), Text(_aiResult!, style: TextStyle(fontFamily:'Cairo', fontSize: 13, height: 1.7,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => setState(() { _aiResult = null; _aiCtrl.clear(); }),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.sunnahGreen, side: const BorderSide(color: AppColors.sunnahGreen)), child: Text(t('↺ طلب جديد', '↺ New Request'), style: const TextStyle(fontFamily: 'Cairo')),
          )),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sunnahGreen.withOpacity(0.05),
        border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(t('✨ خطتك الشخصية','✨ Your Personalized Plan'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.sunnahGreen)),
        SizedBox(height: 14), _mealPlanRow('🌅', t('الفطور','Breakfast'), isAr ?'شوفان بالعسل والتمر + كوب حليب\nبيضتان مسلوقتان + لبن' : 'Oats with honey & dates + milk\n2 boiled eggs + yogurt',
          bf, isAr),
        SizedBox(height: 12), _mealPlanRow('☀️', t('الغداء','Lunch'), isAr ?'دجاج مشوي حلال + أرز بني + سلطة خضراء\nزيت زيتون + ثوم + ليمون' : 'Halal grilled chicken + brown rice + green salad\nOlive oil + garlic + lemon',
          lGoal, isAr),
        SizedBox(height: 12), _mealPlanRow('🌙', t('العشاء','Dinner'), isAr ?'سمك مشوي + خضار مشكلة + عدس\nشوربة عدس بالليمون' : 'Grilled fish + mixed vegetables + lentils\nLentil soup with lemon',
          dGoal, isAr),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.barakahGold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(t('📖 توصيات سنية:','📖 Sunnah recommendations:'), style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.barakahGold)),
            const SizedBox(height: 6),
            Text( isAr ?'• تمر وماء عند الإفطار\n• ٧ تمرات صباحاً للوقاية\n• لا تأكل حتى تجوع\n• الصيام الاثنين والخميس مفيد جداً' :'• Dates & water for iftar\n• 7 dates in the morning for protection\n• Don\'t eat until you\'re hungry\n• Mon/Thu fasting is highly beneficial', style: const TextStyle(fontFamily:'Cairo', fontSize: 11, height: 1.7, color: AppColors.lightMuted),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _mealPlanRow(String emoji, String meal, String desc, int kcal, bool isAr) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(meal, style: const TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700, fontSize: 13)), Text(desc, style: const TextStyle(fontFamily:'Cairo', fontSize: 11, height: 1.5, color: AppColors.lightMuted)),
      ])), Text('$kcal\nkcal', textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.halalGreen)),
    ]);
  }

  Future<void> _generatePlan() async {
    setState(() { _aiLoading = true; _aiResult = null; });
    final profile = ref.read(userProfileProvider);
    final lang    = ref.read(languageProvider); final isAr    = lang =='ar';
    final goal    = profile?.calorieGoalKcal.toInt() ?? 2000;
    final diet    = profile != null
        ? (isAr ? profile.dietPreference.nameAr() : profile.dietPreference.nameEn()) : (isAr ?'حلال' : 'Halal');
    final goalStr = profile != null
        ? (isAr ? profile.primaryGoal.nameAr() : profile.primaryGoal.nameEn()) : (isAr ?'صحة عامة' : 'General health');

    final prompt = _aiCtrl.text.trim().isNotEmpty
        ? _aiCtrl.text.trim() : (isAr ?'اقترح لي خطة وجبات يومية مفصلة' : 'Suggest a detailed daily meal plan for me');

    try {
      final response = await AIService.getMealSuggestion(
        prompt: prompt,
        calorieGoal: goal,
        dietType: diet,
        goal: goalStr,
        language: lang,
      );
      if (mounted) setState(() { _aiLoading = false; _aiResult = response; });
    } catch (_) { if (mounted) setState(() { _aiLoading = false; _aiResult ='fallback'; });
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  // ── MACRO RINGS CARD ─────────────────────────────────────
  Widget _macroRingsCard(bool isAr, bool isDark, Color cardBg, Color muted, CaloriesState cals) {
    final p = cals.proteinTotal + cals.carbsTotal + cals.fatTotal;
    if (p <= 0) return const SizedBox.shrink();
    String t(String ar, String en) => isAr ? ar : en;

    Widget ring(double val, double total, Color col, String label) {
      final pct = total > 0 ? (val / total).clamp(0.0, 1.0) : 0.0;
      return Column(children: [
        SizedBox(width: 72, height: 72, child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(
            value: pct, strokeWidth: 8,
            backgroundColor: col.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(col),
            strokeCap: StrokeCap.round,
          )),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Text('${val.toInt()}g', style: TextStyle(fontFamily: 'Cairo',
                fontSize: 11, fontWeight: FontWeight.w900, color: col)), Text('${(pct * 100).toInt()}%', style: TextStyle( fontFamily:'Cairo', fontSize: 8, color: muted)),
          ]),
        ])),
        const SizedBox(height: 6), Text(label, style: TextStyle(fontFamily:'Cairo', fontSize: 10, color: muted)),
      ]);
    }

    final profile = ref.watch(userProfileProvider);
    final protGoal = profile?.proteinGrams ?? 50.0;
    final carbGoal = profile != null ? profile.calorieGoalKcal / 4 : 250.0;
    final fatGoal  = profile != null ? profile.calorieGoalKcal / 9 * 0.4 : 60.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Column(children: [ Text(t('💊 الماكروز المُتناولة اليوم', '💊 Today\'s Macros'), style: TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700,
                fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ ring(cals.proteinTotal, protGoal, AppColors.halalGreen, t('بروتين', 'Protein')), ring(cals.carbsTotal, carbGoal, AppColors.waterBlue, t('كربوهيدرات', 'Carbs')), ring(cals.fatTotal, fatGoal, AppColors.barakahGold, t('دهون', 'Fat')),
        ]),
      ]),
    );
  }

  // ── WEEKLY CALORIE BAR CHART ──────────────────────────────
  Widget _weeklyCalChart(bool isAr, bool isDark, Color cardBg, Color muted) {
    final weekly = ref.watch(weeklyKcalProvider);
    String t(String ar, String en) => isAr ? ar : en;

    return weekly.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        final dayNames = isAr ? ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'] : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

        // Fill last 7 days
        final today = DateTime.now();
        final bars = List.generate(7, (i) {
          final day = today.subtract(Duration(days: 6 - i)); final key ='${day.year}-${day.month.toString().padLeft(2,"0")}-${day.day.toString().padLeft(2,"0")}'; final found = data.where((d) => d['date'] == key).toList(); final kcal  = found.isNotEmpty ? (found.first['kcal'] as int).toDouble() : 0.0;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: kcal,
              color: i == 6 ? AppColors.sunnahGreen : AppColors.sunnahGreen.withOpacity(0.45),
              width: 22, borderRadius: BorderRadius.circular(6),
            ),
          ]);
        });

        final maxY = bars.map((b) => b.barRods.first.toY).reduce((a, b) => a > b ? a : b);
        final chartMax = (maxY * 1.25).clamp(500.0, 5000.0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
          child: Column(children: [ Text(t('📊 السعرات — آخر ٧ أيام', '📊 Calories — Last 7 Days'), style: TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w700,
                    fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
            const SizedBox(height: 16),
            SizedBox(height: 120, child: BarChart(BarChartData(
              barGroups: bars,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              maxY: chartMax,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 20,
                  getTitlesWidget: (v, _) => Text(dayNames[v.toInt() % 7], style: TextStyle(fontFamily:'Cairo', fontSize: 9, color: muted)),
                )),
                leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ))),
          ]),
        );
      },
    );
  }


  Widget _foodChip(QuickFood f, BuildContext context, bool isAr) {
    return GestureDetector(
      onTap: () {
        ref.read(caloriesProvider.notifier).addEntry(
          f.name, f.kcal, proteinG: f.proteinG, carbsG: f.carbsG, fatG: f.fatG);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sunnahGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(f.name, style: const TextStyle(fontFamily:'Cairo', fontSize: 11,
              fontWeight: FontWeight.w700, color: AppColors.sunnahGreen)), Text('${f.kcal} kcal  P:${f.proteinG.toInt()}g  C:${f.carbsG.toInt()}g  F:${f.fatG.toInt()}g', style: const TextStyle(fontFamily:'Cairo', fontSize: 9, color: AppColors.lightMuted)),
        ]),
      ),
    );
  }

  Widget _statPill(String label, String val, Color color) {
    return Column(children: [ Text(val, style: TextStyle(fontFamily:'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: color)), Text(label, style: const TextStyle(fontFamily:'Cairo', fontSize: 10, color: AppColors.lightMuted)),
    ]);
  }

  Widget _macroBar(String label, int val, int max, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: const TextStyle(fontFamily:'Cairo', fontSize: 12, fontWeight: FontWeight.w600)), Text('${val}g', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ]),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: (val / (max > 0 ? max : 1)).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(6), minHeight: 7),
    ]);
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontFamily:'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  String _timeStr(DateTime t) { final h = t.hour.toString().padLeft(2,'0'); final m = t.minute.toString().padLeft(2,'0'); return'$h:$m';
  }
}
