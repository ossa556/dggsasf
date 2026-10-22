# تحميل GHOST SHIFT على Windows

هاد المجلد فيه نفس ملف اللعبة اللي تْبنى من قبل. ما تعاودش بناء اللعبة ولا تبدّل حتى سكريبت باش نصلحو التحميل.

- [GHOST-SHIFT.rbxlx](GHOST-SHIFT.rbxlx): ملف Roblox Studio.
- [GHOST-SHIFT-source.zip](GHOST-SHIFT-source.zip): نسخة ملفات المشروع مع اللعبة.
- [SHA256SUMS.txt](SHA256SUMS.txt): بصمات الملفات باش تتأكد من سلامة التحميل.

1. حل صفحة `GHOST-SHIFT.rbxlx` فـGitHub، وكليكي على زر **Download raw file** فالجهة العليا ديال الملف.
2. حفظو على Windows باسم `GHOST-SHIFT.rbxlx`.
3. فـRoblox Studio اختار **File → Open from File…** أو **Ctrl+O** وافتح الملف.
4. دير **Play** باش تتبنى المحطة. الجولة كتحتاج **Test → Server & Clients → 2 Players**.

التفاصيل والتحكم فـ[دليل التجربة](../docs/PLAYTEST.ar-MA.md).

## التحقق اللي تدار فعلاً

- حجم الملف: **60,623 bytes**.
- صيغة Roblox XML **version 4** سليمة.
- **14 instances** فيها **7 scripts** فالمسارات والأنواع المنتظرة.
- Source ديال السكريبتات السبعة مطابق لملفات `src/`، وداز فحص Luau **0.743**.
- Rojo **7.7.1** قرا نفس الملف عبر `syncback --dry-run` بلا تغيير الملفات، وتعرف على الخدمات الثلاثة.
- SHA-256 ديال نفس ملف اللعبة:

```text
5dd354d7b53cbf1ea8d6738e85cfc0eba582240b0154d2885eebff5ab883b630
```

تقدر تتحقق بعد التحميل فـPowerShell:

```powershell
Get-FileHash .\GHOST-SHIFT.rbxlx -Algorithm SHA256
```

Roblox Studio وMultiplayer ما تشغلوش داخل بيئة Linux؛ هاد التحقق كيأكد الصيغة والمصادر، وتجربة اللعب باقية خاصها Studio.
