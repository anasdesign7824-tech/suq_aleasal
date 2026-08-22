# UX-06 — توحيد رفع الصور

## ما تغير

كان هناك مكوّنان بصريان لرفع الصور: `AssalImagePickerTile` و`AssalImageUploadSlot`. كلاهما يعرض صورة وزرًا، لكن اختلاف البنية يسبب شعورًا بأن الغلاف والشعار والملف والمنتج ينتمون إلى واجهات مختلفة. أصبح `AssalImageUploadSlot` غلافًا متوافقًا يعيد استخدام `AssalImagePickerTile` نفسه، وبقيت واجهته العامة وحقوله واستخداماته دون حذف.

النتيجة: الضغط على العنصر أو زر الصورة الداخلي يفتح الاختيار، وتغيير الصورة وإزالتها لهما نفس semantics وtooltip، مع fallback واحد وحالات فشل الصور نفسها. لا توجد خانة رابط صورة مستقلة في هذا المسار.

## الاختبار

| البوابة | النتيجة |
|---|---|
| `flutter analyze --no-pub` | PASS — No issues found |
| `unified_ui_test.dart` | PASS — 6 tests |
| `profile_reverify_widget_test.dart` | PASS |
| `merchant_store_channels_test.dart` | PASS — 3 حالات |

تم التحقق من استخدام `AssalImageUploadSlot` في فتح المتجر ومحرر المتجر قبل التوحيد؛ لذلك لم يُحذف المكوّن بل أُعيد توصيله بالمكوّن المشترك.
