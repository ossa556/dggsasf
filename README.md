# GHOST SHIFT

لعبة Roblox بين Ghosts وHunters فمحطة قطارات مهجورة عند **03:17**.
هاد المشروع بداية جديدة مستقلة، فيها أول نسخة قابلة للتجربة؛ ما كتبدّلش اللعبة القديمة ديالك.

ملفات التحميل موجودة مباشرة فالمستودع داخل `build/`:

- [ملف اللعبة لـRoblox Studio](build/GHOST-SHIFT.rbxlx): حل صفحة الملف فـGitHub واستعمل **Download raw file**.
- [نسخة المشروع كاملة ZIP](build/GHOST-SHIFT-source.zip).
- [التحقق من الملف وخطوات Windows](build/README.md).

الكود فيه محطة كتتبنى ملي كتشغل **Play**، فرق وجولات، تحول الأشباح، Sprint،
Detector، وCapture Pulse بست طلقات وReload ديال 2.5 ثانية. Coins وWins ديال الجلسة فقط.
الرشاش، القطار، الحفظ بـDataStore، المشتريات، الصوت والأنيميشن باقي مراحل جاية.

**بدا بـ[دليل فتح اللعبة وتجربة جوج لاعبين](docs/PLAYTEST.ar-MA.md).**
الملف اللي كيتفتح فـStudio هو `build/GHOST-SHIFT.rbxlx`؛ الماب كيبان منين كتدير Play.
Roblox Studio كيحتاج Windows أو macOS. هاد بيئة Linux ما شغلاتش اللعبة ولا Multiplayer؛
نجاح بناء الملف وفحص الكود ماشي تأكيد أن تجربة اللعب نجحات.

- [Roblox + Rojo على الحاسوب ديالك](docs/STUDIO_MIGRATION.ar-MA.md)
- [المراحل ومعايير النجاح](docs/DEVELOPMENT_PLAN.ar-MA.md)

`build/GHOST-SHIFT-source.zip` كيجمع الملفات ونسخة اللعبة. فك الضغط فالحاسوب باش تخدم محلياً.
تعديلات Codex فالسحابة ما كتدخلش تلقائياً لـStudio؛ خاص تحميل الملفات المحدثة أو سحبها من Git من بعد ما تتحفظ فيه.

```text
src/server/     Main + MapService + GameplayService + RoundService
src/client/     التحكم، HUD والكاميرا والمؤثرات المحلية
src/shared/     Config وRoundRules؛ بلا أسرار
tools/          تجهيز Linux، بناء وفحص المشروع، واستخراج اختياري لنسخ قديمة
tests/          اختبارات أداة الاستخراج ومنطق قرارات الجولات
```

لـCodex أو مطور داخل بيئة Linux، من جذر المشروع:

```bash
bash tools/setup_cloud.sh
python3 tools/check_project.py
python3 -m unittest discover -s tests -v
```

الأدوات مثبتة محلياً داخل `.tools`؛ Rojo **7.7.1** كيبني `build/GHOST-SHIFT.rbxlx`.
هاد النسخة مازال ماشي منتوج نهائي للنشر، والحماية ديال RemoteEvents ما كتساويش anti-cheat كامل.
