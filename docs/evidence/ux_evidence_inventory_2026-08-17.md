# UX Evidence Inventory — 2026-08-17

## نطاق الأدلة

هذا السجل يجمع الملاحظات النصية من `pasted_content_5.txt` مع الصور المرفقة في جلسة المستخدم، ويربطها بمتطلبات قابلة للتنفيذ والاختبار. الصور هي أدلة UX وليست مصدرًا للتصنيف أو البيانات؛ كل قيمة تجارية أو تصنيف يجب أن يأتي من JSON/Repository.

## مصفوفة الأدلة

| الدليل | الملاحظة المرئية/النصية | المشكلة | موضع الإصلاح الجذري | معيار القبول |
|---|---|---|---|---|
| `pasted_file_YCqY2K_image.png` | Home يعرض تعريفًا طويلًا وزر «استكشف المتاجر» ورفًا كبيرًا للمصدر | الترتيب يحتاج فصلًا بين Header ثابت، تعريف، بحث، ticker، ورفوف قابلة للتمرير | `AssalHomeShell` وHome/Discovery shared widgets | Header والبحث والسلوك متسقان في Demo/Debug/Release/AAB |
| `pasted_file_cJZmNZ_image.png` | Filter sheet ممتد بحاويات كبيرة وحقول رئيسية فقط | فراغ رأسي كبير، ولا يظهر القسم الفرعي بعد نوع المنتج | Filter sheet وRepository taxonomy contract | اختيار النوع الرئيسي يكشف القسم الفرعي والدرجات من JSON، مع Empty compact |
| `pasted_file_qU91el_image.png` | Product Detail يعرض Empty Reviews/Comments داخل بطاقات كبيرة | Empty State يستهلك المساحة ويبدو كبيانات ناقصة | `AssalMessageCard`/`AssalStateView` والمكونات المشتركة | أيقونة ونص مركزيان بارتفاع متناسب دون بطاقة ضخمة |
| `pasted_file_KgOrbW_image.png` | Create Account فيه AppBar title وعنوان body وتعريف طويل متكرر | ازدواجية العناوين، والشعار المركزي غير موجود | `AuthScreen` وBrand Component | رسالة قصيرة وشعار مركزي واحد، دون تغيير مسار التسجيل |
| `pasted_file_5r9eTK_image.png` | Login فيه AppBar title وعنوان body، ثم بريد وزر | ازدواجية العنوان، وعدم وجود شعار مركزي في المساحة الرئيسية | Login branch وBrand Component | «أهلًا بك/مرحبًا بك من جديد» + شعار مركزي + بريد + OTP |
| `pasted_file_44hLO2_image.png` | Search يعرض نتائج ببطاقات جيدة لكن Header/الرجوع يحتاجان توحيدًا | عدم اتساق AppBar والسهم والحالات | `AssalAppBar` وSearchScreen | سهم رجوع فعّال وHeader موحد |
| `pasted_file_USuic8_image.png` | Search مع filter يعرض chip ونتيجة، مع فراغات ومسافات غير متوازنة | Filter state يحتاج compact layout وclear all متسق | Search filters / chips | الحالات النشطة واضحة ولا توجد مساحة غير مبررة |
| `pasted_file_jcAZfP_image.png` | Stores تعرض بحثًا ومحافظة وحالة «لا توجد متاجر» داخل مساحة كبيرة | Empty container ضخمة، وغياب/عدم وضوح الرجوع | StoresScreen وAssalStateView | Empty compact في المنتصف مع أيقونة ورسالة فقط |
| `pasted_file_bgQ6P8_image.png` | Filter sheet مماثلة للأولى | المشكلة متكررة في كل مسارات الفلاتر | shared filter components | إصلاح واحد في الجذر ينعكس على كل الشاشات |
| الصورة العريضة `pasted_file_4L0tQp_image.png` | Header/شعار عسلكم في مساحة علوية ضيقة | تحتاج مراجعة مقاس الشعار والـHeader لا تخمين النص | `AssalAppBar`/BrandMark | شعار مركزي أو مصغر حسب السياق دون تكرار النص |

## متطلبات الجذر المشترك

يجب أن تُنفذ التحسينات في `apps/mobile_flutter/lib` وطبقات العقود/Repository عند الحاجة، لا في APK أو flavor محدد. `AssalRuntimeConfig` يبدّل Data Source فقط؛ أما `AssalApp`, `AssalHomeShell`, `AssalBrandMark`, `AssalAppBar`, حالات الفراغ، الفلاتر، والتصميم فهي مشتركة.

## ملاحظات مصدر البيانات

البيانات التي تظهر في Demo تأتي من `assets/demo_catalog.json` عبر `DemoRepository`. Production يقرأ عبر `ProductionRepository` من Supabase. لا يجوز إعادة تصميم البطاقات على أساس أن البيانات «حقيقية» فقط لأن شكلها يبدو حقيقيًا، ولا يجوز حذف Demo data لتجميل Empty State. يجب أن تميّز الواجهة بين `loading`, `data`, `empty`, و`error`.

## ملاحظات المصادقة

النسخة السابقة التي كانت على Mimo هي Demo Mode رغم كونها Release ARM64؛ `DemoRepository.requestEmailOtp` لا يرسل بريدًا، و`verifyEmailOtp` يقبل الرمز التجريبي `123456`. مرشح Production بُني من الجذر المشترك مع dart defines منفصلة، وسيبقى تحقق OTP الحقيقي مرتبطًا بإعداد Supabase وبصندوق بريد اختبار مصرح به.

## قواعد التصميم المستخلصة

يُستخدم شعار داخلي runtime واحد عبر `AssalBrandMark`، مع إطار فاتح بزوايا 8 عند وضعه فوق خلفية داكنة. لا تُكرر كلمة «عسلكم» بجانب الشعار إذا كان الشعار كافيًا. Login/Create Account يستخدمان نصًا قصيرًا وشعارًا مركزيًا كبيرًا. التنقل السفلي المستهدف خمسة عناصر: «اكتشف»، «المتاجر»، «التصنيفات»، «المراسلات»، «حسابي». ticker مستقل أسفل التعريف والبحث، وليس حركة عشوائية لكل الصفحة.

## حالة التحقيق

تمت مطابقة الأدلة النصية والبصرية. الخطوة التالية هي تعديل المكونات المشتركة بدءًا من Brand/State/AppBar ثم Login/Home/Navigation/Filters، مع اختبارات مستقلة لكل مجموعة وعدم تغيير مصدر البيانات أو وضع Production أثناء إصلاح UX.
