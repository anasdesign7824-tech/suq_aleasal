# تدقيق جاهزية عسلكم قبل Google Play

**التاريخ:** 17 أغسطس 2026

**النطاق:** نسخة Android APK المستقلة عن Web، وSupabase/Auth/Database/Storage، وتحسينات تجربة العميل والتاجر.

## الحكم التنفيذي

النسخة الحالية **ليست جاهزة بعد للنشر العام على Google Play بنسبة 100%**، لكنها تملك أساسًا تقنيًا جيدًا ومثبتًا: مشروع Supabase يعمل، Email وGoogle وFacebook مفعلة على مستوى إعدادات Auth العامة، مسار Google Android مكتوب كـ native ID-token flow بلا deep-link redirect، تهيئة المستخدمين الجديدة موجودة في قاعدة البيانات، وطبقة Glass Loading ونتائج التحليل والاختبارات الآلية سليمة.

العوائق الحقيقية ليست في Flutter UI وحدها، بل في أربع طبقات إنتاجية لم تُغلق بعد: **توقيع Play release، التحقق التفاعلي من Google على artifact موقّع، البريد الإنتاجي وتأكيد الحساب، وربط عمليات الكتابة ومسار التاجر/الإدارة بقاعدة البيانات**. كما أن Facebook داخل APK غير مفعّل عمدًا حاليًا لأن Native Facebook SDK لم يُضف؛ لذلك لا يجوز وصف تسجيل الدخول في Android بأنه مكتمل بجميع المزودين.

## الحالة الحالية المثبتة

| المجال | الحالة الحالية | الدليل أو الملاحظة |
|---|---|---|
| Supabase project | يعمل وACTIVE_HEALTHY حسب التدقيق السابق | endpoint الإنتاجي يستجيب، وAuth settings تُظهر `email=true`, `google=true`, `facebook=true` |
| إنشاء مستخدم جديد | مهيأ | trigger `auth.users.on_auth_user_created` يستدعي `private.handle_new_user()`؛ الوظيفة تنشئ صفًا في `public.users` و`public.profiles` |
| Google Android | مهيأ برمجيًا كـ native | `google_sign_in` ثم `signInWithIdToken`، مع `serverClientId` من Web Client ID |
| Android redirect | مغلق | manifest الخاص بالـ APK لا يعلن deep-link `login-callback` |
| Email/Password | مسار برمجي موجود | `signInWithPassword` و`signUp` موصولان ببوابة Supabase |
| Facebook Android | غير مكتمل عمدًا | الزر مخفي على Android؛ المصدر يرجع `facebook_native_not_configured` بدل فتح متصفح أو redirect |
| RLS | سياسات ذات شروط مستخدم/مشرف موجودة | شروط `auth.uid()` و`is_admin()` ظاهرة في سياسات القراءة والكتابة؛ اختبار RLS السابق 7/7 PASS |
| Storage | buckets موجودة | `assalkom_public` عام بحد 10MB للصور، و`assalkom_private` خاص بحد 20MB |
| Glass Loading | مطبق في customer UI | `AssalGlassLoading` و`AssalFutureStateView`؛ لا توجد `CircularProgressIndicator` في customer screens وفق الفحص الحالي |
| Static/test regression | PASS | `flutter analyze --no-pub`: لا توجد Issues، و`flutter test --no-pub`: 8/8 |
| بيانات الإنتاج | شبه فارغة | users=1، profiles=1، merchant_profiles=0، stores=0، products=0، banners=0، notifications=0؛ بينما regions=357 وtaxonomy=39 |
| Android signing | غير صالح للنشر العام حاليًا | الـAPK الحالي موقّع بشهادة `Android Debug`، وليس upload key أو Play App Signing |

## ما يلزم لإكمال تسجيل الدخول

### Google native داخل APK

التدفق البرمجي الحالي صحيح من حيث الفكرة: Android يستدعي account chooser من `google_sign_in` ثم يرسل ID token إلى Supabase عبر `signInWithIdToken`. توثّق Supabase هذا المسار للتطبيقات الأصلية، وتطلب تسجيل Client ID مع بصمة SHA-1 الخاصة بالشهادة التي توقّع التطبيق [1] [2].

