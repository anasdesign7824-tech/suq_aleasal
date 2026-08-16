# سوق العسل اليمني — Architecture Contract

## القرار المعماري

المشروع الحالي يملك أساسًا قابلًا لإعادة الاستخدام: حزم Dart للعقود والبيانات ونظام التصميم، Demo catalog، Repository factory، وتطبيق Flutter قائم. المشكلة ليست غياب كل شيء، بل أن تجربة العميل مركزة حاليًا في ملف كبير واحد وأن بعض أجزاء Android/Web والأصول والبيانات لم تتحول إلى بنية إنتاجية موحدة. لذلك تعتمد هذه المرحلة **إعادة هيكلة تدريجية فوق الموجود** مع إبقاء كل commit قابلًا للتراجع.

المبدأ الحاكم هو:

```text
Widget / Screen
  → Controller or ViewModel
  → Use Case
  → Repository Contract
  → Data Source
  → Demo JSON or Supabase/API
```

ولا يسمح بأي مسار من UI مباشرًا إلى Supabase أو قاعدة البيانات.

## طبقات المشروع

| الطبقة | المسؤولية | الممنوع |
|---|---|---|
| `apps/mobile_flutter/lib/features/*/presentation` | الشاشات، widgets، route adapters، حالات العرض | قراءة Supabase أو JSON مباشرة |
| `packages/contracts_dart` | entities، value objects، enums، query/draft/result contracts | Flutter UI أو تفاصيل Supabase |
| `packages/data_dart` | Repository interfaces، Demo/Production implementations، data mapping | رسم الواجهة أو منطق layout |
| `packages/design_system/dart` | tokens، typography، colors، radii، spacing، component primitives | بيانات المنتج أو routing |
| `apps/mobile_flutter/lib/core` | configuration، errors، routing، state primitives، shared widgets، asset helpers | feature-specific business rules |
| `docs` | قرارات، traceability، evidence، acceptance | مصدر runtime للمنتج |

## الهيكل المستهدف التدريجي

```text
apps/
  mobile_flutter/
    lib/
      app/
        assal_app.dart
        assal_theme.dart
        app_config.dart
        app_router.dart
      core/
        errors/
        routing/
        state/
        widgets/
        assets/
      features/
        auth/
          data/
          domain/
          presentation/
        home/
        discovery/
        categories/
        search/
        products/
        stores/
        favorites/
        profile/
        requests/
        messaging/
        notifications/
        merchant/
        settings/
    test/
      unit/
      widget/
      journeys/
      repositories/
    android/
    web/
packages/
  contracts_dart/
  data_dart/
  design_system/dart/
docs/
```

لا يتم نقل كل الملفات دفعة واحدة. يُنقل feature بعد تثبيت عقده واختباراته، مع إبقاء ملفات التصدير القديمة مؤقتًا فقط عند الحاجة للتوافق، ثم حذفها بعد اكتمال parity.

## Boot وRuntime

يجب أن يلتف التطبيق بجذر `MaterialApp` واحد يحتوي `locale: ar` و`GlobalMaterialLocalizations.delegates` و`Directionality` وTheme موحد. هذا يعالج خطأ Mimo الظاهر في النسخة القديمة، حيث كانت `RefreshIndicator` و`NavigationBar` تبحث عن `MaterialLocalizations` غير موجودة. يجب أن يكون الإصلاح موجودًا في المصدر، في APK الجديد، وفي widget test، لا أن يعالج بالاعتماد على بيئة المحاكي.

## Data source strategy

| الوضع | مصدر البيانات | سلوك الواجهة |
|---|---|---|
| Demo | `InMemoryDemoCatalogLoader` وDemo repositories | لا يحتاج شبكة؛ mutations محلية داخل الجلسة؛ يعرض بيانات مترابطة وغنية |
| Production | Production repositories خلف gateway/data source | نفس contracts وuse cases؛ أخطاء الشبكة/auth تظهر كحالات قابلة لإعادة المحاولة |
| Test | fixtures ثابتة ومصغرة | deterministic؛ لا تعتمد على جهاز أو Supabase حقيقي |

يتحول الوضع عبر configuration/feature flags محدودة مثل `demoMode` و`backendMode` و`enableMessaging` و`enableReviews` و`enableMerchant`. لا تستخدم flags لإخفاء أخطاء بنيوية أو لتقديم fake persistence على أنه Production.

## Routing and state

كل route له input typed وحالة not-found واضحة. كل feature data-driven يمر بحالات `initial/loading/loaded/empty/error` مع `retry`، ولا توجد FutureBuilder متداخلة بلا boundary في الشاشات النهائية. عند الحاجة ينتقل المنطق إلى Controller/ViewModel صغير قابل للاختبار، بدل تحميل شاشة واحدة كل منطق التطبيق.

## Web/APK parity

يشترك Web وAPK في domain/data/presentation contracts، وتختلف طبقة shell responsive فقط. على Web يجب دعم keyboard navigation، viewport واسع، focus states وURL/deep-link strategy. على APK يجب دعم touch targets، back handling، share/handoff adapters، وAndroid host ثابت قابل لإعادة البناء من GitHub. لا يعتبر بناء APK من نسخة محلية غير متتبعة دليلًا على تكامل المشروع.

## حدود الإصدار الحالي والحزم اللاحقة

أصبح **Admin Web المحلي المحمي** وSupabase/RLS وStorage وfull end-to-end acceptance جزءًا من الإصدار التشغيلي الحالي وفق الخطة الموحدة المعتمدة. يُنفّذ Admin عبر React/Vite shell وRepository/Data Source وSupabase Auth/RLS، ولا تُضاف استدعاءات Admin أو SQL مباشرة إلى Customer Widgets.

تبقى **Landing Website العام وCloudflare وPublic Web marketing deployment** حزمًا لاحقة. يبقى Flutter Web Customer artifact داخل المستودع وقابلًا للبناء والاختبار، لكن لا يُعلن نشره العام أو إطلاق Landing قبل اجتياز Customer + Merchant + Admin local acceptance.
