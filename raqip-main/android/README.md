# android/

هذا المجلد خاص ببناء تطبيق Android.

## أهم الأجزاء
- `app/src/main/AndroidManifest.xml`: تعريف التطبيق، الصلاحيات، والأيقونة.
- `app/src/main/res/mipmap-*/ic_launcher.png`: أيقونات اللانشر لكل كثافة شاشة (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).
- `app/build.gradle.kts`: إعدادات بناء وحدة التطبيق.
- `build.gradle.kts` و`settings.gradle.kts`: إعدادات المشروع الأندرويد العامة.

## ملاحظة الأيقونات
Android يختار تلقائيًا ملف الأيقونة المناسب حسب كثافة شاشة الهاتف من مجلدات `mipmap-*`.