لكن اكتمال Google في الإنتاج يحتاج الخطوات التالية:

1. إنشاء **upload keystore** آمن خارج Git، وتهيئة `release` signing في Gradle بدل `signingConfigs.getByName("debug")`. الـAPK الحالي يثبت ذلك بوضوح: شهادة `Android Debug` وبصمة SHA-1 للـdebug وليست شهادة Play.
2. بناء **Android App Bundle `.aab`** موقّعًا بمفتاح upload، ثم تفعيل Google Play App Signing في Play Console. Google توصي بالفصل بين upload key وapp signing key [3].
3. بعد إنشاء التطبيق في Play Console، أخذ SHA-1 من مكانين: **Upload certificate** و**App signing certificate**. يجب تسجيل بصمات الاختبار/الرفع وبصمة Play production في Google Cloud Android OAuth client. بصمة Play هي التي ستهم المستخدمين بعد تنزيل التطبيق من المتجر.
4. التأكد من أن Supabase Google provider يحتوي Web Client ID أولًا، ثم Android Client ID، وأن Client IDs المطابقة للبصمات الفعلية مسجلة في Google Cloud وSupabase. لا يمكن اعتبار `google=true` وحدها إثباتًا أن Client ID وsecret والقائمة المرتبة صحيحة، لأن endpoint العام لا يعرض القيم السرية.
5. تثبيت الـAAB أو APK release الموقّع فعليًا على جهاز Android حقيقي/مسار Play internal testing، ثم اختبار: فتح chooser، اختيار حساب، إلغاء الاختيار، إضافة حساب، نجاح أول تسجيل، إعادة فتح التطبيق، refresh للجلسة، sign-out، وإعادة تسجيل الدخول. الاختبارات الحالية تثبت الكود والبناء، لكنها لا تثبت account chooser التفاعلي لأن بيئة المحاكاة الذاتية لم تقلع بسبب غياب KVM.

### Email/Password

مسار Email/Password موجود، لكن إعداد Supabase الحالي يُظهر `mailer_autoconfirm=false`. لذلك يجب إعداد **SMTP إنتاجي** موثوق، واختبار البريد الفعلي، وتوفير تجربة واضحة لـ:

- رسالة «تحقق من بريدك» بعد إنشاء الحساب إذا كانت رسالة التأكيد مطلوبة.
- إعادة إرسال رسالة التأكيد.
- نسيت كلمة المرور وإعادة تعيينها.
- رسائل واضحة عند بريد مستخدم سابقًا، كلمة مرور ضعيفة، أو انتهاء رابط التأكيد.
- عدم اعتبار التسجيل ناجحًا بصريًا قبل وجود جلسة صحيحة، إلا إذا كانت الواجهة تشرح أن الحساب ينتظر تأكيد البريد.

الكود الحالي يعالج `register` و`signIn`، لكن تدفق UI الظاهر في `AuthScreen` لا يثبت وحده اكتمال تجربة تأكيد البريد والإعادة؛ لذلك يلزم اختبار SMTP والرسائل على مشروع الإنتاج قبل Play.

### Facebook

Facebook مفعّل في إعدادات Supabase العامة، لكن **ليس مكتملًا داخل APK**. المصدر الحالي يخفي الزر على Android ويمنع redirect، وهذا قرار صحيح بالنسبة لمطلب التطبيق المستقل، لكنه يعني أن Facebook ليس مزودًا جاهزًا للإطلاق على Android.

إذا كان المطلوب Google + Email فقط في الإصدار الأول، يجب حذف Facebook من قائمة ادعاءات الإصدار وتوثيق أنه مؤجل. أما إذا كان المطلوب Facebook في APK، فيلزم إضافة `flutter_facebook_auth`، إعداد Facebook App ID وClient Token وpackage name وkey hashes، طلب `public_profile` و`email`، وربط access token بـ`signInWithIdToken` أو اعتماد flow موثق آخر. توضح Supabase أن native Facebook يحتاج SDK وإعدادات Facebook ومراجعة صلاحيات قبل فتحه للجمهور [4].

