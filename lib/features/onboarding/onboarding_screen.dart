// onboarding_screen.dart — HalalCalorie v1.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../data/models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _lang   = 'ar';
  String _gender = 'brothers';
  int    _age    = 25;
  double _height = 170;
  double _weight = 70;
  double? _waist;
  double? _targetWeight;
  ActivityLevel   _activity = ActivityLevel.lightlyActive;
  FitnessGoal     _goal     = FitnessGoal.improveHealth;
  DietPreference  _diet     = DietPreference.halalOnly;
  int    _meals  = 3;
  double _sleep  = 7;
  BodyFrame _frame = BodyFrame.medium;
  List<HealthCondition> _conditions = [HealthCondition.none];

  final _ageCtrl    = TextEditingController(text: '25');
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');
  final _waistCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();

  bool get _isAr => _lang == 'ar';
  String t(String ar, String en) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final done = ref.read(onboardingDoneProvider);
      if (done && mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _ageCtrl.dispose(); _heightCtrl.dispose(); _weightCtrl.dispose();
    _waistCtrl.dispose(); _targetCtrl.dispose();
    super.dispose();
  }

  void _next() { if (!mounted) return; setState(() => _step++); }
  void _back() { if (_step == 0 || !mounted) return; setState(() => _step--); }

  Future<void> _finish() async {
    await ref.read(languageProvider.notifier).set(_lang);
    await ref.read(genderProvider.notifier).set(_gender);
    final profile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      gender: _gender, age: _age, heightCm: _height, weightKg: _weight,
      waistCm: _waist, activityLevel: _activity, primaryGoal: _goal,
      dietPreference: _diet, healthConditions: _conditions, mealsPerDay: _meals,
      sleepHours: _sleep, bodyFrame: _frame, targetWeightKg: _targetWeight,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    await ref.read(userProfileProvider.notifier).save(profile);
    await ref.read(onboardingDoneProvider.notifier).complete();
    ref.read(caloriesProvider.notifier).syncWithProfile(profile);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.sunnahGreen,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:  return _stepLanguage();
      case 1:  return _stepWelcome();
      case 2:  return _stepGender();
      case 3:  return _stepAge();
      case 4:  return _stepHeight();
      case 5:  return _stepWeight();
      case 6:  return _stepActivity();
      case 7:  return _stepGoal();
      case 8:  return _stepDiet();
      case 9:  return _stepMealsAndSleep();
      case 10: return _stepBodyFrame();
      case 11: return _stepHealthConds();
      case 12: return _stepOptional();
      case 13: return _stepThankYou();
      default: return _stepThankYou();
    }
  }

  Widget _progress() {
    if (_step <= 2) return const SizedBox.shrink();
    final pct = ((_step - 3) / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t('السؤال ${_step - 2} من 10', 'Question ${_step - 2} of 10'),
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
          Text('${(pct * 100).toInt()}%',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: pct, backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(AppColors.barakahGold),
            borderRadius: BorderRadius.circular(4), minHeight: 5),
      ]),
    );
  }

  Widget _btn(String label, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.barakahGold,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
  );

  Widget _qWrap({required String emoji, required String titleAr, required String titleEn,
      required Widget child, bool canGoBack = true, String? nextLabel, VoidCallback? onNext}) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (canGoBack && _step > 0)
          GestureDetector(onTap: _back, child: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20)),
        const SizedBox(height: 8),
        _progress(),
        Text(emoji, style: const TextStyle(fontSize: 52), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        Text(_isAr ? titleAr : titleEn, textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4)),
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(child: child)),
        const SizedBox(height: 20),
        _btn(nextLabel ?? t('التالي ←', 'Next →'), onNext ?? _next),
      ]),
    ));
  }

  // STEP 0: Language
  Widget _stepLanguage() {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/logo.png', height: 120,
            errorBuilder: (_, __, ___) => const Text('🕌', style: TextStyle(fontSize: 72))),
        const SizedBox(height: 16),
        const Text('HalalCalorie\nHalalCalorie', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4)),
        const SizedBox(height: 8),
        const Text('حلال في كل لقمة • Halal in every bite', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.white70)),
        const SizedBox(height: 48),
        const Text('اختر اللغة / Choose Language', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _langBtn('🇸🇦', 'العربية', 'ar')),
          const SizedBox(width: 14),
          Expanded(child: _langBtn('🇬🇧', 'English', 'en')),
        ]),
        const SizedBox(height: 24),
        _btn(t('متابعة ←', 'Continue →'), _next),
      ]),
    ));
  }

  Widget _langBtn(String flag, String label, String code) {
    final sel = _lang == code;
    return GestureDetector(
      onTap: () => setState(() => _lang = code),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: sel ? AppColors.barakahGold : Colors.white.withOpacity(0.15),
          border: Border.all(color: sel ? AppColors.barakahGold : Colors.white38, width: 2),
          borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700,
              color: sel ? Colors.white : Colors.white70)),
        ]),
      ),
    );
  }

  // STEP 1: Welcome
  Widget _stepWelcome() {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('🌿', style: TextStyle(fontSize: 72), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(t('بِسْمِ اللَّهِ\nأهلاً بك في HalalCalorie', 'In the name of Allah\nWelcome to HalalCalorie'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.5)),
        const SizedBox(height: 20),
        Text(t('سنساعدك على:\n✓ تتبع تغذيتك الحلال\n✓ حساب مقاييس جسمك\n✓ برامج لياقة سنية\n✓ مقالات صحية إسلامية\n\nجميع بياناتك مشفّرة وخاصة تماماً.',
            'We will help you:\n✓ Track your halal nutrition\n✓ Calculate body metrics\n✓ Sunnah fitness programs\n✓ Islamic health articles\n\nAll your data is fully encrypted & private.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.white70, height: 1.8)),
        const SizedBox(height: 48),
        _btn(t('ابدأ رحلتك ✨', 'Start Your Journey ✨'), _next),
      ]),
    ));
  }

  // STEP 2: Gender
  Widget _stepGender() {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(onTap: _back, child: const Icon(Icons.arrow_back_ios, color: Colors.white70)),
        const SizedBox(height: 20),
        Text(t('اختر طريقك', 'Choose Your Path'), textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text(t('هذا الاختيار دائم لضمان الخصوصية الكاملة', 'This choice is permanent to ensure full privacy'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 36),
        _genderBtn('🧔', t('للرجال — Brothers', 'Brothers — للرجال'), 'brothers', AppColors.sunnahGreen),
        const SizedBox(height: 16),
        _genderBtn('🧕', t('للنساء — Sisters', 'Sisters — للنساء'), 'sisters', AppColors.barakahGold),
        const SizedBox(height: 16),
        Text(t('⚠️ لا يمكن تغيير هذا الاختيار', '⚠️ This choice cannot be changed'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 24),
        _btn(t('متابعة ←', 'Continue →'), _next),
      ]),
    ));
  }

  Widget _genderBtn(String emoji, String label, String code, Color color) {
    final sel = _gender == code;
    return GestureDetector(
      onTap: () => setState(() => _gender = code),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          border: Border.all(color: sel ? color : Colors.white30, width: sel ? 2.5 : 1.5),
          borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 18,
              fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.white70))),
          if (sel) const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ]),
      ),
    );
  }

  // STEP 3: Age
  Widget _stepAge() => _qWrap(emoji: '🎂', titleAr: 'كم عمرك؟', titleEn: 'How old are you?',
    child: Column(children: [
      _whiteCard(TextField(controller: _ageCtrl, keyboardType: TextInputType.number,
        textAlign: TextAlign.center, textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen),
        decoration: InputDecoration(hintText: '25', hintStyle: const TextStyle(color: Colors.grey), border: InputBorder.none,
            suffix: Text(t('سنة', 'years'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey))),
        onChanged: (v) => _age = int.tryParse(v) ?? 25)),
      const SizedBox(height: 14),
      _sliderRow(value: _age.toDouble(), min: 10, max: 90,
        onChanged: (v) { setState(() { _age = v.toInt(); _ageCtrl.text = '$_age'; }); },
        label: '$_age ${t("سنة", "yrs")}', color: AppColors.sunnahGreen),
    ]),
    onNext: () { _age = int.tryParse(_ageCtrl.text) ?? 25; _next(); });

  // STEP 4: Height
  Widget _stepHeight() => _qWrap(emoji: '📏', titleAr: 'ما طولك؟ (سم)', titleEn: 'Height? (cm)',
    child: Column(children: [
      _whiteCard(TextField(controller: _heightCtrl, keyboardType: TextInputType.number,
        textAlign: TextAlign.center, textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen),
        decoration: const InputDecoration(hintText: '170', border: InputBorder.none,
            suffix: Text('cm', style: TextStyle(color: Colors.grey))),
        onChanged: (v) => _height = double.tryParse(v) ?? 170)),
      const SizedBox(height: 14),
      _sliderRow(value: _height, min: 120, max: 220,
        onChanged: (v) { setState(() { _height = v; _heightCtrl.text = v.toInt().toString(); }); },
        label: '${_height.toInt()} cm', color: AppColors.waterBlue),
    ]),
    onNext: () { _height = double.tryParse(_heightCtrl.text) ?? 170; _next(); });

  // STEP 5: Weight
  Widget _stepWeight() => _qWrap(emoji: '⚖️', titleAr: 'وزنك الحالي؟ (كجم)', titleEn: 'Current weight? (kg)',
    child: Column(children: [
      _whiteCard(TextField(controller: _weightCtrl, keyboardType: TextInputType.number,
        textAlign: TextAlign.center, textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen),
        decoration: const InputDecoration(hintText: '70', border: InputBorder.none,
            suffix: Text('kg', style: TextStyle(color: Colors.grey))),
        onChanged: (v) => _weight = double.tryParse(v) ?? 70)),
      const SizedBox(height: 14),
      _sliderRow(value: _weight, min: 30, max: 200,
        onChanged: (v) { setState(() { _weight = double.parse(v.toStringAsFixed(1)); _weightCtrl.text = _weight.toStringAsFixed(1); }); },
        label: '${_weight.toStringAsFixed(1)} kg', color: AppColors.barakahGold),
    ]),
    onNext: () { _weight = double.tryParse(_weightCtrl.text) ?? 70; _next(); });

  // STEP 6: Activity
  Widget _stepActivity() => _qWrap(emoji: '🏃', titleAr: 'مستوى نشاطك اليومي؟', titleEn: 'Daily activity level?',
    child: Column(children: ActivityLevel.values.map((lvl) => _radioOption<ActivityLevel>(
      value: lvl, groupValue: _activity, emoji: lvl.emoji(),
      labelAr: lvl.nameAr(), labelEn: lvl.nameEn(),
      onChanged: (v) => setState(() => _activity = v!))).toList()));

  // STEP 7: Goal
  Widget _stepGoal() => _qWrap(emoji: '🎯', titleAr: 'ما هدفك الرئيسي؟', titleEn: 'Main goal?',
    child: Column(children: FitnessGoal.values.map((g) => _radioOption<FitnessGoal>(
      value: g, groupValue: _goal, emoji: g.emoji(),
      labelAr: g.nameAr(), labelEn: g.nameEn(),
      onChanged: (v) => setState(() => _goal = v!))).toList()));

  // STEP 8: Diet
  Widget _stepDiet() => _qWrap(emoji: '🥗', titleAr: 'تفضيلك الغذائي؟', titleEn: 'Dietary preference?',
    child: Column(children: DietPreference.values.map((d) => _radioOption<DietPreference>(
      value: d, groupValue: _diet, emoji: d == DietPreference.halalOnly ? "🥩" : d == DietPreference.vegetarianHalal ? "🥗" : d == DietPreference.sunnahDiet ? "🌿" : "🥦",
      labelAr: d.nameAr(), labelEn: d.nameEn(),
      onChanged: (v) => setState(() => _diet = v!))).toList()));

  // STEP 9: Meals & Sleep
  Widget _stepMealsAndSleep() => _qWrap(emoji: '🌙', titleAr: 'الوجبات والنوم', titleEn: 'Meals & Sleep',
    child: Column(children: [
      Text(t('كم وجبة يومياً؟', 'Meals per day?'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      _sliderRow(value: _meals.toDouble(), min: 1, max: 6,
        onChanged: (v) => setState(() => _meals = v.toInt()),
        label: '$_meals ${t("وجبات", "meals")}', color: AppColors.barakahGold),
      const SizedBox(height: 20),
      Text(t('كم ساعة نوم؟', 'Hours of sleep?'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      _sliderRow(value: _sleep, min: 3, max: 12,
        onChanged: (v) => setState(() => _sleep = double.parse(v.toStringAsFixed(1))),
        label: '${_sleep.toStringAsFixed(1)} ${t("ساعة", "hrs")}', color: AppColors.waterBlue),
    ]));

  // STEP 10: Body Frame
  Widget _stepBodyFrame() => _qWrap(emoji: '💪', titleAr: 'بنية جسمك؟', titleEn: 'Body frame?',
    child: Column(children: BodyFrame.values.map((f) => _radioOption<BodyFrame>(
      value: f, groupValue: _frame, emoji: f == BodyFrame.small ? "🔹" : f == BodyFrame.medium ? "🔷" : "🔶",
      labelAr: f.nameAr(), labelEn: f.nameEn(),
      onChanged: (v) => setState(() => _frame = v!))).toList()));

  // STEP 11: Health Conditions
  Widget _stepHealthConds() => _qWrap(emoji: '🏥', titleAr: 'حالات صحية؟', titleEn: 'Health conditions?',
    child: Column(children: HealthCondition.values.map((c) {
      final sel = _conditions.contains(c);
      return GestureDetector(
        onTap: () => setState(() {
          if (c == HealthCondition.none) { _conditions = [HealthCondition.none]; return; }
          _conditions.remove(HealthCondition.none);
          sel ? _conditions.remove(c) : _conditions.add(c);
          if (_conditions.isEmpty) _conditions = [HealthCondition.none];
        }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sel ? AppColors.barakahGold.withOpacity(0.3) : Colors.white12,
            border: Border.all(color: sel ? AppColors.barakahGold : Colors.white30),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text(c == HealthCondition.none ? '✅' : c == HealthCondition.diabetes ? '🩸' : c == HealthCondition.hypertension ? '💊' : c == HealthCondition.heartDisease ? '❤️' : c == HealthCondition.thyroid ? '🦋' : '⚕️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(_isAr ? c.nameAr() : c.nameEn(),
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 15))),
            if (sel) const Icon(Icons.check, color: Colors.white),
          ]),
        ),
      );
    }).toList()));

  // STEP 12: Optional
  Widget _stepOptional() => _qWrap(emoji: '📐', titleAr: 'معلومات اختيارية', titleEn: 'Optional info',
    child: Column(children: [
      _whiteCard(TextField(controller: _waistCtrl, keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, color: AppColors.sunnahGreen),
        decoration: InputDecoration(hintText: t('محيط الخصر (سم)', 'Waist (cm)'), border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey)),
        onChanged: (v) => _waist = double.tryParse(v))),
      const SizedBox(height: 12),
      _whiteCard(TextField(controller: _targetCtrl, keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, color: AppColors.sunnahGreen),
        decoration: InputDecoration(hintText: t('الوزن المستهدف (كجم)', 'Target weight (kg)'), border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey)),
        onChanged: (v) => _targetWeight = double.tryParse(v))),
    ]));

  // STEP 13: Thank You
  Widget _stepThankYou() {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('🎉', style: TextStyle(fontSize: 80), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(t('جزاك الله خيراً!\nكل شيء جاهز', 'JazakAllah Khayran!\nEverything is ready'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.5)),
        const SizedBox(height: 48),
        _btn(t('ادخل التطبيق 🌟', 'Enter App 🌟'), _finish),
      ]),
    ));
  }

  Widget _whiteCard(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child);

  Widget _sliderRow({required double value, required double min, required double max,
      required ValueChanged<double> onChanged, required String label, required Color color}) {
    return Column(children: [
      Slider(value: value.clamp(min, max), min: min, max: max,
          activeColor: color, inactiveColor: Colors.white24, onChanged: onChanged),
      Text(label, style: TextStyle(fontFamily: 'Cairo', color: color, fontSize: 16, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _radioOption<T>({required T value, required T groupValue, required String emoji,
      required String labelAr, required String labelEn, required ValueChanged<T?> onChanged}) {
    final sel = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.barakahGold.withOpacity(0.3) : Colors.white12,
          border: Border.all(color: sel ? AppColors.barakahGold : Colors.white30),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(_isAr ? labelAr : labelEn,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 15))),
          if (sel) const Icon(Icons.check_circle, color: AppColors.barakahGold, size: 20),
        ]),
      ),
    );
  }
}
