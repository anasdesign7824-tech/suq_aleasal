# TASK 070 — دليل حالة فراغ المتاجر

## نطاق المهمة

تغطي المهمة عدم وجود متاجر منشورة، والتمييز بين فراغ المصدر الحقيقي وعدم تطابق البحث أو الفلاتر. يجب أن يتلقى المستخدم رسالة عربية واضحة وإجراء استرداد حقيقي دون بيانات ثابتة أو زر ميت.

## نتيجة جرد المصدر

المراجع `screens/070_state_empty_stores.png` و`explanations/070_state_empty_stores.md` غير موجودة في checkout الحالي، كما يثبت خط الأساس العام. لم تُنشأ صورة أو عقد بديل ولم تُعلن مطابقة بصرية.

## الفجوة والإصلاح

كان `StoresScreen` يحول نتيجة الفلترة الفارغة إلى `AssalMessageCard` عامة بلا إجراء، وكانت نتيجة `AssalEmpty` المصدرية تمر برسالة المصدر دون CTA موجه. استُخدمت قدرة CTA المشتركة التي أُضيفت في TASK 069: عند فراغ المصدر تعرض الشاشة «لا توجد متاجر منشورة الآن. جرّب تحديث القائمة أو مسح الفلاتر.» مع «مسح البحث والفلاتر» الذي يستدعي `_resetFilters` الحقيقي ويعيد طلب `listStores`. وعند وجود متاجر في المصدر لكن عدم تطابق البحث تعرض «لا توجد متاجر مطابقة للبحث أو الفلاتر الحالية.» مع الإجراء نفسه. لم يُضف endpoint أو جدول أو صلاحية أو بيانات متجر اصطناعية.

## الاختبارات

```text
flutter test --no-pub test/task070_empty_stores_test.dart
00:04 +2: All tests passed!

flutter analyze --no-pub
No issues found!

flutter test --no-pub test/task069_empty_products_test.dart
00:05 +2: All tests passed!

flutter test --no-pub test/task014_stores_list_test.dart --plain-name 'TASK 014 searches, filters, and refreshes source stores'
00:03 +1: All tests passed!

flutter test --no-pub test/task014_stores_list_test.dart --plain-name 'TASK 014 opens the real store profile from the list'
00:03 +1: All tests passed!

flutter test --no-pub test/task009_store_card_test.dart --plain-name 'TASK 009 renders the unified store card contract'
00:03 +1: All tests passed!

flutter test --no-pub test/task009_store_card_test.dart --plain-name 'TASK 009 keeps the store card usable at compact width'
00:02 +1: All tests passed!
```

اختبار TASK 070 يستخدم مصدر Demo مستقلًا يحوي صفر متجر، ومصدرًا ثانيًا يحوي متجرًا واحدًا لتثبيت الفرق بين empty source وfilter mismatch. كما تم تحديث توقع regression TASK 014 لأن الرسالة الجديدة أكثر تحديدًا ومقصودة.

## القبول والحدود

القبول الوظيفي: **PASS**. لا تغيير DB/API/RLS/permissions. القبول البصري: **BLOCKED** لفقدان PNG/Markdown TASK 070. لا يثبت هذا الاختبار مزامنة المتاجر في Production أو قبول أجهزة متعددة.