## حالة قاعدة البيانات وSupabase

### ما تم بناؤه بشكل صحيح

قاعدة البيانات تحتوي على الجداول الأساسية للمستخدمين والملفات والمتاجر والمنتجات والطلبات والمراجعات والإشعارات والبنرات، إضافة إلى المناطق والتصنيفات. trigger إنشاء المستخدم يكتب `users` و`profiles` تلقائيًا، وحماية الدور تمنع المستخدم العادي من تغيير `profiles.role`. كما تمنع وظيفة الحماية تغيير حالة توثيق التاجر إلا للمشرف.

سياسات RLS ليست أسماء فقط؛ شروطها تفحص `auth.uid()` وملكية المتجر أو الطلب، أو تستدعي `is_admin()`. وهذا مناسب كأساس لعزل IDOR، مع بقاء اختبار الكتابة بعد ربط client الحقيقي مطلوبًا.

### ما يجب تشديده قبل الإطلاق

نتيجة grants تُظهر أن `anon` و`authenticated` يملكان صلاحيات SQL واسعة جدًا على عدة جداول، تشمل `DELETE, INSERT, SELECT, UPDATE`، بينما تعتمد الحماية على RLS لمنع التنفيذ غير المسموح. هذا قد يكون آمنًا وظيفيًا إذا بقيت كل السياسات صحيحة، لكنه ليس مبدأ أقل صلاحية مثاليًا. قبل الإطلاق العام يجب مراجعة grants بحيث يحصل `anon` على القراءة العامة فقط حيث يلزم، ويحصل `authenticated` على عمليات الكتابة الضرورية فقط، ويبقى Admin/Service Role للعمليات الإدارية. توثّق Supabase نفسها ترتيبًا مشابهًا: تفعيل RLS والسياسات أولًا ثم منح الصلاحيات الأقل اللازمة للأدوار [2].

كما يجب تفعيل **Leaked Password Protection** في Supabase Auth؛ وهو التحذير الأمني المتبقي الذي ظهر في Security Advisors. يجب أيضًا ضبط rate limits وCAPTCHA/حماية إساءة الاستخدام وفق مستوى المخاطر، والتأكد من أن مفاتيح service-role لا تدخل APK أو Git.

### Storage

Buckets الحالية مناسبة مبدئيًا، لكن وجودها لا يعني أن المنتج مكتمل. يلزم اختبار فعلي بحساب authenticated لرفع صورة متجر وصورة منتج، قراءة الصورة العامة، رفض ملف MIME غير مسموح، رفض ملف أكبر من الحد، والتحقق من أن المسارات لا تسمح لمستخدم بتعديل ملف مستخدم آخر. حاليًا لا يوجد ربط مكتمل في Store Wizard لرفع الوسائط، ولا Admin Web إنتاجي يرفع البنرات إلى `assalkom_public` ثم يسجلها في `banners`.

### بيانات الإنتاج

قاعدة البيانات الإنتاجية تحتوي على taxonomy والمناطق، لكنها لا تحتوي على catalog فعلي: stores=0 وproducts=0 وbanners=0. لذلك ظهور Empty State في APK ليس عطل اتصال، بل نتيجة صحيحة لقاعدة فارغة. قبل إطلاق استقبال المستخدمين يجب إدخال متجر حقيقي أو seed إنتاجي منضبط، وإضافة منتجات وصور وبنرات، وتدقيق الصور والروابط والتصنيفات والأسعار والعملة.

## تجربة التاجر والإدارة

تجربة التاجر ليست مكتملة end-to-end في النسخة الحالية. يوجد نموذج تقديم، لكن `ProductionRepository.submitMerchantApplication` يرجع `production_merchant_application_not_configured`. كما لا يوجد جدول `merchant_applications` في schema الحالية؛ الموجود هو `merchant_profiles` و`stores` والجداول التابعة لها.

