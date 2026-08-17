# بحث Phone OTP لعسلكم في اليمن

**التاريخ:** 17 أغسطس 2026

## Supabase Phone Auth

توضح وثائق Supabase أن Phone Login يعتمد على OTP يرسل عبر SMS أو WhatsApp، ويحتاج تفعيل Phone Auth وإعداد مزود SMS خارجي. المزودون المدعومون يشملون MessageBird وTwilio وVonage، مع TextLocal كمزود مدعوم مجتمعيًا. يرسل التدفق رمزًا من 6 أرقام، ثم يستدعي التطبيق `verifyOtp` مع رقم الهاتف والرمز للحصول على session. الحد الافتراضي بين طلبات OTP هو 60 ثانية، وتنتهي صلاحية OTP بعد ساعة. [1]

## Twilio Yemen

صفحة Twilio الرسمية الخاصة باليمن تحمل البلد `YE` والبادئة `+967`. وتذكر أن **Two-way SMS غير مدعوم**، وأن الأرقام المحلية والطويلة والقصيرة غير مدعومة كمرسلات داخل اليمن، بينما الرسائل الدولية قد تكون مدعومة. كما تذكر أن Dynamic Alphanumeric Sender ID ليس مدعومًا بشكل كامل وقد يظهر Sender ID عامًا بحسب الشبكة. هذا يعني أن Twilio ليس خيارًا يمكن اعتماده للإطلاق اليمني دون اختبار فعلي على شركات الاتصالات اليمنية. [2]

## الاستنتاج المؤقت

Phone OTP ممكن تقنيًا عبر Supabase، لكنه ليس مجانيًا؛ تكلفة Supabase نفسها لا تغني عن تكلفة مزود SMS، والسعر الفعلي يعتمد على الدولة والمسار والشبكة ونوع الرسالة ورسوم المزود. دعم اليمن والتسليم يجب اختبارهما قبل نقل النظام من Email Auth. لا يجوز عرض رقم نهائي بالدولار قبل فتح صفحة السعر الخاصة بالمزود وتحديد مسار Yemen/YE وحالة الحساب، لأن صفحات الأسعار تتغير وقد تضيف رسومًا على Verify أو carrier fees.

## المراجع

[1]: https://supabase.com/docs/guides/auth/phone-login "Supabase Phone Login and OTP"

[2]: https://www.twilio.com/en-us/guidelines/ye/sms "Twilio Yemen SMS Guidelines"

## أسعار وقيود إضافية

تُظهر صفحة Twilio الرسمية لأسعار اليمن سعر SMS الصادر **0.2929 دولار لكل segment** للرقم الدولي أو Alphanumeric Sender ID، مع احتمال إضافة رسوم carrier وتغيّر الأسعار، كما تعرض رقمًا دوليًا مستأجرًا بسعر ابتدائي **1.15 دولار شهريًا**. وبما أن الرسالة تُحاسب لكل segment، فإن رسائل OTP العربية أو الطويلة قد تتجاوز segment واحد. [3]

تذكر صفحة Twilio الخاصة بإرشادات اليمن أن Two-way SMS غير مدعوم، وأن Sender ID الأبجدي الديناميكي ليس مضمونًا بالكامل، وأن الأرقام المحلية/الدولية الطويلة والقصيرة لا تدعمها Twilio كمرسل في اليمن وفق الجدول المنشور. [2]

تذكر صفحة Vonage الرسمية لليمن أن Alphanumeric Sender ID مدعوم لكنه قد يُستبدل لضمان التسليم، وأن Generic Sender IDs مثل INFO وSMS وNOTICE ممنوعة، وأن P2P traffic محظور. لذلك يحتاج Vonage أيضًا إلى مراجعة استخدام OTP واختبارًا فعليًا قبل اعتماده. [4]

## حساب تقريبي غير ملزم

وفق السعر المنشور من Twilio فقط، فإن 1000 رسالة OTP من segment واحد تساوي تقريبًا 292.90 دولارًا قبل carrier fees وأي رسوم أخرى، بينما 100 رسالة تساوي تقريبًا 29.29 دولارًا. هذا ليس عرضًا نهائيًا ولا يثبت نجاح التسليم في اليمن؛ هو حساب مباشر للسعر المنشور وقت البحث.

## المراجع الإضافية

[3]: https://www.twilio.com/en-us/sms/pricing/ye "Twilio SMS Pricing in Yemen"

[4]: https://api.support.vonage.com/hc/en-us/articles/204017343-Yemen-SMS-Features-and-Restrictions "Vonage Yemen SMS Features and Restrictions"

## Bird/Yemen

توضح صفحة Bird الخاصة باليمن أن SMS وWhatsApp متاحان، لكن Two-way messaging غير متاح. كما تشترط تسجيل Alphanumeric Sender ID قبل التسليم، وتذكر أن وقت الإعداد قد يصل إلى **35 يوم عمل**، وأن المسار One-way فقط. صفحة الأسعار العامة التي فتحتها تعرض سعرًا عامًا للولايات المتحدة قدره 0.0074 دولار للرسالة ولا تعرض سعر اليمن في الصفحة المفتوحة؛ لذلك لا يجوز استخدام 0.0074 دولار كسعر لليمن. [5] [6]

[5]: https://bird.com/en-it/products/sms/destinations/yemen "Bird SMS to Yemen: sender types and rules"

[6]: https://bird.com/en-us/pricing/connectivity/sms "Bird SMS Pricing"

## مزودو البريد transactional دون Domain

توضح وثائق Resend الرسمية أن Resend يرسل باستخدام Domain يملكه المستخدم، وأنه يجب إضافة وتوثيق Domain واحد على الأقل قبل الإرسال؛ لذلك لا يحل مشكلة عدم شراء Domain. [7]

محاولة فتح رابط قديم في مركز مساعدة Brevo أعادت صفحة غير موجودة، لذلك لم أعتمد على مقتطفات البحث غير الرسمية لتأكيد متطلبات Brevo. عمليًا يمكن استخدام Gmail الحالي مباشرةً عبر SMTP في Supabase، مع اسم عرض مخصص، دون إدخال مزود ثالث أو تغيير عنوان From قبل امتلاك Domain.

[7]: https://resend.com/docs/dashboard/domains/introduction "Resend Verified Domains"
