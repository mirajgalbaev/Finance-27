import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'no_tasks_found': 'No tasks found for the selected period.',
        'save': 'Save',
        'no_saved_titles': 'No saved titles yet.',
        'title_saved': 'Title saved to memory!',
        'title_already_saved': 'This title is already in memory.',
        'sub_task_info': 'If you do not add a sub-task, the Main Plan will be added to the selected days.',
        'please_enter_title': 'Please enter the Main Plan Title.',
        'please_select_date': 'Please select a date.',
        'time_label': 'Time:',
        'edit_main_title': 'Edit Main Title',
        'planner_setup': 'Planner Setup'
    },
    'tr': {
        'no_tasks_found': 'Seçili döneme ait görev bulunamadı.',
        'save': 'Kaydet',
        'no_saved_titles': 'Henüz kayıtlı başlık yok.',
        'title_saved': 'Başlık hafızaya kaydedildi!',
        'title_already_saved': 'Bu başlık zaten hafızada var.',
        'sub_task_info': 'Alt görev eklemezseniz Ana Plan seçili günlere eklenecektir.',
        'please_enter_title': 'Lütfen Ana Plan Başlığı girin.',
        'please_select_date': 'Lütfen tarih seçin.',
        'time_label': 'Saat:',
        'edit_main_title': 'Ana Başlığı Düzenle',
        'planner_setup': 'Planlayıcı Ayarları'
    },
    'ru': {
        'no_tasks_found': 'Задачи не найдены для выбранного периода.',
        'save': 'Сохранить',
        'no_saved_titles': 'Пока нет сохраненных заголовков.',
        'title_saved': 'Заголовок сохранен в память!',
        'title_already_saved': 'Этот заголовок уже есть в памяти.',
        'sub_task_info': 'Если вы не добавите подзадачу, Главный план будет добавлен на выбранные дни.',
        'please_enter_title': 'Пожалуйста, введите название Главного плана.',
        'please_select_date': 'Пожалуйста, выберите дату.',
        'time_label': 'Время:',
        'edit_main_title': 'Редактировать главный заголовок',
        'planner_setup': 'Настройка планировщика'
    },
    'kg': {
        'no_tasks_found': 'Тандалган мезгил үчүн тапшырмалар табылган жок.',
        'save': 'Сактоо',
        'no_saved_titles': 'Азырынча сакталган темалар жок.',
        'title_saved': 'Тема эс тутумга сакталды!',
        'title_already_saved': 'Бул тема эс тутумда бар.',
        'sub_task_info': 'Эгер сиз кошумча тапшырма кошпосоңуз, Негизги план тандалган күндөргө кошулат.',
        'please_enter_title': 'Сураныч, Негизги пландын темасын киргизиңиз.',
        'please_select_date': 'Сураныч, датаны тандаңыз.',
        'time_label': 'Убакыт:',
        'edit_main_title': 'Негизги теманы өзгөртүү',
        'planner_setup': 'Пландоочуну жөндөө'
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


planner = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with open(planner, 'r', encoding='utf-8') as f:
    p_content = f.read()

reps = {
    "Text('Seçili döneme ait görev bulunamadı.',": "Text(AppStrings.get(ref, 'no_tasks_found') ?? 'Seçili döneme ait görev bulunamadı.',",
    "child: Text('Kaydet')": "child: Text(AppStrings.get(ref, 'save') ?? 'Kaydet')",
    "Text('Henüz kayıtlı başlık yok.',": "Text(AppStrings.get(ref, 'no_saved_titles') ?? 'Henüz kayıtlı başlık yok.',",
    "Text('Başlık hafızaya kaydedildi!')": "Text(AppStrings.get(ref, 'title_saved') ?? 'Başlık hafızaya kaydedildi!')",
    "Text('Bu başlık zaten hafızada var.')": "Text(AppStrings.get(ref, 'title_already_saved') ?? 'Bu başlık zaten hafızada var.')",
    "Text('Alt görev eklemezseniz Ana Plan seçili günlere eklenecektir.',": "Text(AppStrings.get(ref, 'sub_task_info') ?? 'Alt görev eklemezseniz Ana Plan seçili günlere eklenecektir.',",
    "Text('Lütfen Ana Plan Başlığı girin.')": "Text(AppStrings.get(ref, 'please_enter_title') ?? 'Lütfen Ana Plan Başlığı girin.')",
    "Text('Lütfen tarih seçin.')": "Text(AppStrings.get(ref, 'please_select_date') ?? 'Lütfen tarih seçin.')",
    "Text('Saat:',": "Text(AppStrings.get(ref, 'time_label') ?? 'Saat:',",
    "Text('Ana Başlığı Düzenle')": "Text(AppStrings.get(ref, 'edit_main_title') ?? 'Ana Başlığı Düzenle')",
    "Text('Planner Setup',": "Text(AppStrings.get(ref, 'planner_setup') ?? 'Planner Setup',"
}

for k, v in reps.items():
    p_content = p_content.replace(k, v)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
