# Raqib (Flutter)

تطبيق Flutter يعمل على Android و Web مع دعم نشر نسخة الويب على Vercel.

## نظرة سريعة
- **المنصات**: Android + Web.
- **الهدف الحالي**: تطوير تجربة الخرائط والتوجيه مع الحفاظ على بناء APK.
- **نقطة التوقف الحالية**: تم إيقاف ميزة "أقرب محطة وقود" مؤقتًا للتركيز على استقرار التوجيه.

## هيكل المشروع
- `lib/` منطق التطبيق والشاشات.
- `android/` إعدادات أندرويد وملفات التطبيق الأصلية.
- `web/` ملفات Flutter Web الثابتة.
- `test/` اختبارات المشروع.
- `scripts/` سكربتات البناء (مثل سكربت Vercel).

## المعاينة على Vercel (بدون التأثير على APK)
إعدادات Vercel مبنية بحيث تنشئ **نسخة Web فقط** أثناء النشر.

### الملفات المسؤولة
- `vercel.json`: إعداد البناء ومجلد المخرجات (`build/web`) + rewrites للويب.
- `scripts/vercel-build.sh`: تنزيل Flutter (stable) ثم:
  - `flutter pub get`
  - `flutter build web --release`

### خطوات الربط السريعة
1. ربط المستودع في Vercel.
2. من إعدادات المشروع:
   - **Framework Preset**: `Other`
   - **Build Command / Output Directory**: يترك فارغًا لأن `vercel.json` يديرهما.
3. تنفيذ Redeploy.

## بناء Android (APK)
هذا المسار غير متأثر بإعدادات Vercel:

```bash
flutter build apk --release
```

## ملاحظات تشغيل
- في Web: يجب السماح بإذن الموقع من المتصفح حتى تعمل ميزات تحديد الموقع.
- في Android: تأكد من منح صلاحيات الموقع من إعدادات النظام.
