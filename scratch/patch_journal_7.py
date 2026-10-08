import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'download_report_title': 'REPORT DOWNLOAD',
        'export_format_question': 'In which format do you want to save this war report?',
        'export_success_png': 'Save Successful! PNG File: {path}',
        'export_success_pdf': 'Save Successful! PDF File: {path}',
        'export_failed': 'Save failed: {error}'
    },
    'tr': {
        'download_report_title': 'RAPORUNU İNDİR',
        'export_format_question': 'Bu savaş raporunu hangi formatta kaydetmek istiyorsunuz?',
        'export_success_png': 'Kayıt Başarılı! PNG Dosyası: {path}',
        'export_success_pdf': 'Kayıt Başarılı! PDF Dosyası: {path}',
        'export_failed': 'Kayıt başarısız: {error}'
    },
    'ru': {
        'download_report_title': 'СКАЧАТЬ ОТЧЕТ',
        'export_format_question': 'В каком формате вы хотите сохранить этот военный отчет?',
        'export_success_png': 'Успешно сохранено! PNG файл: {path}',
        'export_success_pdf': 'Успешно сохранено! PDF файл: {path}',
        'export_failed': 'Ошибка сохранения: {error}'
    },
    'kg': {
        'download_report_title': 'ОТЧЕТТУ ЖҮКТӨӨ',
        'export_format_question': 'Бул согуштук отчетту кайсы форматта сактагыңыз келет?',
        'export_success_png': 'Ийгиликтүү сакталды! PNG файлы: {path}',
        'export_success_pdf': 'Ийгиликтүү сакталды! PDF файлы: {path}',
        'export_failed': 'Сактоо ишке ашкан жок: {error}'
    }
}

with open(loc_file, 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
current_lang = None

for line in lines:
    lang_match = re.match(r"^\s*'([a-z]{2})':\s*\{\s*$", line)
    if lang_match:
        current_lang = lang_match.group(1)
        new_lines.append(line)
        if current_lang in additions:
            for k, v in additions[current_lang].items():
                if f"'{k}':" not in content:
                    v_escaped = v.replace('$', '\\$').replace("'", "\\'")
                    new_lines.append(f"      '{k}': '{v_escaped}',")
        continue
    if current_lang is not None and line.strip() == '},':
        current_lang = None
    new_lines.append(line)

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))


journal = r'C:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart'
with open(journal, 'r', encoding='utf-8') as f:
    j_content = f.read()

j_content = j_content.replace(
    "Text('$exchange Raporunu İndir'",
    "Text('${exchange.toUpperCase()} ${AppStrings.get(ref, 'download_report_title') ?? 'RAPORUNU İNDİR'}'"
)
j_content = j_content.replace(
    "const Text('Bu savaş raporunu hangi formatta kaydetmek istiyorsunuz?'",
    "Text(AppStrings.get(ref, 'export_format_question') ?? 'Bu savaş raporunu hangi formatta kaydetmek istiyorsunuz?'"
)
j_content = j_content.replace(
    "Text('Kayıt Başarılı! PNG Dosyası: $filePath')",
    "Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası: {path}').replaceAll('{path}', filePath))"
)
j_content = j_content.replace(
    "Text('Kayıt Başarılı! PDF Dosyası: $filePath')",
    "Text((AppStrings.get(ref, 'export_success_pdf') ?? 'Kayıt Başarılı! PDF Dosyası: {path}').replaceAll('{path}', filePath))"
)
j_content = j_content.replace(
    "Text('Kayıt başarısız: $e')",
    "Text((AppStrings.get(ref, 'export_failed') ?? 'Kayıt başarısız: {error}').replaceAll('{error}', e.toString()))"
)

with open(journal, 'w', encoding='utf-8') as f:
    f.write(j_content)

print("Patch complete!")
