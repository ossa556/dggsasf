# ربط Codex على Windows بـRoblox Studio

استعمل MCP المدمج فـRoblox Studio، حسب [دليل Roblox الرسمي](https://create.roblox.com/docs/studio/mcp).
هاد الربط كيسمح لـCodex المحلي يقرا المشروع، يعدّل السكريبتات ويتفاعل مع Play والـOutput.
Codex وStudio خاصهم يكونو خدامين على نفس حاسوب Windows.
هاد المحادثة السحابية ما كتتربطش تلقائياً بالسيرفر المحلي ديالك.

## الخطوات

1. حدّث Roblox Studio لآخر نسخة، وتأكد أن **Codex CLI** مثبت على Windows.
   إلا الأمر `codex --version` ما خدمش فـPowerShell، تبع [تعليمات تثبيت Codex الرسمية](https://developers.openai.com/codex/cli/).
2. فتح نسخة التطوير `GHOST-SHIFT.rbxlx`، ووقف Play.
3. فـStudio، حل **Assistant**.
4. كليكي **… → Manage MCP Servers**.
5. فعّل **Enable Studio as MCP server**.
6. فإعدادات MCP، وسّع **Quick connect** وفعّل **Codex CLI**.
7. سد وعاود حل Codex باش يقرا الإعداد الجديد. إلا ما بانش Codex فاللائحة، تأكد أنه مثبت وعاود حل Studio.
8. رجع لنفس لوحة MCP فـStudio. العلامة الخضرا وعدد clients المتصلين كيبينو أن الاتصال وقع.

هاد الطريقة كتستعمل MCP المدمج؛ ما كتحتاجش تنزيل السيرفر القديم `studio-rust-mcp-server`، اللي توقف تطويره.

## أول تحقق داخل Codex المحلي

فمحادثة Codex اللي خدامة على Windows، لصق:

```text
استعمل Roblox Studio MCP. نادِ list_roblox_studios وأعطني اسم اللعبة المفتوحة وstudio_id.
اختار نسخة GHOST SHIFT الصحيحة، واقرأ get_studio_state ثم لائحة سكريبتات GhostShift.
بدا بالقراءة فقط باش نتحقق من الربط، ومن بعد نكملو تطوير المشروع.
```

ملي يكون أكثر من Studio مفتوح، خاص Codex يختار `studio_id` الصحيح ويستعملو فالأدوات الموالية.
وجود الإعداد فـ`codex mcp list` ما كيأكدش وحده أن Studio متصل؛ خاص نداء أداة فعلي يرجع معلومات اللعبة.

## إلا Quick connect ما خدمش

الدليل الرسمي كيعطي أمر السيرفر على Windows:

```text
cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
```

تأكد أن الملف موجود فـPowerShell:

```powershell
Test-Path "$env:LOCALAPPDATA\Roblox\mcp.bat"
codex mcp list
```

إلا النتيجة `False`، حدّث Studio وراجع تفعيل MCP أولاً.
استعمل إعداد Quick connect ديال Studio باش يسجل الأمر والمسار عند Codex.
إلا بان خطأ، احتفظ بنصه وبنتيجة هاد التحقق باش نصلحو السبب المحدد.

MCP كيعطي للعميل قدرة القراءة والتعديل فاللعبة المفتوحة؛ خدم بنسخة التطوير اللي محفوظة عندك.
ما خاص حتى كلمة سر، Cookie أو Roblox API key يتشارك فالمحادثة.

## الفرق مع ملفات GitHub

MCP كيتعامل مع Studio المفتوح. Rojo كيزامن ملفات الحاسوب نحو Studio.
تعديلات MCP ما كتدخلش تلقائياً لملفات Rojo أو GitHub؛ خاص نراجعوها وننقلوها للمصدر قبل أي مزامنة كتقدر تعوّضها.
من بعد نجاح الربط نختبرو نفس المشروع الموجود؛ ما محتاجينش نعاودو بناء اللعبة من الصفر.
