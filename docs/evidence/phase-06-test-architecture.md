# Phase 6 — TEST وARCHITECTURE CHECK

## التطبيق

نجح `tools/check_flutter_app.py` في التحقق من pubspec، أصول Demo Catalog، شعاري الهوية، خط IBM Plex Sans Arabic، ملفات Dart الأساسية، ومساري Customer وMerchant. كما نجح `tools/check_demo_catalog.py` بعد مزامنة بيانات Demo مع التطبيق.

## Customer flow

تتضمن الواجهة Home عربية RTL، وسم Demo Mode، بحثًا نصيًا، منتجات مختارة، بطاقة منتج، شاشة تفاصيل، مراجعات، وطلب تواصل تجريبي. الشاشة تعتمد على `AssalRepository` ولا تتصل بمصدر خارجي.

## Merchant flow

تتضمن لوحة التاجر ملخص المنتجات والتقييم وطلبات التواصل وقائمة المنتجات، وتعمل من نفس Demo Repository مع عرض واضح للحالة التجريبية.

## States

تستخدم الشاشات `FutureBuilder` مع `AssalStateView` الذي يغطي loading/data/empty/error. رسائل الفراغ والخطأ عربية، وتظهر أزرار إعادة المحاولة حيث يلزم.

## Visual check

الفحص البصري التنفيذي مؤجل لأن Flutter/Dart CLI لم يتوفر في Sandbox، ومحاولة التحقق على جهاز المستخدم انتهت بمهلة دون نتيجة. لا توجد واجهة منشورة أو screenshot يمكن اعتمادها قبل توفر toolchain. تم تعويض ذلك بفحص الأصول، التوكنز، RTL في المصدر، ونظافة حدود Demo.

## Security/architecture

لا تحتوي ملفات Flutter Demo على Supabase أو service role أو اتصال مباشر. التبديل إلى Production محصور في Factory وGateway خارج الواجهة. لا توجد Widget تستدعي مصدر بيانات مباشرة.

## Issues found and fixed

اكتشف الفحص الأول غياب Demo Catalog من pubspec، وتمت إضافته ثم إعادة الفحص بنجاح. كما صُححت مسارات logo aliases داخل Demo Catalog إلى `assets/brand/logo-internal.svg`، وأُعيدت مزامنة أصل التطبيق.
