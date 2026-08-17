# Task 33 — Analytics

## النطاق

إضافة تتبع بسيط لمشاهدة المنتج في Demo عبر local buffer، مع منع إنشاء أرقام Production وهمية. حقلا `viewsCount` و`likesCount` موجودان أصلًا في نموذج المنتج، ولم يتم تعديلهما محليًا على نحو يوحي بأنها مقاييس خادمية.

## التنفيذ

أضيفت عملية Repository باسم `trackProductView(String productId)`.

| المصدر | السلوك |
|---|---|
| Demo | يضيف معرّف المنتج إلى `_localProductViewEvents` ويتيح فحص العدد عبر `localProductViewCount` للاختبارات |
| Production | يعيد `production_analytics_not_configured` برسالة عربية واضحة، ولا يكتب أي metric |
| معرّف فارغ | يعيد `invalid_product_view_target` في Demo |

تستدعي `ProductDetailScreen` العملية مرة واحدة في `initState` عند فتح تفاصيل المنتج. لا يوجد تتبع داخل Widgets عبر Supabase، ولا توجد خوارزمية جمع أو تنبؤ.

## الاختبارات

| الفحص | النتيجة |
|---|---|
| `dart format` | PASS |
| `flutter analyze` | PASS — No issues found |
| الاختبارات الأساسية | PASS — 7 tests passed |
| اختبار buffer مستقل | PASS — مشاهدتان للمنتج `p1` وعدّ صحيح، والهدف الفارغ مرفوض |
| اختبار رحلة العميل | PASS — بقية الرحلة تعمل دون Supabase |
| `git diff --check` | PASS |

## الحدود

هذا تتبع محلي لأغراض Demo والتحقق، وليس نظام Analytics إنتاجيًا. إنشاء المقاييس الحقيقية يتطلب Gateway ومخطط بيانات وسياسات وصول منفصلة، ولذلك بقي Production صريحًا في حالة عدم التهيئة.

## Visual / Runtime QA

تمت مراجعة موضع الاستدعاء في lifecycle على مستوى المصدر، ولم تُضف واجهة مستخدم أو مؤشرات مضللة للمستخدم. لقطة المحاكي السابقة لم تكن صالحة بسبب ADB `screencap` الصفري، لذلك الدليل البصري التفاعلي الكامل يظل غير مكتمل.

## بوابة القبول

**BLOCKED** — منطق Analytics Demo والاختبارات وحدود Production ناجحة. سبب الحجب الوحيد هو عدم توفر Screenshot تفاعلي صالح من المحاكي ضمن هذه الدورة.
