# Data Layer — Web

تستخدم مشاريع Admin وLanding عقود TypeScript وRepository واحدًا مع مصدر صريح. `DemoRepository` يعمل من `demo_catalog.json`، و`ProductionRepository` يتطلب `ProductionSelectGateway` محقونًا. لا يوجد اتصال Supabase مخفي داخل طبقة Demo.

أي Feature لاحقة يجب أن تكمل UI + State + Domain Behavior + Repository Contract + Demo Implementation + Demo Data + Loading/Empty/Error States + Tests + Evidence قبل إضافة Production Gateway.
