# Data Layer — Flutter/Dart

هذه الحزمة تُبقي Demo Mode مستقلًا عن Supabase. `DemoRepository` يقرأ Catalog مضمّنًا عبر `DemoCatalogLoader`، و`ProductionRepository` لا يعمل إلا بعد حقن `ProductionQueryGateway` صريح. حالات التحميل والفراغ والخطأ جزء من العقد.

لا تحتوي الحزمة على شاشة أو User Journey، ولا تُنشئ اتصالًا تلقائيًا أو fallback صامتًا.
