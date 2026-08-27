# Landing build evidence — 2026-08-27

## Implementation

تم إنشاء Landing فعلية في `apps/landing_web` بواجهة عربية RTL، وهوية عسلكم الخارجية، أقسام الفكرة والرحلة والتطبيق، SEO/Open Graph، نموذج اهتمام محلي صريح، responsive layout، reduced-motion، وإعداد `_headers` و`wrangler.toml` قابل لإعادة الإنتاج دون أسرار.

## Verification

تم تشغيل `node --check apps/landing_web/app.js` بنجاح. تمت معاينة الصفحة عبر خادم static محلي مؤقت، وأعادت HTTP 200 وظهرت الهوية والتنقل والأقسام والنموذج والروابط. تم تسجيل الفحص البصري في `/home/ubuntu/landing_preview_visual_check.md` داخل بيئة التنفيذ.

## Asset policy

الشعار الخارجي يُحمّل من CDN assets بدل وضع SVG الكبير داخل حزمة الموقع. لا يوجد APK download URL عام في Landing حتى اعتماد artifact نهائي ورابط توزيع موثوق.

## Deployment status

لم يُنفذ Cloudflare deployment بعد. فحص Cloudflare API الحالي أعاد 401 `Invalid API Token` و403 `Cannot use the access token from location`، كما لم يوجد Pages project مؤكد في المستودع. يلزم اعتماد Cloudflare صالح ومشروع Pages معتمد قبل تنفيذ نشر عام أو إعطاء رابط Cloudflare.

## Repository status

Landing وخطة التنفيذ الموسعة حُفظتا في commit `39f4011` على فرع العمل المحلي، وmanifest الإصدار في commit `7f148fd`. يضاف هذا الدليل وإعداد Wrangler في commit مستقل لاحقًا، بينما تبقى تعديلات تطبيق Flutter السابقة غير الملتزمة خارج هذا commit حمايةً لعمل المستخدم.
