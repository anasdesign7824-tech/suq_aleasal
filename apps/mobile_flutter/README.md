# عسلكم — Flutter/Dart App

هذا هو تطبيق الهاتف الهندسي **Souq Al Assal / سوق العسل** والاسم التجاري الظاهر **عسلكم**. التطبيق يستخدم Flutter/Dart وIBM Plex Sans Arabic وDesign System المشترك.

## Demo Mode

يبدأ التطبيق من `DemoRepository` و`assets/demo_catalog.json`، ولا يتصل بـ Supabase. يظهر وسم «نسخة تجريبية» داخل الواجهة. يتيح التطبيق مسار العميل لاكتشاف المنتجات وتفاصيلها وطلب التواصل، ومسار التاجر لمراجعة المنتجات والطلبات التجريبية.

## Production

Production Repository موجود كـ adapter قابل للحقن من خلال Gateway صريح. لا يوجد اتصال تلقائي أو fallback صامت، ولن يُفعّل قبل مرحلة Production Data Sources المحددة في الخطة.

## تشغيل محلي عند توفر Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

قيد البيئة الحالي: Flutter/Dart CLI غير متوفر في Sandbox، لذلك تُسجل الأدلة المصدرية الآن وتُعاد هذه الأوامر عند توفر toolchain.