كذلك يوجد ملف مرجع `YemenLocationReference` ومصدر JSON للمحافظات والمديريات، لكن الفحص الحالي لا يجد استخدامه داخل Store Wizard. ولا يوجد ربط Flutter فعلي بـ`FilePicker`/`ImagePicker` أو `assalkom_public` في مسار التاجر. لذلك التحسين البصري للتاجر لا يساوي بعدُ تجربة تاجر إنتاجية كاملة؛ المطلوب هو Wizard متعدد الخطوات مع draft/resume، cascading governorate→district، رفع صور، delivery/pickup، إنشاء طلب مراجعة، ثم قبول Admin وتحويل merchant capability إلى متجر.

عمليات الكتابة الإنتاجية الأخرى ما تزال placeholders صريحة في `ProductionRepository`: إنشاء الطلب، المراسلة، المراجعة، التعليق، المتابعة، الحفظ، والإعجاب تعيد `production_write_not_configured`. القراءة وتسجيل الدخول موجودان، لكن التفاعل الاجتماعي والطلبات لن يستمر في قاعدة البيانات حتى تُنفذ هذه العمليات وتُختبر ضد RLS.

Admin Web الحالي ما يزال Demo-oriented وفق المصدر، وتظهر فيه بيانات `demoCatalog` وعبارات Demo وعدم وجود ربط إنتاجي مع Supabase. لذلك لا يمكن الاعتماد عليه حاليًا لإدارة البنرات والمنتجات والتجار إلا بعد إعادة ربطه واختبار مسار رفع/نشر حقيقي.

## هل تحسينات UX تعمل؟

الإجابة الدقيقة هي: **مطبقة برمجيًا وتنجح في الفحوص الآلية، لكنها ليست كلها مثبتة بصريًا على جهاز Android حقيقي، وبعضها يحتاج إكمالًا إنتاجيًا.**

| التحسين | التقييم | التفسير |
|---|---|---|
| Glass shimmer loading | مطبق | `AssalGlassLoading` يستخدم `AnimationController` وBackdropFilter وshimmer، وHome يثبت futures ويعرض initial bundle skeleton بدل عدة loaders تومض منفصلة |
| إزالة spinners التقليدية | مثبتة نصيًا | لا توجد `CircularProgressIndicator` في customer screens وفق grep الحالي |
| Empty/Timeout/Network/Schema | مطبق جزئيًا | `_readList` يميز `timeout`, `network`, `schema_mismatch`, و`data_read_failed` ويسجلها؛ بعض widgets ما تزال تعرض رسالة عامة مثل «تحقق من الاتصال» بدل ترجمة دقيقة لكل code |
| Retry | مطبق في مسارات القراءة الرئيسية | Home وSearch وStores وبعض rails تمرر callback لإعادة التحميل؛ يجب إجراء smoke test بصري بعد وجود بيانات فعلية |
| الأيقونات والـtooltips | مطبق في عناصر رئيسية | أزرار الإشعارات والإعدادات والحفظ والإرسال والخروج تحمل semantics/tooltips؛ الفحص الحالي لم يجد `onPressed: null` حرفيًا في customer/core |
| تجربة Auth loading | مطبق | زر Auth يستخدم Glass Loading بدل spinner عادي |
| تجربة التاجر | غير مكتملة إنتاجيًا | الواجهة موجودة، لكن backend/upload/location/application workflow غير موصول |
| اختبار Android بصري | غير مكتمل | Flutter tests وAPK build ناجحان؛ account chooser وUX النهائي يحتاجان جهاز Android حقيقيًا أو Play internal testing |

## متطلبات Google Play الإضافية خارج الكود

