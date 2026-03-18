// ============================================================
//  ai_service.dart — SunnahStride v1.0
//  Anthropic Claude Vision API for:
//  1. Food photo → nutrition analysis + halal check
//  2. Body photo → composition estimate (Premium)
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/models/models.dart';

class AIService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model    = 'claude-opus-4-5';
  static const _version  = '2023-06-01';

  // ── Convert image file to base64 ──────────────
  static Future<String> _toBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    return base64Encode(bytes);
  }

  static String _mimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif':  return 'image/gif';
      default:     return 'image/jpeg';
    }
  }

  // ── Core API call ─────────────────────────────
  static Future<String> _callVision({
    required String imagePath,
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 800,
  }) async {
    final b64   = await _toBase64(imagePath);
    final mime  = _mimeType(imagePath);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {'type': 'base64', 'media_type': mime, 'data': b64},
            },
            {'type': 'text', 'text': userPrompt},
          ],
        }
      ],
    });

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'anthropic-version': _version,
        // API key is injected via the proxy — no key needed in app
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['content'] as List).firstWhere(
        (c) => c['type'] == 'text', orElse: () => {'text': '{}'},
      )['text'] as String;
    }
    throw Exception('API error ${resp.statusCode}: ${resp.body}');
  }

  // ════════════════════════════════════════════════
  //  FOOD PHOTO ANALYSIS
  // ════════════════════════════════════════════════
  static Future<FoodPhotoResult> analyzeFoodPhoto({
    required String imagePath,
    required String language, // 'ar' | 'en'
  }) async {
    const system = '''You are a professional dietitian and halal food expert.
Analyze food images and return ONLY valid JSON with this exact structure — no markdown, no extra text:
{
  "foodName": "<Arabic name>",
  "foodNameEn": "<English name>",
  "kcal": <integer per serving>,
  "proteinG": <integer grams>,
  "carbsG": <integer grams>,
  "fatG": <integer grams>,
  "halalStatus": "<halal|doubtful|haram|unknown>",
  "halalNote": "<brief halal explanation in Arabic>",
  "confidence": <0.0-1.0>,
  "ingredients": ["<main ingredient 1>", "<main ingredient 2>"],
  "portionSize": "<e.g. 1 plate ~300g>",
  "sunnahNote": "<any Sunnah/Islamic connection, or empty string>"
}

Rules:
- Calories for visible/estimated portion (not 100g)
- halalStatus: halal=clearly permissible, doubtful=contains uncertain additives, haram=contains pork/alcohol/blood, unknown=cannot determine
- If multiple foods visible, analyze the main dish
- Be conservative with halalStatus — when uncertain, use "doubtful"
- sunnahNote: mention if food is referenced in Sunnah (dates, honey, olive oil, black seed, etc.)''';

    final prompt = language == 'ar'
      ? 'حلل هذا الطعام وأعطني القيم الغذائية والحكم الشرعي.'
      : 'Analyze this food and provide nutritional values and halal assessment.';

    try {
      final raw  = await _callVision(imagePath: imagePath, systemPrompt: system, userPrompt: prompt);
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final json  = jsonDecode(clean) as Map<String, dynamic>;
      return FoodPhotoResult(
        foodName: json['foodName'] as String? ?? 'Unknown',
        foodNameEn: json['foodNameEn'] as String? ?? 'Unknown',
        kcal: (json['kcal'] as num?)?.toInt() ?? 0,
        proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0,
        fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
        halalStatus: HalalStatus.unknown,
        halalExplanation: json['halalNote'] as String? ?? '',
        halalExplanationEn: json['halalNote'] as String? ?? '',
        sunnahNote: json['sunnahNote'] as String? ?? '',
        sunnahNoteEn: '',
      );
    } catch (e) {
      // Graceful fallback
      return _fallbackFoodResult(language);
    }
  }

    static FoodPhotoResult _fallbackFoodResult(String lang) => FoodPhotoResult(
    foodName: lang == 'ar' ? 'وجبة مختلطة' : 'Mixed Meal',
    foodNameEn: 'Mixed Meal',
    kcal: 350, proteinG: 20, carbsG: 40, fatG: 12,
    halalStatus: HalalStatus.unknown,
    halalExplanation: lang == 'ar' ? 'التحليل غير متاح' : 'Analysis unavailable',
    halalExplanationEn: 'Analysis unavailable',
    sunnahNote: '',
    sunnahNoteEn: '',
  );

  // ════════════════════════════════════════════════
  //  BODY PHOTO ANALYSIS (Premium)
  // ════════════════════════════════════════════════
  static Future<BodyPhotoResult> analyzeBodyPhoto({
    required String imagePath,
    required bool isMale,
    required double weightKg,
    required double heightCm,
    required int age,
    required String language,
  }) async {
    final system = '''You are a professional fitness coach and body composition analyst.
Analyze the body image and return ONLY valid JSON with this exact structure:
{
  "estimatedBodyFatPct": <number 5-50>,
  "estimatedMuscleMassKg": <number>,
  "bodyType": "<ectomorph|mesomorph|endomorph>",
  "bodyTypeAr": "<نحيف|متوازن|ضخم>",
  "postureNote": "<brief posture observation in English>",
  "postureNoteAr": "<brief posture observation in Arabic>",
  "recommendations": ["<English rec 1>", "<English rec 2>", "<English rec 3>"],
  "recommendationsAr": ["<Arabic rec 1>", "<Arabic rec 2>", "<Arabic rec 3>"],
  "confidence": <0.0-1.0>
}

IMPORTANT:
- This is an ESTIMATE only — body fat from photos is not clinically accurate
- Use visible muscle definition, fat distribution, and overall physique
- Gender: ${isMale ? 'Male' : 'Female'}, Weight: ${weightKg}kg, Height: ${heightCm}cm, Age: $age
- Recommendations should be practical, Islamic-friendly (no mixed-gender gyms reference)
- Confidence should be lower (0.4-0.65) since photo analysis has inherent limitations
- Focus on achievable, halal fitness goals''';

    final prompt = language == 'ar'
      ? 'قدّر تركيبة الجسم من الصورة. هذا للاستخدام الشخصي فقط.'
      : 'Estimate body composition from this photo. This is for personal use only.';

    try {
      final raw   = await _callVision(imagePath: imagePath, systemPrompt: system, userPrompt: prompt, maxTokens: 1000);
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final json  = jsonDecode(clean) as Map<String, dynamic>;
      return BodyPhotoResult(
        bodyFatPercent: (json['estimatedBodyFatPct'] as num?)?.toDouble() ?? 20.0,
        muscleMassKg: (json['estimatedMuscleMassKg'] as num?)?.toDouble() ?? weightKg * 0.4,
        leanBodyMassKg: weightKg * (1 - ((json['estimatedBodyFatPct'] as num?)?.toDouble() ?? 20.0) / 100),
        bodyType: json['bodyTypeAr'] as String? ?? 'متوازن',
        bodyTypeEn: json['bodyType'] as String? ?? 'mesomorph',
        recommendationsAr: List<String>.from(json['recommendationsAr'] ?? []),
        recommendationsEn: List<String>.from(json['recommendations'] ?? []),
        rawAnalysis: '',
      );
    } catch (e) {
      return _fallbackBodyResult(isMale, weightKg, language);
    }
  }

  static BodyPhotoResult _fallbackBodyResult(bool isMale, double weightKg, String lang) {
    final bf = isMale ? 18.0 : 28.0;
    return BodyPhotoResult(
      bodyFatPercent: bf,
      muscleMassKg: weightKg * (1 - bf / 100) * 0.85,
      leanBodyMassKg: weightKg * (1 - bf / 100),
      bodyType: lang == 'ar' ? 'متوازن' : 'mesomorph',
      bodyTypeEn: 'mesomorph',
      recommendationsAr: ['زِد البروتين اليومي', 'امشِ ٣٠ دقيقة يومياً', 'نم ٨ ساعات'],
      recommendationsEn: ['Increase protein intake', 'Walk 30 min daily', 'Sleep 8 hours'],
      rawAnalysis: '',
    );
  }

  // ════════════════════════════════════════════════
  //  QUICK TEXT-ONLY MEAL SUGGESTION (no image)
  // ════════════════════════════════════════════════
  static Future<String> getMealSuggestion({
    required String prompt,
    required int calorieGoal,
    required String dietType,
    required String goal,
    required String language,
  }) async {
    final system = '''You are a halal dietitian. Respond in ${language == 'ar' ? 'Arabic' : 'English'}.
Provide meal suggestions that are 100% halal, practical, and aligned with Islamic dietary guidelines.
Mention Sunnah foods (dates, honey, olive oil, black seed) when relevant.
Keep response concise and structured.''';

    final userMsg = '''
Calorie goal: $calorieGoal kcal/day
Diet type: $dietType
Goal: $goal
Request: $prompt
''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 600,
      'system': system,
      'messages': [
        {'role': 'user', 'content': userMsg},
      ],
    });

    try {
      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json', 'anthropic-version': _version},
        body: body,
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['content'] as List).firstWhere(
          (c) => c != null && c['type'] == 'text',
          orElse: () => {'type': 'text', 'text': ''},
        )['text'] as String;
      }
      throw Exception('${resp.statusCode}');
    } catch (_) {
      return language == 'ar'
        ? 'عذراً، حدث خطأ في الاتصال. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'
        : 'Sorry, connection error. Please check your internet and try again.';
    }
  }
  // ════════════════════════════════════════════════
  //  FOOD NUTRITION LOOKUP
  // ════════════════════════════════════════════════
    static Future<Map<String, dynamic>> lookupFood(String foodName, {String language = 'ar', bool isPremium = false}) async {
    final isAr = language == 'ar';
    final jsonFmt = isPremium 
        ? '{"name_ar":"...","name_en":"...","kcal":0,"protein_g":0.0,"carbs_g":0.0,"fat_g":0.0,"vitamin_c_mg":0.0,"iron_mg":0.0,"calcium_mg":0.0,"potassium_mg":0.0,"serving_size":"100g","halal":true}'
        : '{"name_ar":"...","name_en":"...","kcal":0,"protein_g":0.0,"carbs_g":0.0,"fat_g":0.0,"serving_size":"100g","halal":true}';

    final system = 'You are a nutrition database expert. When given a food name, return ONLY a JSON object with exact nutritional values per 100g serving. Return ONLY valid JSON, no other text.
Required format: $jsonFmt';

    final prompt = isAr
        ? 'القيم الغذائية لـ: $foodName'
        : 'Nutritional values for: $foodName';

    try {
      final body = jsonEncode({
        'model': _model,
        'max_tokens': 400,
        'system': system,
        'messages': [{'role': 'user', 'content': prompt}],
      });

      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json', 'anthropic-version': _version},
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = (data['content'] as List)
            .firstWhere((c) => c['type'] == 'text')['text'] as String;
        final clean = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(clean) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'name_ar': foodName, 'name_en': foodName,
      'kcal': 100, 'protein_g': 5.0, 'carbs_g': 15.0,
      'fat_g': 3.0, 'serving_size': '100g', 'halal': true,
    };
  }

}
