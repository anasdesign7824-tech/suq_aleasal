# Phase 3 — Design System عربي موحد

## الهدف

تحويل نتائج المرجع البصري والهوية المرفقة إلى **Design System Contract** قابل للاستخدام في Flutter/Dart ومشاريع Web، مع الحفاظ على العربية أولًا وRTL، واستخدام IBM Plex Sans Arabic، ومنع القيم العشوائية داخل الشاشات.

## النطاق

تتضمن المرحلة تعريف Color Tokens وTypography Tokens وSpacing وRadius وElevation وStates، ومبادئ AppBars وNavigation وButtons وCards وInputs وSearch وFilters وBadges وChips وDialogs وLoading/Empty/Error States. لا تنفذ هذه المرحلة User Journey أو Features أو Supabase.

## مسارات التوافق

| المسار | المخرج |
|---|---|
| Flutter/Dart | Tokens وعقود Dart قابلة للاستهلاك من التطبيق |
| Web | CSS Variables وTypeScript tokens عند الحاجة لمشروعي Admin وLanding |
| الهوية | مصدر واحد للألوان والخط والأوزان، مع تحويلات تقنية لا تغيّر الدلالة |

## القرارات الأولية

تعتمد الهوية على البرتقالي العسلي، البرتقالي الفاتح، البني الأرضي، البني العميق، والكريمي الدافئ، مع حالات وظيفية منسجمة مع الدفء العام. يعتمد الخط IBM Plex Sans Arabic بالأوزان المرفقة، مع سلم واضح للأحجام وارتفاعات الأسطر. تعتمد البطاقات حواف ناعمة وحدودًا خفيفة وظلالًا لينة، وتُبنى التباينات للحفاظ على القراءة.

## بوابة المرحلة

تُطبق: `PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE → GIT COMMIT → ACCEPTANCE GATE`. لا يُسمح بإنشاء Feature أو ربط Supabase قبل اجتياز المرحلة.
