# Roblox + Rojo: تطوير النسخة الجديدة من الملفات

هاد المستودع فيه **نسخة جديدة مستقلة** ديال GHOST SHIFT. ما محتاجش ترفع اللعبة القديمة باش تبدا.
خلي الأصل محفوظ، وما تربطوش بهاد المشروع: الكود الجديد كيبني الماب ديالو ملي كتدير Play.

إلا بغيتي غير تجرب دابا، بدا بـ[دليل التجربة](PLAYTEST.ar-MA.md).
فتح `build/GHOST-SHIFT.rbxlx` ما كيحتاجش Rojo Plugin؛ Rojo كينفع للتعديل المباشر من الملفات.

## 1. شنو كيدير كل جزء

Roblox Studio هو فين كتجرب اللعبة وMultiplayer. ملفات `.luau` هي المصدر ديال الكود الجديد.
Rojo CLI كيبني Place، أو كيشغل سيرفر محلي باش Plugin ينقل التعديلات من الملفات لـStudio.

هاد البيئة السحابية كتعدل الكود وتفحصو وتبني `.rbxlx`؛ ما فيهاش Studio.
Studio ديالك ما يقدرش يتاصل مباشرة بـ`127.0.0.1` ديال البيئة السحابية.
للمزامنة، خاص **الملفات وRojo CLI وStudio يكونو فالحاسوب ديالك** على Windows أو macOS.
بلا Rojo محلي، نقدر نبقاو نتبادلو نسخ `.rbxlx` مبنية لكل مرحلة.
ما خاصنا لا كلمة السر ديالك، لا Cookie، لا الدخول لحسابك.

## 2. تثبيت Rojo فالحاسوب ديالك

1. حمل **Rojo CLI 7.7.1** المناسب للنظام ديالك من [GitHub الرسمي](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1).
2. فك الضغط. حط الملف التنفيذي فمجلد معروف وضيفو لـPATH باش الأمر `rojo` يخدم، أو استعمل المسار الكامل ديالو.
3. ثبت Plugin الرسمي حسب [تعليمات Rojo الرسمية](https://rojo.space/docs/v7/getting-started/installation/).
   تقدر تستعمل `rojo plugin install` فالحاسوب اللي فيه Studio، من بعد تسد وتعاود تحل Studio.
4. استعمل Plugin متوافق مع **7.7.1**؛ الأفضل نفس الإصدار. راجع التعليمات الرسمية قبل الترقية.
   أمر التثبيت يقدر يعوّض نسخة Plugin موجودة؛ ما تخلطش إصدارات مختلفة لنفس المشروع.
5. نزّل `build/GHOST-SHIFT-source.zip` وفك الضغط فالحاسوب، وحل Terminal أو PowerShell داخل المجلد اللي فيه `default.project.json`.

Rojo كيتبع **ملفات الحاسوب ديالك فقط**. منين Codex يعدل الكود فالسحابة، خاص تنزّل النسخة المحدثة وتستعملها محلياً،
أو تسحب التغييرات من Git من بعد ما تتحفظ فيه. ما كاينش تحكم مباشر ولا مزامنة تلقائية من السحابة لـStudio ديالك.

تحقق:

```bash
rojo --version
```

خاص يبان `Rojo 7.7.1`. إلا كان `rojo.exe` غير فالمجلد الحالي على Windows وماشي فـPATH،
استعمل `.\rojo.exe` بلاصة `rojo` فالأوامر.

## 3. المزامنة مع نسخة التطوير فقط

1. فتح `build/GHOST-SHIFT.rbxlx` الجديد فـStudio، وما تربطش اللعبة الأصلية.
2. وقف Play وأي Test قبل الاتصال.
3. من Terminal فمجلد المشروع شغّل:

```bash
rojo serve default.project.json
```

4. خليه خدام. فـPlugin ديال Rojo اتصل بـ`127.0.0.1` والمنفذ **34872**.
5. راجع التغييرات قبل المزامنة. المتوقع هو هاد السكريبتات، ماشي مجلدات فارغة:

```text
ReplicatedStorage/GhostShift
  Config                  ModuleScript
  RoundRules              ModuleScript
ServerScriptService/GhostShift
  Main                    Script
  MapService              ModuleScript
  GameplayService         ModuleScript
  RoundService            ModuleScript
StarterPlayer/StarterPlayerScripts/GhostShift
  Main                    LocalScript
```

الإعداد ما كيربطش Workspace أو Lighting أو Teams؛ MapService وMain كيوجدوهم أثناء التشغيل.
`$ignoreUnknownInstances: true` كيحافظ على العناصر غير المعروفة، ولكن عنصر بنفس الاسم والمسار يقدر يتبدّل.
إلا شفتي تغييرات كتهم لعبة قديمة أو حذف غير متوقع، وقف وراجع الملف المفتوح والمسارات.

6. من بعد المزامنة، دير Play وجرب. وقف Test وعاود شغلو بعد التغييرات الكبيرة باش الماب والجولات يبداو من جديد.
7. باش توقف Rojo، دير **Ctrl+C** فالـTerminal.

لبناء ملف مستقل محلياً، أنشئ مجلد `build` إذا ما كاينش، ثم:

```bash
rojo build default.project.json --output build/GHOST-SHIFT.rbxlx
```

هاد الأمر كيعوّض build بنفس الاسم؛ ما تستعملش مسار النسخة القديمة كوجهة للناتج.

## 4. أدوات البيئة السحابية

هاد الأوامر خاصة ببيئة Linux x86_64 من جذر المشروع؛ ماشي أوامر Command Bar ديال Studio:

```bash
bash tools/setup_cloud.sh
python3 tools/check_project.py
python3 -m unittest discover -s tests -v
```

الأدوات كتبقى محلياً فـ`.tools`، والناتج هو `build/GHOST-SHIFT.rbxlx`.
الفحص كيتحقق من syntax، قرارات الجولات الخالصة، ومواقع ومحتوى السكريبتات داخل build.
ما كيشغلش Roblox APIs أو Multiplayer. هادو خاصهم [تجربة Studio](PLAYTEST.ar-MA.md).

## 5. أرشفة اللعبة القديمة لاحقاً — اختياري

ما محتاجش ترفعها دابا. إلا احتجنا نقارنو نظام قديم، خرج نسخة احتياطية مستقلة من Studio بصيغة
**Roblox XML Place (`.rbxlx`)** وخلي الأصل بلا تعديل. تبديل امتداد `.rbxl` ما كيحوّلش الصيغة.

الأداة كتستخرج الأكواد والجرد فقط، وما كتشغلهمش وما كتدخلهمش فـRojo:

```bash
python3 tools/import_studio.py /path/to/GhostShift-old-backup.rbxlx --output imports/studio/archive-001
```

مجلد الناتج خاصو يكون جديد. النسخ الخام و`imports/studio/` مستثناة من Git افتراضياً.
الجرد كيسجل المسارات والأنواع وخصائص التشغيل؛ ماشي تحويل كامل للماب.
ما تنقلش كود قديم مباشرة لـ`src`: `script.Parent` وRunContext ونسخ الأحداث المكررة يقدرو يكسرو اللعب.
إلا تشاركات نسخة لاحقاً، تأكد ما فيهاش أسرار مكتوبة فالكود، وما تشارك حتى بيانات دخول.
