# Phase 6 — تطبيق Flutter/Dart وتجارب Customer وMerchant

## الهدف

إنشاء تطبيق Flutter/Dart فعلي قابل للتشغيل في Demo Mode، يستخدم Design System وعقود Dart وDemo Repository، ويعرض مساري Customer وMerchant مع RTL وحالات التحميل والفراغ والخطأ. لا يُوصل Supabase في Demo، ولا يُعتبر أي شاشة مكتملة دون State وDomain Behavior وRepository Contract وDemo Data وTests وEvidence.

## نطاق Customer

يتضمن Home، البحث والتصفية، قائمة المنتجات، تفاصيل المنتج، صفحة المتجر، المفضلة، التقييمات والتعليقات، طلب تواصل، والإشعارات. يجب أن تظهر الهوية العربية والبيانات المستخرجة من Honey Master عبر Demo Repository.

## نطاق Merchant

يتضمن لوحة التاجر المختصرة، ملخص المنتجات، طلبات التواصل، بيانات المتجر، وروابط الاستلام والتوصيل كحالات تجريبية. لا تُرسل بيانات إنتاجية، ويُوضح Demo Mode داخل التطبيق.

## البنية

يستخدم التطبيق `MaterialApp` مع RTL وIBM Plex Sans Arabic، وطبقة Presentation منفصلة عن Repository، ونموذجًا صريحًا لحالة الشاشة. يستخدم `AssalRepositoryFactory` مع `demo` افتراضيًا، ولا يسمح بالتحول إلى `production` دون Gateway صريح.

## بوابة المرحلة

تتبع المرحلة: `PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE → GIT COMMIT → ACCEPTANCE GATE`.
