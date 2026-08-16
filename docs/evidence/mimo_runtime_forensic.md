# Mimo Runtime Forensic Evidence

## مصدر MuMu الخارجي

يوضح دليل MuMu الرسمي للمطورين أن اتصال ADB المعتاد يكون عبر `adb connect 127.0.0.1:7555`، وأنه يمكن استخدام أوامر `adb` لتثبيت APK وتشغيل التطبيقات وقراءة logcat وأخذ screenshots: [1].

لكن نسخة MuMu Player الحالية على جهاز المشروع أظهرت عبر `mumu-cli info --vmindex all` أن الجهاز `#0` يعمل على Android 15 وأن `adb_port` المعلن من RPC هو `16384`، مع `player_state=start_finished` و`sys.boot_completed=1`. منافذ TCP الظاهرة داخليًا في العملية تغيّرت إلى `23574` و`24576`، إلا أن اتصال Android SDK ADB بها ظل `offline` أو مرفوضًا. لذلك استُخدم المسار الرسمي المرفق `mumu-cli control` و`mumu-cli sh` كقناة تشغيل وقراءة بديلة، دون تجاوز صلاحيات النظام.

## Runtime test بعد الإصلاح

تم بناء APK Production النهائي بحجم `78.1MB` في `2026-08-16 21:26:30`، ثم تثبيته بنجاح عبر:

```text
mumu-cli control --vmindex 0 app install --apk D:\assalkom_fixed_final.apk
```

وأعاد الأمر:

```json
{"package":"com.assalkom.assalkom"}
```

بعد ذلك تم تشغيل الحزمة عبر `mumu-cli control --vmindex 0 app launch --package com.assalkom.assalkom`، وتنظيف logcat قبل الإقلاع. أظهر السجل:

```text
ActivityTaskManager: Displayed com.assalkom.assalkom/.MainActivity ... +1s18ms
ActivityTaskManager: Fully drawn com.assalkom.assalkom/.MainActivity ... +1s18ms
```

لم يظهر في filter الإقلاع أي `FATAL EXCEPTION` أو `AndroidRuntime` fatal أو `SocketException` أو `Timeout` أو `Postgrest` error. رسائل `HWComposer UNSUPPORTED` وSELinux audit الظاهرة من بيئة MuMu/Android وليست crash للتطبيق.

## الإصلاحات التي يغطيها APK

يتضمن الإصدار glass shimmer loading موحدًا بدل spinner الخام، فروع error صريحة بدل بقاء FutureBuilder في حالة انتظار، timeout قدره 12 ثانية لطلبات Supabase، منع `demo-customer` من الوصول إلى Production notifications ذات UUID، تثبيت futures في Home/Product/Store، وتثبيت PageController الخاص بمعرض المنتج خارج build. كما أزيل زر استعادة كلمة المرور غير المنفذ من Auth UI.

## الحالة المتبقية

تم إثبات build وinstall وlaunch وغياب crash عبر RPC. لم يُعتمد بعد نجاح Email/Google/Facebook التفاعلي أو قياس تجربة الوميض بصريًا من خلال logcat وحده؛ يلزم إكمال tap/input على شاشة Auth ثم التقاط النتيجة مع بقاء قناة RPC متاحة.

## References

[1]: https://www.mumuplayer.com/help/win/developers-essentials-manual.html "MuMuPlayer Windows Developers' Essentials: Manual"
