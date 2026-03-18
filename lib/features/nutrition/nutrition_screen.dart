import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../data/models/models.dart';
import '../../core/ai_service.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override ConsumerState<NutritionScreen> createState() => _NutritionState();
}

class _NutritionState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl    = TextEditingController();
  final _kcalCtrl    = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl   = TextEditingController();
  final _fatCtrl     = TextEditingController();
  final _aiCtrl      = TextEditingController();
  String _foodSearch = '';
  bool _aiLoading    = false;
  String? _aiResult;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose(); _kcalCtrl.dispose();
    _proteinCtrl.dispose(); _carbsCtrl.dispose();
    _fatCtrl.dispose(); _aiCtrl.dispose();
    super.dispose();
  }

  String t(String ar, String en) {
    final lang = ref.read(languageProvider);
    return lang == 'ar' ? ar : en;
  }

  // ── Add meal bottom sheet ──────────────────────────────────
  void _showAddSheet(BuildContext ctx, bool isAr, bool isDark) {
    _nameCtrl.clear(); _kcalCtrl.clear();
    _proteinCtrl.clear(); _carbsCtrl.clear(); _fatCtrl.clear();
    _foodSearch = '';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => StatefulBuilder(
        builder: (bCtx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isAr ? '🍽️ أضف وجبة' : '🍽️ Add Food',
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),

              // ── Quick foods ──────────────────────────────
              Text(isAr ? 'إضافة سريعة:' : 'Quick add:',
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.sunnahGreen)),
              const SizedBox(height: 6),
              TextField(
                onChanged: (v) => setS(() => _foodSearch = v.toLowerCase()),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث...' : 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: kQuickFoods
                    .where((f) => _foodSearch.isEmpty ||
                        f.name.toLowerCase().contains(_foodSearch))
                    .take(30)
                    .map((food) => GestureDetector(
                      onTap: () {
                        ref.read(caloriesProvider.notifier).addEntry(
                          food.name, food.kcal,
                          proteinG: food.proteinG,
                          carbsG: food.carbsG,
                          fatG: food.fatG,
                        );
                        Navigator.pop(bCtx);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('${food.name} ${isAr ? "أضيف ✓" : "added ✓"}',
                              style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: AppColors.sunnahGreen,
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sunnahGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.sunnahGreen.withOpacity(0.25)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(food.name, style: const TextStyle(
                                fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                                fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('🔥 ${food.kcal}', style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 10,
                                color: AppColors.lightMuted)),
                            Text('💪 ${food.proteinG}g', style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 9,
                                color: AppColors.halalGreen)),
                          ],
                        ),
                      ),
                    )).toList(),
                ),
              ),

              const Divider(height: 24),

              // ── Manual entry ─────────────────────────────
              Text(isAr ? 'إدخال يدوي:' : 'Manual entry:',
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.sunnahGreen)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم الطعام' : 'Food name',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kcalCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  labelText: isAr ? 'السعرات (kcal)' : 'Calories (kcal)',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                  controller: _proteinCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isAr ? 'بروتين (g)' : 'Protein (g)',
                    labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                  ),
                )),
                const SizedBox(width: 6),
                Expanded(child: TextField(
                  controller: _carbsCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isAr ? 'كارب (g)' : 'Carbs (g)',
                    labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                  ),
                )),
                const SizedBox(width: 6),
                Expanded(child: TextField(
                  controller: _fatCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isAr ? 'دهون (g)' : 'Fat (g)',
                    labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                  ),
                )),
              ]),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final kcal = int.tryParse(_kcalCtrl.text.trim());
                  if (name.isEmpty || kcal == null || kcal <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(isAr
                          ? 'أدخل اسم الطعام والسعرات'
                          : 'Enter food name and calories',
                          style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.haramRed,
                    ));
                    return;
                  }
                  final p  = double.tryParse(_proteinCtrl.text.trim()) ?? 0;
                  final c  = double.tryParse(_carbsCtrl.text.trim()) ?? 0;
                  final ft = double.tryParse(_fatCtrl.text.trim()) ?? 0;
                  await ref.read(caloriesProvider.notifier)
                      .addEntry(name, kcal, proteinG: p, carbsG: c, fatG: ft);
                  if (mounted) {
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('$name ${isAr ? "أضيف ✓" : "added ✓"}',
                          style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.sunnahGreen,
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunnahGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(isAr ? '✓ أضف للعداد' : '✓ Add to Tracker',
                    style: const TextStyle(fontFamily: 'Cairo',
                        fontSize: 15, color: Colors.white,
                        fontWeight: FontWeight.w700)),
              )),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _generatePlan() async {
    setState(() { _aiLoading = true; _aiResult = null; });
    final lang = ref.read(languageProvider);
    final profile = ref.read(userProfileProvider);
    final goal = profile?.calorieGoalKcal.toInt() ?? 2000;
    final prompt = _aiCtrl.text.trim().isNotEmpty
        ? _aiCtrl.text.trim()
        : (lang == 'ar'
            ? 'اقترح لي خطة وجبات يومية مفصلة'
            : 'Suggest a detailed daily meal plan for me');
    try {
      final response = await AIService.getMealSuggestion(
        prompt: prompt,
        calorieGoal: goal,
        dietType: lang == 'ar' ? 'حلال' : 'Halal',
        goal: lang == 'ar' ? 'صحة عامة' : 'General health',
        language: lang,
      );
      if (mounted) setState(() { _aiLoading = false; _aiResult = response; });
    } catch (_) {
      if (mounted) setState(() {
        _aiLoading = false;
        _aiResult = 'fallback';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang   = ref.watch(languageProvider);
    final isAr   = lang == 'ar';
    final isDark = ref.watch(themeProvider);
    final cals   = ref.watch(caloriesProvider);
    final profile = ref.watch(userProfileProvider);
    final isPremium = ref.watch(premiumProvider);
    final bg     = isDark ? AppColors.darkBg   : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final muted  = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textC  = isDark ? AppColors.darkText  : AppColors.lightText;
    String tl(String ar, String en) => isAr ? ar : en;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context, isAr, isDark),
          backgroundColor: AppColors.sunnahGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(tl('أضف طعام', 'Add Food'),
              style: const TextStyle(fontFamily: 'Cairo',
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        appBar: AppBar(
          title: Text(tl('التغذية 🌿', 'Nutrition 🌿'),
              style: const TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.sunnahGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tab,
            indicatorColor: AppColors.barakahGold,
            labelStyle: const TextStyle(fontFamily: 'Cairo',
                fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo', fontSize: 11),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: tl('السعرات', 'Calories')),
              Tab(text: tl('الوصفات', 'Recipes')),
              Tab(text: tl('AI مخطط', 'AI Planner')),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildCaloriesTab(isAr, isDark, bg, cardBg, muted, textC,
                cals, profile, isPremium),
            _buildRecipesTab(isAr, isDark, bg, cardBg, muted),
            _buildAITab(isAr, isDark, bg, cardBg, muted, profile, isPremium),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: CALORIES ──────────────────────────────────────
  Widget _buildCaloriesTab(bool isAr, bool isDark, Color bg, Color cardBg,
      Color muted, Color textC, CaloriesState cals, dynamic profile,
      bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;
    final goal = cals.goal;
    final pct  = goal > 0 ? (cals.total / goal).clamp(0.0, 1.0) : 0.0;
    final calCol = cals.total > goal
        ? AppColors.haramRed
        : cals.total > goal * 0.85
            ? AppColors.doubtOrange
            : AppColors.halalGreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      children: [
        // ── Calorie ring ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 12)]),
          child: Column(children: [
            SizedBox(height: 160,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(calCol),
                  strokeCap: StrokeCap.round,
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${cals.total}', style: TextStyle(fontFamily: 'Cairo',
                      fontSize: 40, fontWeight: FontWeight.w900,
                      color: calCol)),
                  Text(tl('سعرة', 'kcal'), style: TextStyle(fontFamily: 'Cairo',
                      fontSize: 12, color: muted)),
                  Text('/ $goal', style: TextStyle(fontFamily: 'Cairo',
                      fontSize: 12, color: muted)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _macroChip(tl('بروتين', 'Protein'),
                  '${cals.proteinTotal.toInt()}g', AppColors.halalGreen),
              _macroChip(tl('كارب', 'Carbs'),
                  '${cals.carbsTotal.toInt()}g', AppColors.waterBlue),
              _macroChip(tl('دهون', 'Fat'),
                  '${cals.fatTotal.toInt()}g', AppColors.barakahGold),
              _macroChip(tl('متبقي', 'Left'),
                  '${(goal - cals.total).abs()}', calCol),
            ]),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Weekly chart ──────────────────────────────────
        _weeklyChart(isAr, isDark, cardBg, muted),

        const SizedBox(height: 14),

        // ── Meal log ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(tl("سجل اليوم 📋", "Today's Log 📋"),
                  style: TextStyle(fontFamily: 'Cairo',
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: isAr ? AppColors.darkText : AppColors.lightText)),
              if (cals.entries.isNotEmpty)
                Text('${cals.entries.length} ${tl("وجبة", "meals")}',
                    style: TextStyle(fontFamily: 'Cairo',
                        fontSize: 11, color: muted)),
            ]),
            const SizedBox(height: 8),
            if (cals.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Column(children: [
                  const Text('🍽️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(tl('لا توجد وجبات اليوم', 'No meals logged today'),
                      style: TextStyle(fontFamily: 'Cairo',
                          fontSize: 13, color: muted)),
                ])),
              )
            else
              ...cals.entries.map((e) => Dismissible(
                key: Key('meal_${e.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.haramRed,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(caloriesProvider.notifier).removeEntry(e.id),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name, style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 13)),
                  subtitle: e.proteinG > 0
                      ? Text('💪 ${e.proteinG.toInt()}g  🍚 ${e.carbsG.toInt()}g  🥑 ${e.fatG.toInt()}g',
                          style: TextStyle(fontFamily: 'Cairo',
                              fontSize: 10, color: muted))
                      : null,
                  trailing: Text('${e.kcal} kcal',
                      style: const TextStyle(fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700, fontSize: 13,
                          color: AppColors.halalGreen)),
                ),
              )),
          ]),
        ),
      ],
    );
  }

  Widget _macroChip(String label, String val, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(val, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 9, color: color.withOpacity(0.8))),
    ],
  );

  Widget _weeklyChart(bool isAr, bool isDark, Color cardBg, Color muted) {
    final weekly = ref.watch(weeklyKcalProvider);
    final days   = isAr
        ? ['أح', 'إث', 'ث', 'أر', 'خ', 'ج', 'س']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isAr ? 'السعرات الأسبوعية 📊' : 'Weekly Calories 📊',
            style: TextStyle(fontFamily: 'Cairo',
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 14),
        SizedBox(height: 120, child: weekly.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            final today = DateTime.now();
            final bars = List.generate(7, (i) {
              final d = today.subtract(Duration(days: 6 - i));
              final key =
                  '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final found = data.where((x) => x['date'] == key).toList();
              final kcal = found.isNotEmpty
                  ? (found.first['kcal'] as num).toDouble()
                  : 0.0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: kcal,
                    color: AppColors.sunnahGreen, width: 16,
                    borderRadius: BorderRadius.circular(4)),
              ]);
            });
            return BarChart(BarChartData(
              barGroups: bars,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(days[v.toInt()],
                      style: TextStyle(fontFamily: 'Cairo',
                          fontSize: 9, color: muted)),
                )),
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ));
          },
        )),
      ]),
    );
  }

  // ── TAB 2: RECIPES ───────────────────────────────────────
  Widget _buildRecipesTab(bool isAr, bool isDark, Color bg,
      Color cardBg, Color muted) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(isAr ? '🌿 وصفات سنية صحية' : '🌿 Healthy Sunnah Recipes',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 4),
        Text(isAr ? 'مستوحاة من السنة النبوية ﷺ'
            : 'Inspired by the Prophetic Sunnah ﷺ',
            style: TextStyle(fontFamily: 'Cairo',
                fontSize: 11, color: muted)),
        const SizedBox(height: 14),
        ...kRecipes.map((r) => _recipeCard(r, isAr, isDark, cardBg, muted)),
      ],
    );
  }

  Widget _recipeCard(Recipe r, bool isAr, bool isDark,
      Color cardBg, Color muted) {
    return GestureDetector(
      onTap: () {
        ref.read(caloriesProvider.notifier)
            .addEntry(r.nameAr, r.kcal,
                proteinG: r.proteinG.toDouble(),
                carbsG: r.carbsG.toDouble(),
                fatG: r.fatG.toDouble());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${r.nameAr} ${isAr ? "أضيف ✓" : "added ✓"}',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.sunnahGreen,
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8)]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(r.nameAr, style: const TextStyle(fontFamily: 'Cairo',
                fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              _chip('🔥 ${r.kcal}', AppColors.haramRed),
              const SizedBox(width: 6),
              _chip('💪 ${r.proteinG}g', AppColors.halalGreen),
              const SizedBox(width: 6),
              _chip('⏱ ${r.timeMins}${isAr ? "د" : "m"}',
                  AppColors.waterBlue),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.sunnahGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isAr ? '+ أضف' : '+ Add',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sunnahGreen)),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontFamily: 'Cairo',
        fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  // ── TAB 3: AI PLANNER ────────────────────────────────────
  Widget _buildAITab(bool isAr, bool isDark, Color bg, Color cardBg,
      Color muted, dynamic profile, bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;

    if (!isPremium) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(tl('مخطط الوجبات بالذكاء الاصطناعي',
                  'AI Meal Planner'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo',
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(tl('يُخصّص خطة وجبات بناءً على جسمك وأهدافك',
                  'Personalized meal plan based on your body & goals'),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo',
                  fontSize: 13, color: muted, height: 1.7)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.push('/paywall'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.barakahGold,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(tl('🔓 افتح بريميوم', '🔓 Unlock Premium'),
                style: const TextStyle(fontFamily: 'Cairo',
                    fontSize: 16, color: Colors.white,
                    fontWeight: FontWeight.w700)),
          )),
        ]),
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (profile != null) Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: AppColors.sunnahGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Text(
            isAr
              ? '🤖 AI يعرف: وزنك ${profile.weightKg}كجم • سعراتك: ${profile.calorieGoalKcal.toInt()}'
              : '🤖 AI knows: ${profile.weightKg}kg • Calories: ${profile.calorieGoalKcal.toInt()}',
            style: const TextStyle(fontFamily: 'Cairo',
                fontSize: 11, color: AppColors.sunnahGreen),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(tl('اطلب خطة وجبات مخصصة:',
                    'Request a Personalized Meal Plan:'),
                style: const TextStyle(fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: _aiCtrl,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'مثال: خطة رمضان، بدون جلوتين...'
                    : 'e.g. Ramadan plan, gluten-free...',
                hintStyle: TextStyle(fontFamily: 'Cairo',
                    fontSize: 12, color: muted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _aiLoading ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunnahGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _aiLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(tl('🤖 توليد خطة وجبات',
                          '🤖 Generate Meal Plan'),
                      style: const TextStyle(fontFamily: 'Cairo',
                          color: Colors.white, fontSize: 13)),
            )),
          ]),
        ),
        if (_aiResult != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardBg,
                borderRadius: BorderRadius.circular(16)),
            child: _aiResult == 'fallback'
                ? Center(child: Column(children: [
                    const Text('😔', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(isAr
                        ? 'تعذّر الاتصال. حاول مجدداً.'
                        : 'Could not connect. Try again.',
                        style: TextStyle(fontFamily: 'Cairo',
                            fontSize: 12, color: muted)),
                  ]))
                : Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Text('🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(tl('خطتك الشخصية', 'Your Personal Plan'),
                        style: const TextStyle(fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700, fontSize: 15,
                            color: AppColors.sunnahGreen)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_aiResult!,
                      style: TextStyle(fontFamily: 'Cairo',
                          fontSize: 13, height: 1.7,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText)),
                ]),
          ),
        ],
      ],
    );
  }
}
