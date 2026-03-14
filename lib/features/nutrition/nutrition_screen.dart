import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/ai_service.dart';
import '../../data/models/models.dart';
import '../../data/models/user_profile.dart';
import '../../core/providers.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionState();
}

class _NutritionState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _pCtrl    = TextEditingController();
  final _cCtrl    = TextEditingController();
  final _fCtrl    = TextEditingController();
  final _aiCtrl   = TextEditingController();
  String? _search;
  bool    _aiLoading = false;
  String? _aiResult;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose(); _kcalCtrl.dispose();
    _pCtrl.dispose(); _cCtrl.dispose(); _fCtrl.dispose();
    _aiCtrl.dispose();
    super.dispose();
  }

  String t(String ar, String en) {
    final lang = ref.read(languageProvider);
    return lang == 'ar' ? ar : en;
  }

  Future<void> _generatePlan() async {
    setState(() { _aiLoading = true; _aiResult = null; });
    final profile = ref.read(userProfileProvider);
    final lang    = ref.read(languageProvider);
    final isAr    = lang == 'ar';
    final goal    = profile?.calorieGoalKcal.toInt() ?? 2000;
    final diet    = profile != null
        ? (isAr ? profile.dietPreference.nameAr() : profile.dietPreference.nameEn())
        : (isAr ? 'حلال' : 'Halal');
    final goalStr = profile != null
        ? (isAr ? profile.primaryGoal.nameAr() : profile.primaryGoal.nameEn())
        : (isAr ? 'صحة عامة' : 'General health');
    final prompt = _aiCtrl.text.trim().isNotEmpty
        ? _aiCtrl.text.trim()
        : (isAr ? 'اقترح لي خطة وجبات يومية مفصلة' : 'Suggest a detailed daily meal plan for me');
    try {
      final response = await AIService.getMealSuggestion(
        prompt: prompt,
        calorieGoal: goal,
        dietType: diet,
        goal: goalStr,
        language: lang,
      );
      if (mounted) setState(() { _aiLoading = false; _aiResult = response; });
    } catch (_) {
      if (mounted) setState(() { _aiLoading = false; _aiResult = 'fallback'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang    = ref.watch(languageProvider);
    final isAr    = lang == 'ar';
    final isDark  = ref.watch(themeProvider);
    final profile = ref.watch(userProfileProvider);
    final cals    = ref.watch(caloriesProvider);
    final isPremium = ref.watch(premiumProvider);
    final bg      = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final cardBg  = isDark ? AppColors.darkCard  : AppColors.lightCard;
    final muted   = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textC   = isDark ? AppColors.darkText  : AppColors.lightText;
    String tl(String ar, String en) => isAr ? ar : en;

    final remaining = (profile?.calorieGoalKcal.toInt() ?? 2000) - cals.totalKcal;
    final calCol = remaining < 0 ? AppColors.haramRed
        : remaining < 200 ? AppColors.barakahGold : AppColors.sunnahGreen;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(tl('التغذية', 'Nutrition'),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.sunnahGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: tl('اليوم', 'Today')),
              Tab(text: tl('الوصفات', 'Recipes')),
              Tab(text: tl('AI مخطط', 'AI Planner')),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildTodayTab(isAr, isDark, bg, cardBg, muted, textC, cals, profile, calCol, isPremium),
            _buildRecipesTab(isAr, isDark, bg, cardBg, muted),
            _buildAITab(isAr, isDark, bg, cardBg, muted, profile, isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(bool isAr, bool isDark, Color bg, Color cardBg, Color muted, Color textC,
      CaloriesState cals, UserProfile? profile, Color calCol, bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;
    final goal = profile?.calorieGoalKcal.toInt() ?? 2000;
    final pct  = (cals.totalKcal / goal).clamp(0.0, 1.0);

    return ListView(padding: const EdgeInsets.all(14), children: [
      if (profile != null) Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Text(
          isAr
            ? '🤖 AI يعرف: وزنك ${profile.weightKg}كجم • هدفك: ${profile.primaryGoal.nameAr()} • سعراتك: ${profile.calorieGoalKcal.toInt()}'
            : '🤖 AI knows: ${profile.weightKg}kg • Goal: ${profile.primaryGoal.nameEn()} • Calories: ${profile.calorieGoalKcal.toInt()}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.sunnahGreen),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tl('السعرات اليوم', "Today's Calories"),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: muted)),
              Text('${cals.totalKcal}',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: calCol)),
              Text('/ $goal ${tl("سعرة", "kcal")}',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
            ]),
            const Spacer(),
            SizedBox(width: 70, height: 70,
              child: CircularProgressIndicator(value: pct, strokeWidth: 8,
                color: calCol, backgroundColor: calCol.withOpacity(0.15))),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: pct, minHeight: 8, color: calCol,
              backgroundColor: calCol.withOpacity(0.12))),
          const SizedBox(height: 10),
          Row(children: [
            _statPill(tl('بروتين', 'Protein'), '${cals.proteinTotal.toInt()}g', AppColors.halalGreen),
            const SizedBox(width: 8),
            _statPill(tl('كارب', 'Carbs'), '${cals.carbsTotal.toInt()}g', AppColors.waterBlue),
            const SizedBox(width: 8),
            _statPill(tl('دهون', 'Fat'), '${cals.fatTotal.toInt()}g', AppColors.barakahGold),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      _macroRingsCard(isAr, isDark, cardBg, muted, cals),
      const SizedBox(height: 14),
      _weeklyChart(isAr, isDark, cardBg, muted),
      const SizedBox(height: 14),
      _addMealSection(isAr, isDark, cardBg, muted, cals),
    ]);
  }

  Widget _buildRecipesTab(bool isAr, bool isDark, Color bg, Color cardBg, Color muted) {
    String tl(String ar, String en) => isAr ? ar : en;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text(tl('وصفات سنية صحية', 'Healthy Sunnah Recipes'),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 4),
      Text(tl('مستوحاة من السنة النبوية', 'Inspired by the Prophetic Sunnah'),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: muted)),
      const SizedBox(height: 14),
      ...kRecipes.map((r) => _recipeCard(r, isAr, isDark, cardBg, muted)),
    ]);
  }

  Widget _buildAITab(bool isAr, bool isDark, Color bg, Color cardBg, Color muted,
      UserProfile? profile, bool isPremium) {
    String tl(String ar, String en) => isAr ? ar : en;
    if (!isPremium) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🤖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(tl('مخطط الوجبات بالذكاء الاصطناعي', 'AI Meal Planner'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(tl('يُخصّص خطة وجبات كاملة بناءً على جسمك وأهدافك',
              'Creates a complete meal plan based on your body and goals'),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: muted, height: 1.7)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => context.push('/paywall'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.barakahGold,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(tl('🔓 افتح بريميوم', '🔓 Unlock Premium'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
        )),
      ])));
    }

    return ListView(padding: const EdgeInsets.all(14), children: [
      if (profile != null) Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Text(
          isAr
            ? '🤖 AI يعرف: وزنك ${profile.weightKg}كجم • هدفك: ${profile.primaryGoal.nameAr()} • سعراتك: ${profile.calorieGoalKcal.toInt()} • نظامك: ${profile.dietPreference.nameAr()}'
            : '🤖 AI knows: ${profile.weightKg}kg • Goal: ${profile.primaryGoal.nameEn()} • Calories: ${profile.calorieGoalKcal.toInt()} • Diet: ${profile.dietPreference.nameEn()}',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.sunnahGreen),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tl('اطلب خطة وجبات مخصصة:', 'Request a Personalized Meal Plan:'),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: _aiCtrl,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: InputDecoration(
              hintText: isAr ? 'مثال: خطة رمضان، بدون جلوتين...' : 'e.g. Ramadan plan, gluten-free...',
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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(tl('🤖 توليد خطة وجبات', '🤖 Generate Meal Plan'),
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
          )),
        ]),
      ),
      if (_aiResult != null) ...[
        const SizedBox(height: 14),
        _aiResult == 'fallback'
            ? Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Text('😔', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(isAr ? 'تعذّر الاتصال. حاول مجدداً.' : 'Could not connect. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: muted, height: 1.5)),
                ]))
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(tl('خطتك الشخصية', 'Your Personal Plan'),
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.sunnahGreen)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_aiResult!,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.7,
                          color: isDark ? AppColors.darkText : AppColors.lightText)),
                ])),
      ],
    ]);
  }

  Widget _statPill(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(val, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: color)),
      ]),
    );
  }

  Widget _macroRingsCard(bool isAr, bool isDark, Color cardBg, Color muted, CaloriesState cals) {
    String tl(String ar, String en) => isAr ? ar : en;
    final profile = ref.watch(userProfileProvider);
    if (profile == null) return const SizedBox.shrink();
    final carbGoal    = (profile.calorieGoalKcal / 4).toInt();
    final proteinGoal = profile.proteinGrams.toInt();
    final fatGoal     = (profile.calorieGoalKcal / 9 * 0.45).toInt();

    Widget ring(double val, double total, Color color, String label) {
      final pct = total > 0 ? (val / total).clamp(0.0, 1.0) : 0.0;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 56, height: 56,
          child: CircularProgressIndicator(value: pct, strokeWidth: 6, color: color,
            backgroundColor: color.withOpacity(0.15))),
        const SizedBox(height: 6),
        Text('${val.toInt()}/${total}g',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 9, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 8, color: muted)),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tl('المغذيات الكبرى', 'Macronutrients'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          ring(cals.proteinTotal, proteinGoal.toDouble(), AppColors.halalGreen, tl('بروتين', 'Protein')),
          ring(cals.carbsTotal, carbGoal.toDouble(), AppColors.waterBlue, tl('كارب', 'Carbs')),
          ring(cals.fatTotal, fatGoal.toDouble(), AppColors.barakahGold, tl('دهون', 'Fat')),
        ]),
      ]),
    );
  }

  Widget _weeklyChart(bool isAr, bool isDark, Color cardBg, Color muted) {
    String tl(String ar, String en) => isAr ? ar : en;
    final weekly = ref.watch(weeklyKcalProvider);
    final days = isAr
        ? ['أح', 'إث', 'ث', 'أر', 'خ', 'ج', 'س']
        : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tl('السعرات الأسبوعية', 'Weekly Calories'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 14),
        SizedBox(height: 120, child: weekly.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_,__) => const SizedBox.shrink(),
          data: (data) {
            final today = DateTime.now();
            final bars = List.generate(7, (i) {
              final d = today.subtract(Duration(days: 6 - i));
              final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final found = data.where((x) => x['date_key'] == key).toList();
              final kcal = found.isNotEmpty ? (found.first['total'] as int).toDouble() : 0.0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: kcal, color: AppColors.sunnahGreen, width: 14,
                    borderRadius: BorderRadius.circular(4))
              ]);
            });
            return BarChart(BarChartData(
              barGroups: bars,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) =>
                    Text(days[v.toInt()], style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: muted)))),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ));
          },
        )),
      ]),
    );
  }

  Widget _addMealSection(bool isAr, bool isDark, Color cardBg, Color muted, CaloriesState cals) {
    String tl(String ar, String en) => isAr ? ar : en;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tl('أضف وجبة', 'Add Meal'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 12),
        // Quick foods
        Text(tl('إضافة سريعة:', 'Quick add:'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12,
                color: AppColors.sunnahGreen)),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => _search = v.isEmpty ? null : v),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          decoration: InputDecoration(
            hintText: tl('ابحث عن طعام...', 'Search food...'),
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 80, child: ListView(scrollDirection: Axis.horizontal,
          children: kQuickFoods
            .where((f) => _search == null || f.name.toLowerCase().contains(_search!.toLowerCase()))
            .take(20)
            .map((food) => GestureDetector(
              onTap: () {
                ref.read(caloriesProvider.notifier).addEntry(
                  food.name, food.kcal, proteinG: food.proteinG, carbsG: food.carbsG, fatG: food.fatG);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${food.name} ${tl("أضيف!", "added!")}',
                      style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: AppColors.sunnahGreen,
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.sunnahGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sunnahGreen.withOpacity(0.2))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(food.name, style: const TextStyle(fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700, fontSize: 11)),
                  Text('${food.kcal} kcal', style: const TextStyle(fontFamily: 'Cairo',
                      fontSize: 9, color: AppColors.lightMuted)),
                ]),
              ),
            )).toList(),
        )),
        const SizedBox(height: 12),
        Text(tl('إدخال مخصص:', 'Custom entry:'),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12,
                color: AppColors.sunnahGreen)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          decoration: InputDecoration(
            labelText: tl('اسم الطعام', 'Food name'),
            border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _kcalCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: const InputDecoration(labelText: 'Kcal', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _pCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: const InputDecoration(labelText: 'P(g)', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _cCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: const InputDecoration(labelText: 'C(g)', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _fCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            decoration: const InputDecoration(labelText: 'F(g)', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final kcal = int.tryParse(_kcalCtrl.text) ?? 0;
            if (name.isEmpty || kcal == 0) return;
            final p = double.tryParse(_pCtrl.text) ?? 0;
            final c = double.tryParse(_cCtrl.text) ?? 0;
            final f = double.tryParse(_fCtrl.text) ?? 0;
            ref.read(caloriesProvider.notifier).addEntry(name, kcal, proteinG: p, carbsG: c, fatG: f);
            _nameCtrl.clear(); _kcalCtrl.clear();
            _pCtrl.clear(); _cCtrl.clear(); _fCtrl.clear();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunnahGreen,
              padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(tl('+ أضف', '+ Add'),
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        )),
        const SizedBox(height: 16),
        if (cals.entries.isNotEmpty) ...[
          Text(tl('سجل اليوم', "Today's Log"),
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 8),
          ...cals.entries.map((e) => ListTile(
            dense: true,
            title: Text(e.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            trailing: Text('${e.kcal} kcal',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                    fontSize: 12, color: AppColors.halalGreen)),
            onLongPress: () => ref.read(caloriesProvider.notifier).removeEntry(e.id),
          )),
        ],
      ]),
    );
  }

  Widget _recipeCard(Recipe r, bool isAr, bool isDark, Color cardBg, Color muted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(isAr ? r.nameAr : r.nameEn,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.halalGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${r.kcal} kcal',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10,
                    fontWeight: FontWeight.w700, color: AppColors.halalGreen))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('⏱ ${r.timeMins}${isAr ? " دقيقة" : " min"}',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: muted)),
          const SizedBox(width: 12),
          Text('🥩 ${r.proteinG}g  🍚 ${r.carbsG}g  🥑 ${r.fatG}g',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: muted)),
        ]),
      ]),
    );
  }

  String _timeStr(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
