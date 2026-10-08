import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'export_daily_plan_format': 'In what format do you want to save your daily plan?',
        'export_success_png': 'Save Successful! PNG File: {path}',
        'export_success_pdf': 'Save Successful! PDF File: {path}',
        'export_failed': 'Save failed: {error}',
        'daily_tasks_table': 'DAILY TASKS TABLE',
        'monthly_tasks_table': 'MONTHLY TASKS TABLE',
        'add_all_tasks': 'ADD ALL ({count} Tasks)',
        'add_plan': 'ADD PLAN',
        'days_selected': '{count} Days Selected',
        'edit_title': 'Edit Title',
        'enter_new_title': 'Enter new title...',
        'saved_templates': 'Saved Templates',
        'main_plan_title': 'Main Plan Title',
        'enter_plan_name': 'Enter plan name...',
        'select_time': 'Select Time',
        'save_title_to_memory': 'Save Title to Memory',
        'saved_titles': 'Saved Titles',
        'sub_tasks': 'Sub Tasks',
        'add_task_upper': 'ADD TASK',
        'sub_task_index': 'Sub Task #{index}',
        'main_plan_added': 'Main Plan Added!',
        'sub_tasks_added': 'Sub Tasks Added!',
        'task_stats': 'TASK STATISTICS',
        'total_task': 'TOTAL\nTASKS',
        'completed_task': 'COMPLETED',
        'pending_task': 'PENDING',
        'completion_rate': 'Completion Rate',
        'delete_all': 'Delete All',
        'delete_upper': 'DELETE',
        'export_title': 'Export'
    },
    'tr': {
        'export_daily_plan_format': 'Günlük planınızı hangi formatta kaydetmek istiyorsunuz?',
        'export_success_png': 'Kayıt Başarılı! PNG Dosyası: {path}',
        'export_success_pdf': 'Kayıt Başarılı! PDF Dosyası: {path}',
        'export_failed': 'Kayıt başarısız: {error}',
        'daily_tasks_table': 'GÜNLÜK GÖREVLER TABLOSU',
        'monthly_tasks_table': 'AYLIK GÖREVLER TABLOSU',
        'add_all_tasks': 'TÜMÜNÜ EKLE ({count} Görev)',
        'add_plan': 'PLANI EKLE',
        'days_selected': '{count} Gün Seçildi',
        'edit_title': 'Başlığı Düzenle',
        'enter_new_title': 'Yeni başlık girin...',
        'saved_templates': 'Kayıtlı Şablonlar',
        'main_plan_title': 'Ana Plan Başlığı',
        'enter_plan_name': 'Plan ismi girin...',
        'select_time': 'Saat Seç',
        'save_title_to_memory': 'Başlığı Hafızaya Kaydet',
        'saved_titles': 'Kayıtlı Başlıklar',
        'sub_tasks': 'Alt Görevler',
        'add_task_upper': 'GÖREV EKLE',
        'sub_task_index': 'Alt Görev #{index}',
        'main_plan_added': 'Ana Plan Eklendi!',
        'sub_tasks_added': 'Alt Görevler Eklendi!',
        'task_stats': 'GÖREV İSTATİSTİKLERİ',
        'total_task': 'TOPLAM\nGÖREV',
        'completed_task': 'TAMAMLANAN',
        'pending_task': 'BEKLEYEN',
        'completion_rate': 'Tamamlanma Oranı',
        'delete_all': 'Tümünü Sil',
        'delete_upper': 'SİL',
        'export_title': 'Dışa Aktar'
    },
    'ru': {
        'export_daily_plan_format': 'В каком формате вы хотите сохранить ежедневный план?',
        'export_success_png': 'Успешное сохранение! PNG файл: {path}',
        'export_success_pdf': 'Успешное сохранение! PDF файл: {path}',
        'export_failed': 'Не удалось сохранить: {error}',
        'daily_tasks_table': 'ТАБЛИЦА ЕЖЕДНЕВНЫХ ЗАДАЧ',
        'monthly_tasks_table': 'ТАБЛИЦА ЕЖЕМЕСЯЧНЫХ ЗАДАЧ',
        'add_all_tasks': 'ДОБАВИТЬ ВСЕ ({count} Задач)',
        'add_plan': 'ДОБАВИТЬ ПЛАН',
        'days_selected': '{count} Дней Выбрано',
        'edit_title': 'Изменить Заголовок',
        'enter_new_title': 'Введите новый заголовок...',
        'saved_templates': 'Сохраненные Шаблоны',
        'main_plan_title': 'Заголовок Основного Плана',
        'enter_plan_name': 'Введите название плана...',
        'select_time': 'Выбрать Время',
        'save_title_to_memory': 'Сохранить Заголовок в Память',
        'saved_titles': 'Сохраненные Заголовки',
        'sub_tasks': 'Подзадачи',
        'add_task_upper': 'ДОБАВИТЬ ЗАДАЧУ',
        'sub_task_index': 'Подзадача #{index}',
        'main_plan_added': 'Основной План Добавлен!',
        'sub_tasks_added': 'Подзадачи Добавлены!',
        'task_stats': 'СТАТИСТИКА ЗАДАЧ',
        'total_task': 'ВСЕГО\nЗАДАЧ',
        'completed_task': 'ЗАВЕРШЕНО',
        'pending_task': 'В ОЖИДАНИИ',
        'completion_rate': 'Уровень Выполнения',
        'delete_all': 'Удалить Все',
        'delete_upper': 'УДАЛИТЬ',
        'export_title': 'Экспорт'
    },
    'kg': {
        'export_daily_plan_format': 'Күнүмдүк планды кайсы форматта сактагыңыз келет?',
        'export_success_png': 'Ийгиликтүү сакталды! PNG Файл: {path}',
        'export_success_pdf': 'Ийгиликтүү сакталды! PDF Файл: {path}',
        'export_failed': 'Сактоо ишке ашкан жок: {error}',
        'daily_tasks_table': 'КҮНҮМДҮК ТАПШЫРМАЛАР ТАБЛИЦАСЫ',
        'monthly_tasks_table': 'АЙЛЫК ТАПШЫРМАЛАР ТАБЛИЦАСЫ',
        'add_all_tasks': 'БААРЫН КОШУУ ({count} Тапшырма)',
        'add_plan': 'ПЛАНДЫ КОШУУ',
        'days_selected': '{count} Күн Тандалды',
        'edit_title': 'Аталышты Өзгөртүү',
        'enter_new_title': 'Жаңы аталышты киргизиңиз...',
        'saved_templates': 'Сакталган Калыптар',
        'main_plan_title': 'Негизги План Аталышы',
        'enter_plan_name': 'Пландын атын киргизиңиз...',
        'select_time': 'Убакытты Тандоо',
        'save_title_to_memory': 'Аталышты Эстутумга Сактоо',
        'saved_titles': 'Сакталган Аталыштар',
        'sub_tasks': 'Кошумча Тапшырмалар',
        'add_task_upper': 'ТАПШЫРМА КОШУУ',
        'sub_task_index': 'Кошумча Тапшырма #{index}',
        'main_plan_added': 'Негизги План Кошулду!',
        'sub_tasks_added': 'Кошумча Тапшырмалар Кошулду!',
        'task_stats': 'ТАПШЫРМА СТАТИСТИКАСЫ',
        'total_task': 'БАРДЫГЫ\nТАПШЫРМА',
        'completed_task': 'АТКАРЫЛГАН',
        'pending_task': 'КҮТҮЛҮҮДӨ',
        'completion_rate': 'Аткаруу Деңгээли',
        'delete_all': 'Баарын Өчүрүү',
        'delete_upper': 'ӨЧҮРҮҮ',
        'export_title': 'Экспорттоо'
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

# Replace all these hardcoded strings with AppStrings.get
replacements = {
    "'Günlük planınızı hangi formatta kaydetmek istiyorsunuz?'": "(AppStrings.get(ref, 'export_daily_plan_format') ?? 'Günlük planınızı hangi formatta kaydetmek istiyorsunuz?')",
    "'Kayıt Başarılı! PNG Dosyası: $filePath'": "(AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası: {path}').replaceAll('{path}', filePath)",
    "'Kayıt Başarılı! PDF Dosyası: $filePath'": "(AppStrings.get(ref, 'export_success_pdf') ?? 'Kayıt Başarılı! PDF Dosyası: {path}').replaceAll('{path}', filePath)",
    "'Kayıt başarısız: $e'": "(AppStrings.get(ref, 'export_failed') ?? 'Kayıt başarısız: {error}').replaceAll('{error}', e.toString())",
    "'GÜNLÜK GÖREVLER TABLOSU'": "(AppStrings.get(ref, 'daily_tasks_table') ?? 'GÜNLÜK GÖREVLER TABLOSU')",
    "'AYLIK GÖREVLER TABLOSU'": "(AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GÖREVLER TABLOSU')",
    "'TÜMÜNÜ EKLE (${_subTasks.length} Görev)'": "(AppStrings.get(ref, 'add_all_tasks')?.replaceAll('{count}', '${_subTasks.length}') ?? 'TÜMÜNÜ EKLE (${_subTasks.length} Görev)')",
    "'PLANI EKLE'": "(AppStrings.get(ref, 'add_plan') ?? 'PLANI EKLE')",
    "'${_globalDates.length} Gün Seçildi'": "(AppStrings.get(ref, 'days_selected')?.replaceAll('{count}', '${_globalDates.length}') ?? '${_globalDates.length} Gün Seçildi')",
    "'Başlığı Düzenle'": "(AppStrings.get(ref, 'edit_title') ?? 'Başlığı Düzenle')",
    "'Yeni başlık girin...'": "(AppStrings.get(ref, 'enter_new_title') ?? 'Yeni başlık girin...')",
    "'Kayıtlı Şablonlar'": "(AppStrings.get(ref, 'saved_templates') ?? 'Kayıtlı Şablonlar')",
    "'Ana Plan Başlığı'": "(AppStrings.get(ref, 'main_plan_title') ?? 'Ana Plan Başlığı')",
    "'Plan ismi girin...'": "(AppStrings.get(ref, 'enter_plan_name') ?? 'Plan ismi girin...')",
    "'Saat Seç'": "(AppStrings.get(ref, 'select_time') ?? 'Saat Seç')",
    "'Başlığı Hafızaya Kaydet'": "(AppStrings.get(ref, 'save_title_to_memory') ?? 'Başlığı Hafızaya Kaydet')",
    "'Kayıtlı Başlıklar'": "(AppStrings.get(ref, 'saved_titles') ?? 'Kayıtlı Başlıklar')",
    "'Alt Görevler'": "(AppStrings.get(ref, 'sub_tasks') ?? 'Alt Görevler')",
    "'GÖREV EKLE'": "(AppStrings.get(ref, 'add_task_upper') ?? 'GÖREV EKLE')",
    "'Alt Görev #${index + 1}'": "(AppStrings.get(ref, 'sub_task_index')?.replaceAll('{index}', '${index + 1}') ?? 'Alt Görev #${index + 1}')",
    "'Ana Plan Eklendi!'": "(AppStrings.get(ref, 'main_plan_added') ?? 'Ana Plan Eklendi!')",
    "'Alt Görevler Eklendi!'": "(AppStrings.get(ref, 'sub_tasks_added') ?? 'Alt Görevler Eklendi!')",
    "'GÖREV İSTATİSTİKLERİ'": "(AppStrings.get(ref, 'task_stats') ?? 'GÖREV İSTATİSTİKLERİ')",
    "'TOPLAM\\nGÖREV'": "(AppStrings.get(ref, 'total_task') ?? 'TOPLAM\\nGÖREV')",
    "'TAMAMLANAN'": "(AppStrings.get(ref, 'completed_task') ?? 'TAMAMLANAN')",
    "'BEKLEYEN'": "(AppStrings.get(ref, 'pending_task') ?? 'BEKLEYEN')",
    "'Tamamlanma Oranı'": "(AppStrings.get(ref, 'completion_rate') ?? 'Tamamlanma Oranı')",
    "'Tümünü Sil'": "(AppStrings.get(ref, 'delete_all') ?? 'Tümünü Sil')",
    "'SİL'": "(AppStrings.get(ref, 'delete_upper') ?? 'SİL')",
    "'Dışa Aktar'": "(AppStrings.get(ref, 'export_title') ?? 'Dışa Aktar')"
}

for old, new in replacements.items():
    p_content = p_content.replace(old, new)

# One special case for Task stats string concatenation:
# Text('${_isDailyTab ? 'GÜNLÜK' : 'AYLIK'} GÖREV İSTATİSTİKLERİ'
p_content = p_content.replace(
    "Text('${_isDailyTab ? 'GÜNLÜK' : 'AYLIK'} GÖREV İSTATİSTİKLERİ'",
    "Text('${_isDailyTab ? (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK') : (AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK')} ' + (AppStrings.get(ref, 'task_stats') ?? 'GÖREV İSTATİSTİKLERİ')"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
