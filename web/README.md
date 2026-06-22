# web/

ملفات Flutter Web الثابتة قبل عملية البناء.

## المحتويات
- `index.html`: نقطة دخول تطبيق الويب.
- `manifest.json`: إعدادات PWA.
- `favicon.png` و`icons/`: أيقونات التطبيق في المتصفح.

## العلاقة مع Vercel
- عملية النشر لا تعتمد على هذا المجلد فقط؛ يتم تنفيذ:
  - `flutter build web --release`
- الناتج النهائي الذي ينشره Vercel يكون داخل:
  - `build/web`
