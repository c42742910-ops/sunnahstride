// ============================================================
//  onboarding_screen.dart — SunnahStride v1.0
//  Flow: Language → Welcome → Gender → 10 Personal Questions → شكراً
// ============================================================
import 'package:flutter/material.dart'; import'package:flutter_riverpod/flutter_riverpod.dart'; import'package:go_router/go_router.dart'; import'../../core/theme.dart'; import'../../core/providers.dart'; import'../../data/models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {

  // ── Step index ─────────────────────────────────────────────
  // 0=Language, 1=Welcome, 2=Gender, 3-12=Questions, 13=Thank You
  int _step = 0;
  static const int _totalSteps = 14;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Answers collected ────────────────────────────────────── String _lang   ='ar'; String _gender ='brothers';
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

  // ── Text controllers ─────────────────────────────────────── final _ageCtrl    = TextEditingController(text:'25'); final _heightCtrl = TextEditingController(text:'170'); final _weightCtrl = TextEditingController(text:'70');
  final _waistCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();

  // ── Translations ─────────────────────────────────────────── bool get _isAr => _lang =='ar';
  String t(String ar, String en) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    // Check if already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final done = ref.read(onboardingDoneProvider); if (done) context.go('/home');
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ageCtrl.dispose(); _heightCtrl.dispose(); _weightCtrl.dispose();
    _waistCtrl.dispose(); _targetCtrl.dispose();
    super.dispose();
  }

  void _next() {
    _animCtrl.reverse().then((_) {
      setState(() => _step++);
      _animCtrl.forward();
    });
  }

  void _back() {
    if (_step == 0) return;
    _animCtrl.reverse().then((_) {
      setState(() => _step--);
      _animCtrl.forward();
    });
  }

  Future<void> _finish() async {
    // Save language
    await ref.read(languageProvider.notifier).set(_lang);
    // Save gender
    await ref.read(genderProvider.notifier).set(_gender);

    // Build & save profile
    final profile = UserProfile( id:'user_${DateTime.now().millisecondsSinceEpoch}',
      gender: _gender,
      age: _age,
      heightCm: _height,
      weightKg: _weight,
      waistCm: _waist,
      activityLevel: _activity,
      primaryGoal: _goal,
      dietPreference: _diet,
      healthConditions: _conditions,
      mealsPerDay: _meals,
      sleepHours: _sleep,
      bodyFrame: _frame,
      targetWeightKg: _targetWeight,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(userProfileProvider.notifier).save(profile);
    await ref.read(onboardingDoneProvider.notifier).complete();

    // Sync calorie goal
    ref.read(caloriesProvider.notifier).syncWithProfile(profile); if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.sunnahGreen,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: _buildStep(),
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

  // ── Progress bar ─────────────────────────────────────────
  Widget _progress() {
    if (_step <= 2) return const SizedBox.shrink();
    final pct = ((_step - 3) / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(t('السؤال ${_step - 2} من 10', 'Question ${_step - 2} of 10'), style: const TextStyle(fontFamily:'Cairo', color: Colors.white70, fontSize: 12)), Text('${(pct * 100).toInt()}%', style: const TextStyle(fontFamily:'Cairo', color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(AppColors.barakahGold),
          borderRadius: BorderRadius.circular(4),
          minHeight: 5,
        ),
      ]),
    );
  }

  // ── Wrapper used by all question steps ───────────────────
  Widget _qWrap({
    required String emoji,
    required String titleAr,
    required String titleEn,
    required Widget child,
    bool canGoBack = true,
    String? nextLabel,
    VoidCallback? onNext,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canGoBack && _step > 0)
              GestureDetector(
                onTap: _back,
                child: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
              ),
            const SizedBox(height: 8),
            _progress(),
            Text(emoji, style: const TextStyle(fontSize: 52), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text(
              _isAr ? titleAr : titleEn,
              textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: child)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onNext ?? _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.barakahGold,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ), child: Text(nextLabel ?? t('التالي ←', 'Next →'), style: const TextStyle(fontFamily:'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 0: Language ─────────────────────────────────────
  Widget _stepLanguage() {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const Text('🕌', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16), const Text('سنة سترايد\nSunnahStride',
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4)),
        const SizedBox(height: 8), const Text('حلال في كل لقمة • Halal in every bite',
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 15, color: Colors.white70, height: 1.6)),
        const SizedBox(height: 48), const Text('اختر اللغة / Choose Language',
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 16, color: Colors.white)),
        const SizedBox(height: 20),
        Row(children: [ Expanded(child: _langBtn('🇸🇦', 'العربية', 'ar')),
          const SizedBox(width: 14), Expanded(child: _langBtn('🇬🇧', 'English', 'en')),
        ]),
      ]),
    ));
  }

  Widget _langBtn(String flag, String label, String code) {
    final sel = _lang == code;
    return GestureDetector(
      onTap: () => setState(() { _lang = code; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: sel ? AppColors.barakahGold : Colors.white.withOpacity(0.15),
          border: Border.all(color: sel ? AppColors.barakahGold : Colors.white38, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6), Text(label, style: TextStyle(fontFamily:'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.white70)),
        ]),
      ),
    );
  }

  // ── STEP 1: Welcome ──────────────────────────────────────
  Widget _stepWelcome() {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [ const Text('🌿', style: TextStyle(fontSize: 72), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text( t('بِسْمِ اللَّهِ\nأهلاً بك في سنة سترايد', 'In the name of Allah\nWelcome to SunnahStride'),
          textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.5),
        ),
        const SizedBox(height: 20),
        Text(
          t( 'سنساعدك على:\n✓ تتبع تغذيتك الحلال\n✓ حساب مقاييس جسمك\n✓ برامج لياقة سنية\n✓ مقالات صحية إسلامية\n\nجميع بياناتك مشفّرة وخاصة تماماً.', 'We will help you:\n✓ Track your halal nutrition\n✓ Calculate body metrics\n✓ Sunnah fitness programs\n✓ Islamic health articles\n\nAll your data is fully encrypted & private.',
          ),
          textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 15, color: Colors.white70, height: 1.8),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.barakahGold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(t('ابدأ رحلتك ✨', 'Start Your Journey ✨'), style: const TextStyle(fontFamily:'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    ));
  }

  // ── STEP 2: Gender ───────────────────────────────────────
  Widget _stepGender() {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(onTap: _back, child: const Icon(Icons.arrow_back_ios, color: Colors.white70)),
        const SizedBox(height: 20), Text(t('اختر طريقك', 'Choose Your Path'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8), Text(t('هذا الاختيار دائم لضمان الخصوصية الكاملة', 'This choice is permanent to ensure full privacy'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 36), _genderBtn('🧔', t('إخواني — Brothers', 'Brothers — إخواني'), 'brothers', AppColors.sunnahGreen),
        const SizedBox(height: 16), _genderBtn('🧕', t('أخواتي — Sisters', 'Sisters — أخواتي'), 'sisters', AppColors.barakahGold),
        const SizedBox(height: 28), Text(t('⚠️ لا يمكن تغيير هذا الاختيار', '⚠️ This choice cannot be changed'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 11, color: Colors.white60)),
      ]),
    ));
  }

  Widget _genderBtn(String emoji, String label, String code, Color color) {
    final sel = _gender == code;
    return GestureDetector(
      onTap: () => setState(() { _gender = code; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          border: Border.all(color: sel ? color : Colors.white30, width: sel ? 2.5 : 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16), Expanded(child: Text(label, style: TextStyle(fontFamily:'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.white70))),
          if (sel) const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ]),
      ),
    );
  }

  // ── STEP 3: Age ──────────────────────────────────────────
  Widget _stepAge() {
    return _qWrap( emoji:'🎂', titleAr:'كم عمرك؟', titleEn:'How old are you?',
      child: Column(children: [
        _whiteCard(TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr, style: const TextStyle(fontFamily:'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen),
          decoration: InputDecoration( hintText:'25',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none, suffix: Text(t('سنة', 'years'), style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey)),
          ),
          onChanged: (v) => _age = int.tryParse(v) ?? 25,
        )),
        const SizedBox(height: 14),
        _sliderRow(
          value: _age.toDouble(),
          min: 10, max: 90, onChanged: (v) { setState(() { _age = v.toInt(); _ageCtrl.text ='$_age'; }); }, label:'$_age ${t("سنة", "yrs")}',
          color: AppColors.sunnahGreen,
        ),
        const SizedBox(height: 14), Text(t('نستخدم عمرك لحساب احتياجاتك الدقيقة', 'We use your age to calculate your precise needs'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 12, color: Colors.white70)),
      ]),
      onNext: () { _age = int.tryParse(_ageCtrl.text) ?? 25; _next(); },
    );
  }

  // ── STEP 4: Height ───────────────────────────────────────
  Widget _stepHeight() {
    return _qWrap( emoji:'📏', titleAr:'ما طولك؟ (بالسنتيمتر)', titleEn:'What is your height? (cm)',
      child: Column(children: [
        _whiteCard(TextField(
          controller: _heightCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr, style: const TextStyle(fontFamily:'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen),
          decoration: InputDecoration( hintText:'170',
            border: InputBorder.none, suffix: Text('cm', style: const TextStyle(color: Colors.grey)),
          ),
          onChanged: (v) => _height = double.tryParse(v) ?? 170,
        )),
        const SizedBox(height: 14),
        _sliderRow(
          value: _height,
          min: 120, max: 220,
          onChanged: (v) { setState(() { _height = v; _heightCtrl.text = v.toInt().toString(); }); }, label:'${_height.toInt()} cm',
          color: AppColors.waterBlue,
        ),
      ]),
      onNext: () { _height = double.tryParse(_heightCtrl.text) ?? 170; _next(); },
    );
  }

  // ── STEP 5: Weight ───────────────────────────────────────
  Widget _stepWeight() {
    return _qWrap( emoji:'⚖️', titleAr:'ما وزنك الحالي؟ (كجم)', titleEn:'What is your current weight? (kg)',
      child: Column(children: [
        _whiteCard(TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr, style: const TextStyle(fontFamily:'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunnahGreen), decoration: InputDecoration(hintText:'70', border: InputBorder.none, suffix: Text('kg', style: const TextStyle(color: Colors.grey))),
          onChanged: (v) => _weight = double.tryParse(v) ?? 70,
        )),
        const SizedBox(height: 14),
        _sliderRow(
          value: _weight,
          min: 30, max: 200,
          onChanged: (v) { setState(() { _weight = double.parse(v.toStringAsFixed(1)); _weightCtrl.text = _weight.toStringAsFixed(1); }); }, label:'${_weight.toStringAsFixed(1)} kg',
          color: AppColors.barakahGold,
        ),
        const SizedBox(height: 14),
        // Live BMI preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
          child: Builder(builder: (_) {
            final h = _height / 100;
            final bmi = h > 0 ? _weight / (h * h) : 0.0; final cat = bmi < 18.5 ? t('نقص وزن','Underweight') : bmi < 25 ? t('مثالي ✓','Normal ✓') : bmi < 30 ? t('زيادة','Overweight') : t('سمنة','Obese');
            final col = bmi < 18.5 ? AppColors.waterBlue : bmi < 25 ? AppColors.halalGreen : bmi < 30 ? AppColors.doubtOrange : AppColors.haramRed;
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Text(t('BMI الآن: ', 'BMI now: '), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)), Text(bmi.toStringAsFixed(1), style: TextStyle(fontFamily:'Cairo', fontWeight: FontWeight.w900, fontSize: 18, color: col)),
              const SizedBox(width: 8), Text(cat, style: TextStyle(fontFamily:'Cairo', fontSize: 13, color: col)),
            ]);
          }),
        ),
      ]),
      onNext: () { _weight = double.tryParse(_weightCtrl.text) ?? 70; _next(); },
    );
  }

  // ── STEP 6: Activity Level ───────────────────────────────
  Widget _stepActivity() {
    return _qWrap( emoji:'🏃', titleAr:'مستوى نشاطك اليومي؟', titleEn:'What is your daily activity level?',
      child: Column(
        children: ActivityLevel.values.map((lvl) => _radioOption<ActivityLevel>(
          value: lvl, groupValue: _activity,
          emoji: lvl.emoji(),
          labelAr: lvl.nameAr(), labelEn: lvl.nameEn(),
          onTap: () => setState(() => _activity = lvl),
        )).toList(),
      ),
    );
  }

  // ── STEP 7: Goal ─────────────────────────────────────────
  Widget _stepGoal() {
    return _qWrap( emoji:'🎯', titleAr:'ما هدفك الرئيسي؟', titleEn:'What is your primary goal?',
      child: Column(
        children: FitnessGoal.values.map((g) => _radioOption<FitnessGoal>(
          value: g, groupValue: _goal,
          emoji: g.emoji(),
          labelAr: g.nameAr(), labelEn: g.nameEn(),
          onTap: () => setState(() => _goal = g),
        )).toList(),
      ),
    );
  }

  // ── STEP 8: Diet Preference ──────────────────────────────
  Widget _stepDiet() {
    return _qWrap( emoji:'🌿', titleAr:'تفضيلاتك الغذائية؟', titleEn:'Your dietary preferences?',
      child: Column(
        children: DietPreference.values.map((d) => _radioOption<DietPreference>(
          value: d, groupValue: _diet, emoji:'🥗',
          labelAr: d.nameAr(), labelEn: d.nameEn(),
          onTap: () => setState(() => _diet = d),
        )).toList(),
      ),
    );
  }

  // ── STEP 9: Meals & Sleep ────────────────────────────────
  Widget _stepMealsAndSleep() {
    return _qWrap( emoji:'🍽️', titleAr:'كم وجبة وكم ساعة نوم؟', titleEn:'How many meals & sleep hours?',
      child: Column(children: [ Text(t('الوجبات اليومية', 'Daily Meals'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        _sliderRow(value: _meals.toDouble(), min: 1, max: 6, divisions: 5,
          onChanged: (v) => setState(() => _meals = v.toInt()), label:'$_meals ${t("وجبات", "meals")}',
          color: AppColors.halalGreen,
        ),
        const SizedBox(height: 20), Text(t('ساعات النوم عادةً', 'Usual Sleep Hours'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        _sliderRow(value: _sleep, min: 4, max: 12, divisions: 8,
          onChanged: (v) => setState(() => _sleep = double.parse(v.toStringAsFixed(1))), label:'${_sleep.toStringAsFixed(0)} ${t("ساعة", "hrs")}',
          color: AppColors.sleepPurple,
        ),
        const SizedBox(height: 14), _infoBox(t('النوم الكافي (7-8 ساعات) يُحسّن الأيض ويُساعد على خسارة الوزن', 'Adequate sleep (7-8 hrs) improves metabolism & aids weight loss')),
      ]),
    );
  }

  // ── STEP 10: Body Frame ──────────────────────────────────
  Widget _stepBodyFrame() {
    return _qWrap( emoji:'🦴', titleAr:'حجم بنيتك الجسمية (معصمك)؟', titleEn:'Your body frame size (wrist)?',
      child: Column(children: [ _infoBox(t('قِس محيط معصمك لتحديد إطار جسمك', 'Measure your wrist to determine body frame')),
        const SizedBox(height: 16),
        ...BodyFrame.values.map((f) => _radioOption<BodyFrame>(
          value: f, groupValue: _frame, emoji: f == BodyFrame.small ?'🤏' : f == BodyFrame.medium ? '✋' : '🤚',
          labelAr: f.nameAr(), labelEn: f.nameEn(),
          onTap: () => setState(() => _frame = f),
        )),
      ]),
    );
  }

  // ── STEP 11: Health Conditions ───────────────────────────
  Widget _stepHealthConds() {
    return _qWrap( emoji:'🏥', titleAr:'هل لديك حالات صحية؟ (اختياري)', titleEn:'Any health conditions? (optional)',
      child: Column(children: [ _infoBox(t('نستخدم هذه المعلومات لتخصيص توصياتك الصحية فقط', 'We use this info only to personalize your health recommendations')),
        const SizedBox(height: 14),
        ...HealthCondition.values.map((cond) {
          final sel = _conditions.contains(cond);
          return GestureDetector(
            onTap: () => setState(() {
              if (cond == HealthCondition.none) {
                _conditions = [HealthCondition.none];
              } else {
                _conditions.remove(HealthCondition.none);
                if (sel) {
                  _conditions.remove(cond);
                  if (_conditions.isEmpty) _conditions = [HealthCondition.none];
                } else {
                  _conditions.add(cond);
                }
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                border: Border.all(color: sel ? Colors.white : Colors.white30, width: sel ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(sel ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(_isAr ? cond.nameAr() : cond.nameEn(), style: const TextStyle(fontFamily:'Cairo', color: Colors.white, fontSize: 14)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // ── STEP 12: Optional Data ───────────────────────────────
  Widget _stepOptional() {
    return _qWrap( emoji:'📐', titleAr:'معلومات إضافية (اختيارية)', titleEn:'Additional Info (optional)', nextLabel: t('تم ✓', 'Done ✓'),
      child: Column(children: [ _infoBox(t('هذه المعلومات تزيد دقة حساباتك بشكل كبير', 'This info greatly increases the accuracy of your calculations')),
        const SizedBox(height: 16),
        // Waist Text(t('محيط الخصر (سم)', 'Waist Circumference (cm)'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        _whiteCard(TextField(
          controller: _waistCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr, style: const TextStyle(fontFamily:'Cairo', fontSize: 22, color: AppColors.sunnahGreen), decoration: InputDecoration(hintText: t('اختياري', 'Optional'), border: InputBorder.none, suffix: const Text('cm', style: TextStyle(color: Colors.grey))),
          onChanged: (v) => _waist = double.tryParse(v),
        )),
        const SizedBox(height: 16),
        // Target weight Text(t('وزنك المستهدف (كجم)', 'Target Weight (kg)'), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        _whiteCard(TextField(
          controller: _targetCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr, style: const TextStyle(fontFamily:'Cairo', fontSize: 22, color: AppColors.sunnahGreen), decoration: InputDecoration(hintText: t('اختياري', 'Optional'), border: InputBorder.none, suffix: const Text('kg', style: TextStyle(color: Colors.grey))),
          onChanged: (v) => _targetWeight = double.tryParse(v),
        )),
      ]),
      onNext: () {
        _waist = double.tryParse(_waistCtrl.text);
        _targetWeight = double.tryParse(_targetCtrl.text);
        _next();
      },
    );
  }

  // ── STEP 13: Thank You ───────────────────────────────────
  Widget _stepThankYou() {
    // Calculate profile preview
    final h = _height / 100;
    final bmi = h > 0 ? _weight / (h * h) : 0.0; final bmr = _gender =='brothers'? 10 * _weight + 6.25 * _height - 5 * _age + 5
        : 10 * _weight + 6.25 * _height - 5 * _age - 161;
    final tdee = bmr * _activity.multiplier;
    final cGoal = (tdee + _goal.calorieAdjustment).clamp(1200, 4000);

    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [ const Text('🤲', style: TextStyle(fontSize: 72), textAlign: TextAlign.center),
        const SizedBox(height: 16), const Text('شُكراً لك\nThank You',
            textAlign: TextAlign.center, style: TextStyle(fontFamily:'Cairo', fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4)),
        const SizedBox(height: 8), Text(t('بارك الله فيك! تم تخصيص تجربتك الكاملة', 'May Allah bless you! Your experience is fully personalized'),
            textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', fontSize: 14, color: Colors.white70, height: 1.6)),
        const SizedBox(height: 28),
        // Summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
          child: Column(children: [ _summaryRow('⚖️', 'BMI', bmi.toStringAsFixed(1)), _summaryRow('🔥', t('هدف السعرات', 'Calorie Goal'), '${cGoal.toInt()} kcal/${t("يوم","day")}'), _summaryRow('🏃', t('النشاط', 'Activity'), _isAr ? _activity.nameAr() : _activity.nameEn()), _summaryRow('🎯', t('الهدف', 'Goal'), _isAr ? _goal.nameAr() : _goal.nameEn()),
          ]),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _finish,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.barakahGold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(t('ابدأ رحلتك ✨', 'Start Your Journey ✨'), style: const TextStyle(fontFamily:'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    ));
  }

  Widget _summaryRow(String emoji, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child:
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontFamily:'Cairo', color: Colors.white70, fontSize: 13))), Text(value, style: const TextStyle(fontFamily:'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }

  // ── Reusable Widgets ─────────────────────────────────────
  Widget _whiteCard(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _sliderRow({required double value, required double min, required double max,
      int? divisions, required ValueChanged<double> onChanged, required String label, required Color color}) {
    return Column(children: [ Text(label, style: TextStyle(fontFamily:'Cairo', fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Slider(
        value: value, min: min, max: max, divisions: divisions ?? (max - min).toInt(),
        activeColor: color, inactiveColor: Colors.white24,
        onChanged: onChanged,
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('${min.toInt()}', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 11)), Text('${max.toInt()}', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 11)),
      ]),
    ]);
  }

  Widget _radioOption<T>({required T value, required T groupValue, required String emoji,
      required String labelAr, required String labelEn, required VoidCallback onTap}) {
    final sel = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.08),
          border: Border.all(color: sel ? AppColors.barakahGold : Colors.white30, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12), Expanded(child: Text(_isAr ? labelAr : labelEn, style: TextStyle(fontFamily:'Cairo', fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: Colors.white))),
          if (sel) const Icon(Icons.radio_button_checked, color: AppColors.barakahGold, size: 20)
          else const Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 20),
        ]),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily:'Cairo', color: Colors.white70, fontSize: 12, height: 1.5)),
    );
  }
}