| البند | المطلوب قبل Production |
|---|---|
| Release artifact | رفع `.aab` موقّع بمفتاح upload، وليس APK debug |
| Play App Signing | تفعيل Google Play App Signing وحفظ upload keystore خارج Git |
| Target API | النسخة الحالية target/compile 36؛ Google تطلب API 36 للتطبيقات الجديدة والتحديثات ابتداءً من 31 أغسطس 2026 [5] |
| Privacy policy | رابط HTTPS عام غير PDF، ووصلة داخل التطبيق، يشرح البيانات والاحتفاظ والحذف |
| Data Safety | إكمال النموذج بدقة بما يتوافق مع Supabase وGoogle Sign-In وأي SDK؛ Google تطلب الإفصاح عن بيانات SDKs أيضًا [6] |
| Account deletion | زر حذف داخل التطبيق ورابط خارجي لطلب حذف الحساب والبيانات؛ التعطيل أو التجميد لا يكفي [7] |
| Review credentials | حساب اختبار قابل لإعادة الاستخدام، بدون OTP أو 2FA يوقف المراجع، وتعليمات إنجليزية إذا تطلبت الوظائف تسجيل دخول [8] |
| Closed testing | إذا كان حساب المطور Personal منشأ بعد 13 نوفمبر 2023: 12 مختبرًا على الأقل opted-in باستمرار لمدة 14 يومًا قبل طلب Production access [9] |
| Store listing | اسم، وصف، أيقونة، screenshots، تصنيف محتوى، بيانات دعم، رابط سياسة الخصوصية، وإرشادات وصول المراجع |
| Real content | متجر/منتجات/صور/بنرات حقيقية أو seed معتمد، حتى لا يصل المستخدم إلى تطبيق فارغ بعد التثبيت |

## ترتيب التنفيذ المقترح

**أولًا:** أغلق عقد الإطلاق الأدنى الذي يخص Auth فقط: release keystore وAAB، Play App Signing، fingerprints في Google Cloud، Client IDs في Supabase، SMTP/confirmation/reset، واختبار Google native على internal testing.

**ثانيًا:** أضف account deletion داخل التطبيق وخارجه، privacy policy، Data Safety، leaked-password protection، grants least-privilege، ثم اختبر RLS والـStorage بحسابين مختلفين.

**ثالثًا:** قبل إعلان أن التطبيق «كامل»، نفّذ طبقة التاجر والإدارة: merchant application table أو RPC، Wizard الموقع والوسائط، store creation، product creation، Admin Web production connection، banner upload/publish، notifications insertion، وقواعد audit.

**رابعًا:** نفّذ closed testing على Google Play، واجمع ملاحظات حقيقية، وأعد بناء release كل مرة مع زيادة `versionCode`. لا ترفع artifact debug الحالي إلى Production.

## الخلاصة المباشرة

إذا كان الإصدار الأول سيقدم **التصفح + Email + Google native فقط**، فالمسافة المتبقية إلى إطلاق APK قابلة للإغلاق، لكنها ليست منتهية: التوقيع، fingerprints، SMTP، account deletion، privacy/Data Safety، بيانات حقيقية، واختبار جهاز/Play فعلي ما زالت مطلوبة.

إذا كان الإصدار الأول يجب أن يقدم **Google + Facebook + Email، مع تجربة تاجر وطلبات ومراسلة وبنرات حقيقية**، فالتطبيق غير مكتمل حاليًا؛ لأن Facebook Android غير مهيأ، وعمليات الكتابة والتاجر وAdmin Web ما تزال placeholders أو Demo. التحسينات الزجاجية والأيقونات موجودة وتنجح آليًا، لكنها لا تعوّض هذه الفجوات التشغيلية.

## المراجع

[1]: https://supabase.com/docs/guides/auth/social-login/auth-google "Supabase — Login with Google"

[2]: https://supabase.com/docs/reference/dart/auth-signinwithidtoken "Supabase Dart Reference — signInWithIdToken and Data API access"

[3]: https://developer.android.com/studio/publish/app-signing "Android Developers — Sign your app"

[4]: https://supabase.com/docs/guides/auth/social-login/auth-facebook "Supabase — Login with Facebook"

[5]: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en "Google Play — Target API level requirements"

[6]: https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-GB "Google Play — Data safety section"

[7]: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en "Google Play — App account deletion requirements"

[8]: https://support.google.com/googleplay/android-developer/answer/15748846?hl=en "Google Play — Requirements for sign-in details for review"

[9]: https://support.google.com/googleplay/android-developer/answer/14151465?hl=en "Google Play — Testing requirements for new personal developer accounts"
