# Dioxivet Academy — نسخة بداية نظيفة

هذا مشروع Flutter جديد. لا يغيّر مستودع GitHub القديم `LMB`.

## 1) إنشاء مستودع GitHub

1. افتح GitHub واضغط **New repository**.
2. الاسم: `dioxivet-academy`.
3. اجعله Private إذا كنت تريد إبقاء الكود خاصًا.
4. أنشئ المستودع فارغًا، بدون README أو .gitignore تلقائيين.
5. ارفع محتويات هذا الملف المضغوط إلى جذر المستودع، بحيث يظهر `pubspec.yaml` في الصفحة الرئيسية، ويظهر `.github/workflows/build-apk.yml`.

## 2) إعداد GitHub Actions Secrets

من المستودع الجديد: **Settings → Secrets and variables → Actions → New repository secret**.

أنشئ السرّين التاليين:
- `SUPABASE_URL` = رابط مشروع Supabase الحالي.
- `SUPABASE_PUBLISHABLE_KEY` = مفتاح Publishable الخاص بالمشروع.

لا تضع `service_role` في التطبيق أو GitHub Actions. لا تشارك المفتاح في المحادثات العامة.

## 3) إعداد Supabase

1. افتح مشروع Supabase الحالي.
2. ادخل **SQL Editor → New query**.
3. افتح الملف `supabase/setup.sql` من المستودع، وانسخ محتواه إلى المحرر ثم اضغط **Run**.
4. تأكد من وجود الفيديو `azareet.mp4.mp4` داخل Storage bucket اسمه `lecture-videos`.

تنبيه: هذا الإعداد يجعل فيديوهات هذا الـ bucket متاحة للقراءة العامة. لا تستخدمه لمحتوى مدفوع أو خاص دون إضافة نظام دخول وصلاحيات مناسبة.

## 4) بناء APK

بعد رفع الملفات وإضافة السرّين:
1. افتح تبويب **Actions** في المستودع الجديد.
2. اختر **Build Dioxivet Academy APK**.
3. اضغط **Run workflow**.
4. إذا نجح البناء، افتح نتيجة التشغيل وانزل إلى **Artifacts**.
5. نزّل `dioxivet-academy-apk`، ثم فك الضغط لتحصل على `app-release.apk`.

الـ workflow ينشئ ملفات Android القياسية تلقائيًا إذا لم تكن موجودة، ثم يشغّل `flutter pub get` و`flutter analyze` ويبني نسخة Release.

## ما الذي يتضمنه المشروع؟

- واجهة عربية أولية باسم Dioxivet Academy.
- قراءة قائمة المحاضرات من جدول `public.lessons`.
- مشغل فيديو.
- إعداد Supabase عبر `--dart-define` بدل تضمين المفاتيح داخل الكود.
- GitHub Actions لبناء APK ورفع الناتج كـ artifact.

## ملاحظات مهمة

- لا يمكن ضمان نجاح الاتصال بقاعدة البيانات قبل تطبيق SQL والتأكد من اسم الملف وسياسات Storage.
- هذا إصدار أولي للتشغيل والبناء، وليس نظام تسجيل دخول أو دفع إلكتروني.
- لا يُحذف أي جدول أو فيديو موجود بواسطة ملف SQL.
