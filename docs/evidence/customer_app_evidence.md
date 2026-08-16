# سجل أدلة تدقيق تطبيق العميل — عسلكم

هذا السجل يجمع الأدلة القابلة لإعادة التشغيل من نسخة تطبيق العميل Flutter Web وAPK. لا يُعد إعلان GO نهائيًا قبل إكمال التدقيق البصري والاختبارات اليدوية التفصيلية، لكنه يفصل بوضوح بين ما تم إثباته وما بقي مفتوحًا.

## نقطة التسليم الحالية

| البند | الدليل | النتيجة |
|---|---|---|
| المصدر | GitHub `anasdesign7824-tech/suq_aleasal`, branch `main` | آخر commit موثق في سجل Git |
| التحليل الساكن | `flutter analyze --no-pub` من `D:\suq_aleasal_audit2\apps\mobile_flutter` | `No issues found!` |
| الاختبارات | `flutter test` | 6 اختبارات تمر |
| Web build | `flutter build web --release` | نجح، و`build/web` موجود |
| Web HTTP | `npx serve -s apps/mobile_flutter/build/web -l 8124` ثم curl | `index.html` و`main.dart.js` يعيدان HTTP 200 |
| APK debug | `flutter build apk --debug` | نجح |
| APK release | `flutter build apk --release` | نجح، artifact بحجم يقارب 75.5MB |
| Mimo install | `adb install -r build/app/outputs/flutter-apk/app-release.apk` | `Success` |
| Mimo runtime | `adb shell dumpsys activity activities` بعد التشغيل | `com.assalkom.assalkom/.MainActivity` في الواجهة |
| Mimo crash smoke | `adb logcat -d` مع بحث `FATAL` | لا توجد أسطر FATAL في نافذة الفحص |
| Guest boot | `test/widget_test.dart` | التطبيق يقلع مباشرة إلى Guest Discovery بلا login wall |
| Core navigation | `test/navigation_test.dart` | اكتشف، التصنيفات، الحساب تمر في الاختبار |
| Dataset integrity | `test/demo_catalog_integrity_test.dart` | يثبت 10+ مناطق/متاجر/تصنيفات، 40+ منتجًا، 5 banners، popular searches، وبيانات اجتماعية مترابطة |
| Journey integration | `test/customer_journey_test.dart` | auth، follow، favorite، like، request، review، comment، message، merchant application، notification read state |
| Filter matrix | `test/data_layer_test.dart` | region، province، origin، certificate، processing، packaging، availability، merchant، rating، price |

## التغييرات الوظيفية المثبتة

تم فصل تجربة العميل إلى وحدات `customer_core`, `customer_discovery`, `customer_catalog`, `customer_social`, `customer_account`, و`customer_favorites` مع facade يحافظ على imports السابقة. تم توسيع Demo catalog إلى بيانات مترابطة، وإضافة Hero carousel بتدوير تلقائي، popular searches، rails للاكتشاف، responsive grids، وNavigationRail لسطح المكتب.

تشمل تفاصيل المنتج gallery ديناميكية من `imageUrls` وبيانات هوية العسل والمصدر والمعالجة والتعبئة والتواريخ والتسليم والاستلام. وتشمل صفحة المتجر gallery وروابط التواصل والتوصيل والاستلام. كما أصبحت Favorites مقسمة إلى المنتجات والمتاجر والتصنيفات المرتبطة بالمحفوظات، وأصبح merchant conversion نموذجًا محفوظًا في Demo مع إشعار متابعة.

تتبع الطلبات مسار التواصل والتسليم دون Checkout، وتدعم `deliveryNote` و`handoffDetails`. وتدعم الإشعارات unread badge وmark-as-read. أما Google sign-in وProduction writes فتظهر كحدود typed واضحة؛ Demo لا يوهم المستخدم بنجاح OAuth غير متاح دون مزود إنتاجي.

## الفجوات التي لا يجوز إخفاؤها قبل GO

| الفجوة | أثرها | الإجراء المطلوب |
|---|---|---|
| التدقيق البصري الكامل على مقاسات Web متعددة | لا يكفي HTTP 200 لإثبات typography وoverflow وfocus | تشغيل متصفح فعلي على mobile/tablet/desktop وتسجيل screenshots |
| توقيع APK الإنتاجي | release build ناجح لكنه ليس artifact موقّعًا بمفتاح متجر المستخدم | تزويد keystore وتهيئة `key.properties` خارج Git قبل النشر |
| OAuth Google الحقيقي | العقد والواجهة المفسرة موجودان، لكن provider غير مهيأ | ربط مزود Auth الإنتاجي في حزمة Backend/Auth اللاحقة |
| Supabase/RLS الحقيقي | ProductionRepository boundary موجود، ومصدر البيانات لم يُفعّل | تنفيذ حزمة Supabase/RLS بعد Customer App GO حسب الخطة |
| Accessibility audit اليدوي | Semantics أساسية موجودة، لكن keyboard/focus/text-scale تحتاج فحصًا | تشغيل accessibility scanner وفحص لوحة المفاتيح والتكبير |

> القاعدة الحاكمة: لا يتحول أي بند إلى PASS بمجرد نجاح build. يجب أن يمر التنفيذ، الاختبار، التشغيل، الفحص البصري، وفحص المعمارية مع وجود دليل قابل لإعادة التشغيل.
