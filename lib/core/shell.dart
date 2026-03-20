// shell.dart — HalalCalorie v1.0
// 5-tab bottom nav (Body merged under Health, accessible via Home quick actions)
import 'package:flutter/material.dart'; import'package:flutter_riverpod/flutter_riverpod.dart'; import'package:go_router/go_router.dart'; import'theme.dart'; import'providers.dart'; import'../data/models/user_profile.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [ _Tab('/home',      '🏠'), _Tab('/scanner',   '📷'), _Tab('/nutrition', '🌿'), _Tab('/fitness',   '🏃'), _Tab('/health',    '🩺'), _Tab('/body',      '💪'), _Tab('/profile',   '👤'),
  ];

  // 5 visible nav items → body is accessible from home/health
  static const _navTabs = [ _Tab('/home',      '🏠'), _Tab('/nutrition', '🌿'), _Tab('/fitness',   '🏃'), _Tab('/health',    '🩺'), _Tab('/profile',   '👤'),
  ];

  int _idx(String loc) {
    // Map body → health in nav if (loc.startsWith('/body')) return 3; if (loc.startsWith('/scanner')) return 0; // show home as active
    for (int i = 0; i < _navTabs.length; i++) {
      if (loc.startsWith(_navTabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc    = GoRouterState.of(context).matchedLocation;
    final idx    = _idx(loc);
    final isDark = ref.watch(themeProvider);
    final lang   = ref.watch(languageProvider); final isAr   = lang =='ar';
    final cals   = ref.watch(caloriesProvider);
    final water  = ref.watch(waterProvider);
    // Badge: nutrition tab if no meals, health tab if water < 50%
    final nutritionBadge = cals.entries.isEmpty;
    final healthBadge    = water.cups == 0;
    final navBg  = isDark ? AppColors.darkNav  : AppColors.lightNav;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final labels = isAr ? ['الرئيسية', 'تغذية', 'لياقة', 'صحة', 'ملفي'] : ['Home',     'Nutrition', 'Fitness', 'Health', 'Profile'];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: _navTabs.asMap().entries.map((e) {
                final active = e.key == idx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(_navTabs[e.key].path),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(fontSize: active ? 22 : 19),
                            child: Stack(clipBehavior: Clip.none, children: [
                            Text(e.value.emoji), if ((e.value.path =='/nutrition'&& nutritionBadge) || (e.value.path =='/health'&& healthBadge))
                              Positioned(
                                right: -4, top: -4,
                                child: Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.haramRed, shape: BoxShape.circle)),
                              ),
                          ]),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle( fontFamily:'Cairo',
                              fontSize: active ? 10 : 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              color: active
                                  ? AppColors.sunnahGreen
                                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            ),
                            child: Text(labels[e.key]),
                          ),
                          // Active indicator dot
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 16 : 0,
                            height: active ? 3 : 0,
                            decoration: BoxDecoration(
                              color: AppColors.sunnahGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String path, emoji;
  const _Tab(this.path, this.emoji);
}
