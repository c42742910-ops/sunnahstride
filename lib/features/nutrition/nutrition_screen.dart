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
  final _searchCtrl  = TextEditingController();
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
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Add meal sheet ─────────────────────────────────────────
  void _showAddSheet(BuildContext ctx) {
    final lang  = ref.read(languageProvider);
    final isAr  = lang == 'ar';
    final isDark = ref.read(themeProvider);
    _nameCtrl.clear(); _kcalCtrl.clear();
    _proteinCtrl.clear(); _carbsCtrl.clear(); _fatCtrl.clear();
    _searchCtrl.clear();
    _foodSearch = '';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddFoodSheet(
        isAr: isAr,
        isDark: isDark,
        onAdd: (name, kcal, p, c, ft) async {
          await ref.read(caloriesProvider.notifier)
              .addEntry(name, kcal, proteinG: p, carbsG: c, fatG: ft);
          if (mounted) Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('$name ${isAr ? "أضيف ✓" : "added ✓"}',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.sunnahGreen,
            duration: const Duration(seconds: 2),
          ));
        },
      ),
    );
  }

  Future<void> _generatePlan() async {
    setState(() { _aiLoading = true; _aiResult = null; });
    final lang    = ref.read(languageProvider);
    final profile = ref.read(userProfileProvider);
    final goal    = profile?.calorieGoalKcal.toInt() ?? 2000;
    final prompt  = _aiCtrl.text.trim().isNotEmpty
        ? _aiCtrl.text.trim()
        : (lang == 'ar'
            ? 'اقترح لي خطة وجبات يومية مفصلة وصحية'
            : 'Suggest a detailed healthy daily meal plan for me');
    try {
      final response = await AIService.getMealSuggestion(
        prompt: prompt, calorieGoal: goal,
        dietType: lang == 'ar' ? 'حلال' : 'Halal',
        goal: lang == 'ar' ? 'صحة عامة' : 'General health',
        language: lang,
      );
      if (mounted) setState(() { _aiLoading = false; _aiResult = response; });
    } catch (_) {
      if (mounted) setState(() { _aiLoading = false; _aiResult = 'fallback'; });
    }
  }


  // ── Food detail dialog ────────────────────────────────────
  void _showFoodDetail(BuildContext ctx, MealEntry e, bool isAr, bool isDark, bool isPremium) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    String tl(String ar, String en) => isAr ? ar : en;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Text(e.name, style: const TextStyle(fontFamily: 'Cairo',
              fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(tl('القيم الغذائية', 'Nutritional Values'),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          // Main macros
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _detailBadge('🔥', '${e.kcal}', tl('سعرة', 'kcal'), AppColors.haramRed),
            _detailBadge('💪', '${e.proteinG.toStringAsFixed(1)}g', tl('بروتين', 'Protein'), AppColors.halalGreen),
            _detailBadge('🍚', '${e.carbsG.toStringAsFixed(1)}g', tl('كارب', 'Carbs'), AppColors.waterBlue),
            _detailBadge('🥑', '${e.fatG.toStringAsFixed(1)}g', tl('دهون', 'Fat'), AppColors.barakahGold),
          ]),
          const SizedBox(height: 20),
          // Premium micronutrients
          if (isPremium) ...[
            Divider(color: AppColors.barakahGold.withOpacity(0.3)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.star, color: AppColors.barakahGold, size: 16),
              const SizedBox(width: 6),
              Text(tl('مغذيات دقيقة', 'Micronutrients'),
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.barakahGold)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _detailBadge('🍊', '~${(e.kcal * 0.08).toStringAsFixed(0)}mg', tl('فيت. C', 'Vit. C'), Colors.orange),
              _detailBadge('🩸', '~${(e.proteinG * 0.15).toStringAsFixed(1)}mg', tl('حديد', 'Iron'), Colors.redAccent),
              _detailBadge('🥛', '~${(e.kcal * 0.5).toStringAsFixed(0)}mg', tl('كالسيوم', 'Calcium'), Colors.blueGrey),
              _detailBadge('🍌', '~${(e.kcal * 1.2).toStringAsFixed(0)}mg', tl('بوتاسيوم', 'Potassium'), Colors.amber),
            ]),
            const SizedBox(height: 8),
            Text(tl('* تقديري بناءً على السعرات', '* Estimated based on calories'),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: muted)),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.barakahGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.barakahGold.withOpacity(0.3))),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    tl('بريميوم: شاهد الفيتامينات والمعادن لكل وجبة',
                       'Premium: See vitamins & minerals for every meal'),
                    style: const TextStyle(fontFamily: 'Cairo',
                        fontSize: 11, color: AppColors.barakahGold))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                ref.read(caloriesProvider.notifier).removeEntry(e.id);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.haramRed, size: 18),
              label: Text(tl('حذف', 'Delete'),
                  style: const TextStyle(fontFamily: 'Cairo', color: AppColors.haramRed)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.haramRed)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen),
              child: Text(tl('إغلاق', 'Close'),
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _detailBadge(String emoji, String val, String label, Color color) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 9, color: color.withOpacity(0.8))),
    ]);

  @override
  Widget build(BuildContext context) {
    final lang    = ref.watch(languageProvider);
    final isAr    = lang == 'ar';
    final isDark  = ref.watch(themeProvider);
    final cals    = ref.watch(caloriesProvider);
    final profile = ref.watch(userProfileProvider);
    final isPremium = ref.watch(premiumProvider);
    final bg      = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final cardBg  = isDark ? AppColors.darkCard  : Colors.white;
    final muted   = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textC   = isDark ? AppColors.darkText  : AppColors.lightText;
    String tl(String ar, String en) => isAr ? ar : en;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context),
          backgroundColor: AppColors.sunnahGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(tl('أضف طعام', 'Add Food'),
              style: const TextStyle(fontFamily: 'Cairo',
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        appBar: AppBar(
          title: Text(tl('التغذية 🌿', 'Nutrition 🌿'),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.sunnahGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tab,
            indicatorColor: AppColors.barakahGold,
            labelStyle: const TextStyle(fontFamily: 'Cairo',
                fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
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
            _buildCaloriesTab(isAr, isDark, bg, cardBg, muted, textC, cals, profile, isPremium),
            _buildRecipesTab(isAr, isDark, cardBg, muted),
            _buildAITab(isAr, isDark, bg, cardBg, muted, profile, isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesTab(bool isAr, bool isDark, Color bg, Color cardBg,
      Color muted, Color textC, CaloriesState cals, dynamic profile, bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;
    final goal = cals.goal;
    final pct  = goal > 0 ? (cals.total / goal).clamp(0.0, 1.0) : 0.0;
    final calCol = cals.total > goal ? AppColors.haramRed
        : cals.total > goal * 0.85 ? AppColors.doubtOrange
        : AppColors.halalGreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
          child: Column(children: [
            SizedBox(height: 160, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: pct, strokeWidth: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(calCol),
                strokeCap: StrokeCap.round,
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${cals.total}', style: TextStyle(fontFamily: 'Cairo',
                    fontSize: 40, fontWeight: FontWeight.w900, color: calCol)),
                Text(tl('سعرة', 'kcal'), style: TextStyle(fontFamily: 'Cairo',
                    fontSize: 12, color: muted)),
                Text('/ $goal', style: TextStyle(fontFamily: 'Cairo',
                    fontSize: 12, color: muted)),
              ]),
            ])),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _macro(tl('بروتين', 'Protein'), '${cals.proteinTotal.toInt()}g', AppColors.halalGreen),
              _macro(tl('كارب', 'Carbs'), '${cals.carbsTotal.toInt()}g', AppColors.waterBlue),
              _macro(tl('دهون', 'Fat'), '${cals.fatTotal.toInt()}g', AppColors.barakahGold),
              _macro(tl('متبقي', 'Left'), '${(goal - cals.total).abs()}', calCol),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        _weeklyChart(isAr, isDark, cardBg, muted),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(tl('سجل اليوم 📋', "Today's Log 📋"),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                      fontWeight: FontWeight.w700, color: textC)),
              if (cals.entries.isNotEmpty)
                Text('${cals.entries.length} ${tl("وجبة", "meals")}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
            ]),
            const SizedBox(height: 8),
            if (cals.entries.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Column(children: [
                  const Text('🍽️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(tl('لا توجد وجبات اليوم', 'No meals logged today'),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: muted)),
                ])))
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
                  onTap: () => _showFoodDetail(context, e, isAr, isDark, isPremium),
                  title: Text(e.name, style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 13)),
                  subtitle: e.proteinG > 0
                      ? Text('💪 \${e.proteinG.toInt()}g  🍚 \${e.carbsG.toInt()}g  🥑 \${e.fatG.toInt()}g',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: muted))
                      : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('\${e.kcal} kcal',
                        style: const TextStyle(fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: AppColors.halalGreen)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.lightMuted),
                  ]),
                ),
              )),
          ]),
        ),
      ],
    );
  }

  Widget _macro(String label, String val, Color color) => Column(
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
    final days = isAr
        ? ['أح', 'إث', 'ث', 'أر', 'خ', 'ج', 'س']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isAr ? 'السعرات الأسبوعية 📊' : 'Weekly Calories 📊',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 14),
        SizedBox(height: 120, child: weekly.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            final today = DateTime.now();
            final bars = List.generate(7, (i) {
              final d = today.subtract(Duration(days: 6 - i));
              final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final found = data.where((x) => x['date'] == key).toList();
              final kcal = found.isNotEmpty ? (found.first['kcal'] as num).toDouble() : 0.0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: kcal, color: AppColors.sunnahGreen,
                    width: 16, borderRadius: BorderRadius.circular(4)),
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
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: muted)),
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

  Widget _buildRecipesTab(bool isAr, bool isDark, Color cardBg, Color muted) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(isAr ? '🌿 وصفات سنية صحية' : '🌿 Healthy Sunnah Recipes',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 4),
        Text(isAr ? 'مستوحاة من السنة النبوية ﷺ' : 'Inspired by the Prophetic Sunnah ﷺ',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
        const SizedBox(height: 14),
        ...kRecipes.map((r) => GestureDetector(
          onTap: () {
            ref.read(caloriesProvider.notifier).addEntry(r.nameAr, r.kcal,
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.nameAr, style: const TextStyle(fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  _chip('🔥 ${r.kcal}', AppColors.haramRed),
                  const SizedBox(width: 6),
                  _chip('💪 ${r.proteinG}g', AppColors.halalGreen),
                  const SizedBox(width: 6),
                  _chip('⏱ ${r.timeMins}${isAr ? "د" : "m"}', AppColors.waterBlue),
                ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(isAr ? '+ أضف' : '+ Add',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                        fontWeight: FontWeight.w700, color: AppColors.sunnahGreen)),
              ),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontFamily: 'Cairo',
        fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _buildAITab(bool isAr, bool isDark, Color bg, Color cardBg,
      Color muted, dynamic profile, bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;
    if (!isPremium) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(tl('مخطط الوجبات بالذكاء الاصطناعي', 'AI Meal Planner'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.push('/paywall'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.barakahGold,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(tl('🔓 افتح بريميوم', '🔓 Unlock Premium'),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16,
                    color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ));
    }
    return ListView(padding: const EdgeInsets.all(14), children: [
      if (profile != null) Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
        child: Text(
          isAr ? '🤖 AI يعرف: وزنك ${profile.weightKg}كجم • سعراتك: ${profile.calorieGoalKcal.toInt()}'
               : '🤖 AI knows: ${profile.weightKg}kg • Calories: ${profile.calorieGoalKcal.toInt()}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
              color: AppColors.sunnahGreen),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tl('اطلب خطة وجبات مخصصة:', 'Request a Personalized Meal Plan:'),
              style: const TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: _aiCtrl, maxLines: 2,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: InputDecoration(
              hintText: isAr ? 'مثال: خطة رمضان، بدون جلوتين...'
                  : 'e.g. Ramadan plan, gluten-free...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _aiLoading ? null : _generatePlan,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _aiLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(tl('🤖 توليد خطة وجبات', '🤖 Generate Meal Plan'),
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
          )),
        ]),
      ),
      if (_aiResult != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
          child: _aiResult == 'fallback'
              ? Center(child: Text(isAr ? 'تعذّر الاتصال. حاول مجدداً.'
                  : 'Could not connect. Try again.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted)))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(tl('خطتك الشخصية', 'Your Personal Plan'),
                        style: const TextStyle(fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700, fontSize: 15,
                            color: AppColors.sunnahGreen)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_aiResult!, style: TextStyle(fontFamily: 'Cairo',
                      fontSize: 13, height: 1.7,
                      color: isDark ? AppColors.darkText : AppColors.lightText)),
                ]),
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Separate StatefulWidget for the Add Food Sheet
// This avoids context/state issues
// ══════════════════════════════════════════════════════════════
class _AddFoodSheet extends ConsumerStatefulWidget {
  final bool isAr;
  final bool isDark;
  final Future<void> Function(String, int, double, double, double) onAdd;

  const _AddFoodSheet({
    required this.isAr,
    required this.isDark,
    required this.onAdd,
  });

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _searchCtrl  = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _kcalCtrl    = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl   = TextEditingController();
  final _fatCtrl     = TextEditingController();

  bool _searching = false;
  Map<String, dynamic>? _aiResult;
  String _searchText = '';
  bool _adding = false;
  int _tab = 0; // 0=search, 1=manual, 2=quick

  @override
  void dispose() {
    _searchCtrl.dispose(); _nameCtrl.dispose(); _kcalCtrl.dispose();
    _proteinCtrl.dispose(); _carbsCtrl.dispose(); _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchFood() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _searching = true; _aiResult = null; });
    try {
      final lang = ref.read(languageProvider);
      final result = await AIService.lookupFood(q, language: lang);
      setState(() { _searching = false; _aiResult = result; });
    } catch (_) {
      setState(() { _searching = false; });
    }
  }

  void _fillFromAI() {
    if (_aiResult == null) return;
    final r = _aiResult!;
    _nameCtrl.text = widget.isAr
        ? (r['name_ar'] ?? r['name_en'] ?? _searchCtrl.text)
        : (r['name_en'] ?? r['name_ar'] ?? _searchCtrl.text);
    _kcalCtrl.text    = '${(r['kcal'] ?? 0).round()}';
    _proteinCtrl.text = '${(r['protein_g'] ?? 0.0).toStringAsFixed(1)}';
    _carbsCtrl.text   = '${(r['carbs_g'] ?? 0.0).toStringAsFixed(1)}';
    _fatCtrl.text     = '${(r['fat_g'] ?? 0.0).toStringAsFixed(1)}';
    setState(() => _tab = 1);
  }


  // ── Food detail dialog ────────────────────────────────────
  void _showFoodDetail(BuildContext ctx, MealEntry e, bool isAr, bool isDark, bool isPremium) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    String tl(String ar, String en) => isAr ? ar : en;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Text(e.name, style: const TextStyle(fontFamily: 'Cairo',
              fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(tl('القيم الغذائية', 'Nutritional Values'),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          // Main macros
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _detailBadge('🔥', '${e.kcal}', tl('سعرة', 'kcal'), AppColors.haramRed),
            _detailBadge('💪', '${e.proteinG.toStringAsFixed(1)}g', tl('بروتين', 'Protein'), AppColors.halalGreen),
            _detailBadge('🍚', '${e.carbsG.toStringAsFixed(1)}g', tl('كارب', 'Carbs'), AppColors.waterBlue),
            _detailBadge('🥑', '${e.fatG.toStringAsFixed(1)}g', tl('دهون', 'Fat'), AppColors.barakahGold),
          ]),
          const SizedBox(height: 20),
          // Premium micronutrients
          if (isPremium) ...[
            Divider(color: AppColors.barakahGold.withOpacity(0.3)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.star, color: AppColors.barakahGold, size: 16),
              const SizedBox(width: 6),
              Text(tl('مغذيات دقيقة', 'Micronutrients'),
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.barakahGold)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _detailBadge('🍊', '~${(e.kcal * 0.08).toStringAsFixed(0)}mg', tl('فيت. C', 'Vit. C'), Colors.orange),
              _detailBadge('🩸', '~${(e.proteinG * 0.15).toStringAsFixed(1)}mg', tl('حديد', 'Iron'), Colors.redAccent),
              _detailBadge('🥛', '~${(e.kcal * 0.5).toStringAsFixed(0)}mg', tl('كالسيوم', 'Calcium'), Colors.blueGrey),
              _detailBadge('🍌', '~${(e.kcal * 1.2).toStringAsFixed(0)}mg', tl('بوتاسيوم', 'Potassium'), Colors.amber),
            ]),
            const SizedBox(height: 8),
            Text(tl('* تقديري بناءً على السعرات', '* Estimated based on calories'),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: muted)),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.barakahGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.barakahGold.withOpacity(0.3))),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    tl('بريميوم: شاهد الفيتامينات والمعادن لكل وجبة',
                       'Premium: See vitamins & minerals for every meal'),
                    style: const TextStyle(fontFamily: 'Cairo',
                        fontSize: 11, color: AppColors.barakahGold))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                ref.read(caloriesProvider.notifier).removeEntry(e.id);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.haramRed, size: 18),
              label: Text(tl('حذف', 'Delete'),
                  style: const TextStyle(fontFamily: 'Cairo', color: AppColors.haramRed)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.haramRed)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen),
              child: Text(tl('إغلاق', 'Close'),
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _detailBadge(String emoji, String val, String label, Color color) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 9, color: color.withOpacity(0.8))),
    ]);

  @override
  Widget build(BuildContext context) {
    final isAr   = widget.isAr;
    final isDark = widget.isDark;
    final muted  = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    String tl(String ar, String en) => isAr ? ar : en;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text(tl('🍽️ أضف طعام', '🍽️ Add Food'),
              style: const TextStyle(fontFamily: 'Cairo',
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),

          // Tab selector
          Row(children: [
            _tabBtn(tl('🤖 AI بحث', '🤖 AI Search'), 0),
            const SizedBox(width: 8),
            _tabBtn(tl('✏️ يدوي', '✏️ Manual'), 1),
            const SizedBox(width: 8),
            _tabBtn(tl('⚡ سريع', '⚡ Quick'), 2),
          ]),
          const SizedBox(height: 16),

          // ── TAB 0: AI Search ──────────────────────────
          if (_tab == 0) ...[
            Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                onSubmitted: (_) => _searchFood(),
                decoration: InputDecoration(
                  hintText: tl('ابحث عن أي طعام...', 'Search any food...'),
                  hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.sunnahGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.sunnahGreen, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searching ? null : _searchFood,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunnahGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _searching
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(tl('بحث', 'Search'),
                        style: const TextStyle(fontFamily: 'Cairo',
                            color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            if (_aiResult != null) _buildAIResultCard(isAr, isDark, muted),
            if (!_searching && _aiResult == null)
              Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('🔍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(tl('ابحث عن أي طعام في العالم\nوالذكاء الاصطناعي سيعطيك قيمه الغذائية',
                          'Search any food in the world\nAI will give you its nutritional values'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
                          color: muted, height: 1.6)),
                ]))),
          ],

          // ── TAB 1: Manual ──────────────────────────────
          if (_tab == 1) ...[
            TextField(
              controller: _nameCtrl,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                labelText: tl('اسم الطعام *', 'Food name *'),
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kcalCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                labelText: tl('السعرات (kcal) *', 'Calories (kcal) *'),
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _numField(_proteinCtrl, tl('بروتين g', 'Protein g'))),
              const SizedBox(width: 6),
              Expanded(child: _numField(_carbsCtrl, tl('كارب g', 'Carbs g'))),
              const SizedBox(width: 6),
              Expanded(child: _numField(_fatCtrl, tl('دهون g', 'Fat g'))),
            ]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _adding ? null : () async {
                final name = _nameCtrl.text.trim();
                final kcal = int.tryParse(_kcalCtrl.text.trim());
                if (name.isEmpty || kcal == null || kcal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isAr ? 'أدخل الاسم والسعرات' : 'Enter name and calories',
                        style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: AppColors.haramRed,
                  ));
                  return;
                }
                setState(() => _adding = true);
                await widget.onAdd(
                  name, kcal,
                  double.tryParse(_proteinCtrl.text.trim()) ?? 0,
                  double.tryParse(_carbsCtrl.text.trim()) ?? 0,
                  double.tryParse(_fatCtrl.text.trim()) ?? 0,
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunnahGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _adding
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(tl('✓ أضف للعداد', '✓ Add to Tracker'),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15,
                          color: Colors.white, fontWeight: FontWeight.w700)),
            )),
          ],

          // ── TAB 2: Quick foods ─────────────────────────
          if (_tab == 2) ...[
            TextField(
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              decoration: InputDecoration(
                hintText: tl('فلتر...', 'Filter...'),
                prefixIcon: const Icon(Icons.filter_list, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
            const SizedBox(height: 8),
            ...kQuickFoods
              .where((f) => _searchText.isEmpty ||
                  f.name.toLowerCase().contains(_searchText))
              .take(40)
              .map((food) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(food.name, style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 13)),
                subtitle: Text(
                  '💪 ${food.proteinG}g  🍚 ${food.carbsG}g  🥑 ${food.fatG}g',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: muted)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${food.kcal}', style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                      fontSize: 14, color: AppColors.halalGreen)),
                  const Text(' kcal', style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 10,
                      color: AppColors.lightMuted)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await widget.onAdd(food.name, food.kcal,
                          food.proteinG, food.carbsG, food.fatG);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.sunnahGreen,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('+', style: TextStyle(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              )),
          ],
        ],
      )),
    );
  }

  Widget _buildAIResultCard(bool isAr, bool isDark, Color muted) {
    final r = _aiResult!;
    final name = isAr ? (r['name_ar'] ?? r['name_en'] ?? '') : (r['name_en'] ?? r['name_ar'] ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sunnahGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Cairo',
              fontWeight: FontWeight.w800, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: r['halal'] == true ? AppColors.halalGreen : AppColors.doubtOrange,
                borderRadius: BorderRadius.circular(20)),
            child: Text(r['halal'] == true
                ? (isAr ? '✓ حلال' : '✓ Halal')
                : (isAr ? '⚠️ راجع' : '⚠️ Check'),
                style: const TextStyle(fontFamily: 'Cairo',
                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(isAr ? 'لكل ${r['serving_size'] ?? '100g'}' : 'Per ${r['serving_size'] ?? '100g'}',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _nutritionBadge('🔥', '${(r['kcal'] ?? 0).round()}',
              isAr ? 'سعرة' : 'kcal', AppColors.haramRed),
          _nutritionBadge('💪', '${(r['protein_g'] ?? 0.0).toStringAsFixed(1)}g',
              isAr ? 'بروتين' : 'Protein', AppColors.halalGreen),
          _nutritionBadge('🍚', '${(r['carbs_g'] ?? 0.0).toStringAsFixed(1)}g',
              isAr ? 'كارب' : 'Carbs', AppColors.waterBlue),
          _nutritionBadge('🥑', '${(r['fat_g'] ?? 0.0).toStringAsFixed(1)}g',
              isAr ? 'دهون' : 'Fat', AppColors.barakahGold),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _fillFromAI,
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: Text(isAr ? 'أضف هذا الطعام' : 'Add This Food',
              style: const TextStyle(fontFamily: 'Cairo',
                  color: Colors.white, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunnahGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      ]),
    );
  }

  Widget _nutritionBadge(String emoji, String val, String label, Color color) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      Text(val, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontFamily: 'Cairo',
          fontSize: 9, color: color.withOpacity(0.8))),
    ]);

  Widget _tabBtn(String label, int idx) => Expanded(child: GestureDetector(
    onTap: () => setState(() => _tab = idx),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _tab == idx ? AppColors.sunnahGreen : AppColors.sunnahGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _tab == idx ? Colors.white : AppColors.sunnahGreen)),
    ),
  ));

  Widget _numField(TextEditingController ctrl, String label) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textDirection: TextDirection.ltr,
    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
  );
}
