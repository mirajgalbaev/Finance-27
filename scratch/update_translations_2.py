import re

# 1. Update localization_provider.dart
loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'jan': 'January', 'feb': 'February', 'mar': 'March', 'apr': 'April',
        'may': 'May', 'jun': 'June', 'jul': 'July', 'aug': 'August',
        'sep': 'September', 'oct': 'October', 'nov': 'November', 'dec': 'December',
        'year_suffix': ' Year',
        'all_time_lifetime': 'All (Lifetime)',
        'apply': 'Apply',
        'war_plan_ops': 'WAR PLAN (Trades & Tasks)',
        'goals_progress': 'GOALS (Overall Progress)',
        'net_pnl': 'Net PnL (Profit/Loss)',
        'active_fin_goals': 'Active Financial Goals',
        'active_prog_goals': 'Active Progress Goals',
        'completed_fin_goals': 'Completed Financial Goals',
        'completed_prog_goals': 'Completed Progress Goals',
        'daily_target_units': 'Daily Target: {daily} Units • Monthly: {monthly} Units',
        'fin_goal_label': 'Financial Goal',
        'prog_goal_label': 'Progress Goal (e.g. Learn a Language)',
        'units': 'Units',
        'currency': 'Currency',
        'goal_not_approved': 'Goal not approved: Progress goals must have at least 1 unit per day. Please select a closer date or increase the target units.',
        'reached_goal_msg': 'You have successfully reached your goal:\\n{title}',
        'remaining_units': 'Remaining: {amount} Units',
        'no_deposits_yet': 'No deposits yet. Start saving!',
        'source_note_fin': 'Source / Note (e.g. Salary)',
        'source_note_prog': 'Note (e.g. Day 1 Workout)',
        'added_units_day': 'Added Units / Day'
    },
    'tr': {
        'jan': 'Ocak', 'feb': 'Şubat', 'mar': 'Mart', 'apr': 'Nisan',
        'may': 'Mayıs', 'jun': 'Haziran', 'jul': 'Temmuz', 'aug': 'Ağustos',
        'sep': 'Eylül', 'oct': 'Ekim', 'nov': 'Kasım', 'dec': 'Aralık',
        'year_suffix': ' Yılı',
        'all_time_lifetime': 'Tümü (Ömür Boyu)',
        'apply': 'Uygula',
        'war_plan_ops': 'SAVAŞ PLANI (İşlemler & Görevler)',
        'goals_progress': 'HEDEFLER (Genel İlerleme)',
        'net_pnl': 'Net PnL (Kâr/Zarar)',
        'active_fin_goals': 'Aktif Finansal Hedefler',
        'active_prog_goals': 'Aktif İlerleme Hedefleri',
        'completed_fin_goals': 'Tamamlanan Finansal Hedefler',
        'completed_prog_goals': 'Tamamlanan İlerleme Hedefleri',
        'daily_target_units': 'Günlük Hedef: {daily} Adet • Aylık: {monthly} Adet',
        'fin_goal_label': 'Finansal Hedef',
        'prog_goal_label': 'İlerleme Hedefi (Örn: Dil Öğrenme)',
        'units': 'Adet',
        'currency': 'Para Birimi',
        'goal_not_approved': 'Hedef Onaylanmadı: İlerleme hedeflerinde günlük hedef en az 1 adet olmalıdır. Lütfen daha yakın bir tarih seçin veya hedef adedini artırın.',
        'reached_goal_msg': 'You have successfully reached your goal:\\n{title}', # kept original behavior for TR but translated below actually:
        'remaining_units': 'Kalan: {amount} Adet',
        'no_deposits_yet': 'No deposits yet. Start saving!', # kept original behavior for TR but translated below actually:
        'source_note_fin': 'Kaynak / Not (Örn: Maaş)',
        'source_note_prog': 'Not (Örn: 1. Gün Antrenmanı)',
        'added_units_day': 'Eklenen Adet / Gün'
    },
    'ru': {
        'jan': 'Январь', 'feb': 'Февраль', 'mar': 'Март', 'apr': 'Апрель',
        'may': 'Май', 'jun': 'Июнь', 'jul': 'Июль', 'aug': 'Август',
        'sep': 'Сентябрь', 'oct': 'Октябрь', 'nov': 'Ноябрь', 'dec': 'Декабрь',
        'year_suffix': ' Год',
        'all_time_lifetime': 'Все (за все время)',
        'apply': 'Применить',
        'war_plan_ops': 'ПЛАН ВОЙНЫ (Сделки и Задачи)',
        'goals_progress': 'ЦЕЛИ (Общий прогресс)',
        'net_pnl': 'Чистая прибыль (PnL)',
        'active_fin_goals': 'Активные финансовые цели',
        'active_prog_goals': 'Активные цели прогресса',
        'completed_fin_goals': 'Завершенные финансовые цели',
        'completed_prog_goals': 'Завершенные цели прогресса',
        'daily_target_units': 'Дневная цель: {daily} ед. • Месяц: {monthly} ед.',
        'fin_goal_label': 'Финансовая цель',
        'prog_goal_label': 'Цель прогресса (напр. Выучить язык)',
        'units': 'Единицы',
        'currency': 'Валюта',
        'goal_not_approved': 'Цель не утверждена: Дневная цель должна быть не менее 1 единицы. Выберите более близкую дату или увеличьте количество единиц.',
        'reached_goal_msg': 'Вы успешно достигли цели:\\n{title}',
        'remaining_units': 'Осталось: {amount} Единиц',
        'no_deposits_yet': 'Пока нет вложений. Начните копить!',
        'source_note_fin': 'Источник / Заметка (напр. Зарплата)',
        'source_note_prog': 'Заметка (напр. 1-й день тренировки)',
        'added_units_day': 'Добавленные единицы / День'
    },
    'kg': {
        'jan': 'Үчтүн айы', 'feb': 'Бирдин айы', 'mar': 'Жалган куран', 'apr': 'Чын куран',
        'may': 'Бугу', 'jun': 'Кулжа', 'jul': 'Теке', 'aug': 'Баш оона',
        'sep': 'Аяк оона', 'oct': 'Тогуздун айы', 'nov': 'Жетинин айы', 'dec': 'Бештин айы',
        'year_suffix': ' Жылы',
        'all_time_lifetime': 'Баардыгы (Өмүр бою)',
        'apply': 'Колдонуу',
        'war_plan_ops': 'СОГУШ ПЛАНЫ (Транзакциялар жана Тапшырмалар)',
        'goals_progress': 'МАКСАТТАР (Жалпы прогресс)',
        'net_pnl': 'Таза Пайда (PnL)',
        'active_fin_goals': 'Активдүү финансылык максаттар',
        'active_prog_goals': 'Активдүү прогресс максаттары',
        'completed_fin_goals': 'Аткарылган финансылык максаттар',
        'completed_prog_goals': 'Аткарылган прогресс максаттары',
        'daily_target_units': 'Күнүмдүк максат: {daily} даана • Айлык: {monthly} даана',
        'fin_goal_label': 'Финансылык максат',
        'prog_goal_label': 'Прогресс максаты (мис. Тил үйрөнүү)',
        'units': 'Даана',
        'currency': 'Валюта',
        'goal_not_approved': 'Максат бекитилген жок: Күнүмдүк максат кеминде 1 даана болушу керек. Жакыныраак күндү тандаңыз же максаттын санын көбөйтүңүз.',
        'reached_goal_msg': 'Сиз максатыңызга ийгиликтүү жеттиңиз:\\n{title}',
        'remaining_units': 'Калды: {amount} Даана',
        'no_deposits_yet': 'Азырынча салымдар жок. Коюуну баштаңыз!',
        'source_note_fin': 'Булагы / Эскертүү (мис. Айлык)',
        'source_note_prog': 'Эскертүү (мис. 1-күн машыгуу)',
        'added_units_day': 'Кошулган даана / Күн'
    }
}

# Fix TR strings that were kept original in the first pass
additions['tr']['reached_goal_msg'] = 'Hedefinize başarıyla ulaştınız:\\n{title}'
additions['tr']['no_deposits_yet'] = 'Henüz para/ilerleme eklenmedi. Başlayın!'
additions['en']['reached_goal_msg'] = 'You have successfully reached your goal:\\n{title}'
additions['en']['no_deposits_yet'] = 'No deposits yet. Start saving!'

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
                new_lines.append(f"      '{k}': '{v}',")
        continue
    
    if current_lang is not None and line.strip() == '},':
        current_lang = None
    
    new_lines.append(line)

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))


# 2. Update analytics_screen.dart
analytics_file = r'C:\Finance 27\lib\ui\screens\analytics_screen.dart'
with open(analytics_file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',",
    "AppStrings.get(ref, 'jan') ?? 'Ocak', AppStrings.get(ref, 'feb') ?? 'Şubat', AppStrings.get(ref, 'mar') ?? 'Mart', AppStrings.get(ref, 'apr') ?? 'Nisan', AppStrings.get(ref, 'may') ?? 'Mayıs', AppStrings.get(ref, 'jun') ?? 'Haziran',"
)
content = content.replace(
    "'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'",
    "AppStrings.get(ref, 'jul') ?? 'Temmuz', AppStrings.get(ref, 'aug') ?? 'Ağustos', AppStrings.get(ref, 'sep') ?? 'Eylül', AppStrings.get(ref, 'oct') ?? 'Ekim', AppStrings.get(ref, 'nov') ?? 'Kasım', AppStrings.get(ref, 'dec') ?? 'Aralık'"
)
content = content.replace(
    "return '$_selectedYear Yılı';",
    "return '$_selectedYear ${AppStrings.get(ref, 'year_suffix') ?? 'Yılı'}';"
)
content = content.replace(
    "return 'Tümü (Ömür Boyu)';",
    "return AppStrings.get(ref, 'all_time_lifetime') ?? 'Tümü (Ömür Boyu)';"
)
content = content.replace(
    "Text('Uygula', style:",
    "Text(AppStrings.get(ref, 'apply') ?? 'Uygula', style:"
)
content = content.replace(
    "_buildSectionTitle('SAVAŞ PLANI (İşlemler & Görevler)')",
    "_buildSectionTitle(AppStrings.get(ref, 'war_plan_ops') ?? 'SAVAŞ PLANI (İşlemler & Görevler)')"
)
content = content.replace(
    "_buildSectionTitle('HEDEFLER (Genel İlerleme)')",
    "_buildSectionTitle(AppStrings.get(ref, 'goals_progress') ?? 'HEDEFLER (Genel İlerleme)')"
)
content = content.replace(
    "Text('Net PnL (Kâr/Zarar)',",
    "Text(AppStrings.get(ref, 'net_pnl') ?? 'Net PnL (Kâr/Zarar)',"
)

with open(analytics_file, 'w', encoding='utf-8') as f:
    f.write(content)


# 3. Update goals_screen.dart
goals_file = r'C:\Finance 27\lib\ui\screens\goals_screen.dart'
with open(goals_file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "'Aktif Finansal Hedefler'",
    "AppStrings.get(ref, 'active_fin_goals') ?? 'Aktif Finansal Hedefler'"
)
content = content.replace(
    "'Aktif İlerleme Hedefleri'",
    "AppStrings.get(ref, 'active_prog_goals') ?? 'Aktif İlerleme Hedefleri'"
)
content = content.replace(
    "'Tamamlanan Finansal Hedefler'",
    "AppStrings.get(ref, 'completed_fin_goals') ?? 'Tamamlanan Finansal Hedefler'"
)
content = content.replace(
    "'Tamamlanan İlerleme Hedefleri'",
    "AppStrings.get(ref, 'completed_prog_goals') ?? 'Tamamlanan İlerleme Hedefleri'"
)
content = content.replace(
    "'Günlük Hedef: ${(goal.requiredDailySaving).toStringAsFixed(2)} Adet • Aylık: ${(goal.requiredDailySaving * 30).toStringAsFixed(2)} Adet'",
    "(AppStrings.get(ref, 'daily_target_units') ?? 'Günlük Hedef: {daily} Adet • Aylık: {monthly} Adet').replaceAll('{daily}', goal.requiredDailySaving.toStringAsFixed(2)).replaceAll('{monthly}', (goal.requiredDailySaving * 30).toStringAsFixed(2))"
)
content = content.replace(
    "isFinancial ? 'Finansal Hedef' : 'İlerleme Hedefi (Örn: Dil Öğrenme)'",
    "isFinancial ? (AppStrings.get(ref, 'fin_goal_label') ?? 'Finansal Hedef') : (AppStrings.get(ref, 'prog_goal_label') ?? 'İlerleme Hedefi (Örn: Dil Öğrenme)')"
)
content = content.replace(
    "isFinancial ? selectedCurrency : 'Adet'",
    "isFinancial ? selectedCurrency : (AppStrings.get(ref, 'units') ?? 'Adet')"
)
content = content.replace(
    "labelText: 'Para Birimi'",
    "labelText: AppStrings.get(ref, 'currency') ?? 'Para Birimi'"
)
content = content.replace(
    "'Hedef Onaylanmadı: İlerleme hedeflerinde günlük hedef en az 1 adet olmalıdır. Lütfen daha yakın bir tarih seçin veya hedef adedini artırın.'",
    "AppStrings.get(ref, 'goal_not_approved') ?? 'Hedef Onaylanmadı: İlerleme hedeflerinde günlük hedef en az 1 adet olmalıdır. Lütfen daha yakın bir tarih seçin veya hedef adedini artırın.'"
)
content = content.replace(
    "'Adet'",
    "(AppStrings.get(ref, 'units') ?? 'Adet')"
)

with open(goals_file, 'w', encoding='utf-8') as f:
    f.write(content)


# 4. Update goal_detail_screen.dart
detail_file = r'C:\Finance 27\lib\ui\screens\goal_detail_screen.dart'
with open(detail_file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "'You have successfully reached your goal:\\n${goal.title}'",
    "(AppStrings.get(ref, 'reached_goal_msg') ?? 'You have successfully reached your goal:\\n{title}').replaceAll('{title}', goal.title)"
)
content = content.replace(
    "'Kalan: ${goal.remainingAmount.toStringAsFixed(2)} Adet'",
    "(AppStrings.get(ref, 'remaining_units') ?? 'Kalan: {amount} Adet').replaceAll('{amount}', goal.remainingAmount.toStringAsFixed(2))"
)
content = content.replace(
    "'No deposits yet. Start saving!'",
    "AppStrings.get(ref, 'no_deposits_yet') ?? 'No deposits yet. Start saving!'"
)
content = content.replace(
    "'Kaynak / Not (Örn: Maaş)'",
    "AppStrings.get(ref, 'source_note_fin') ?? 'Kaynak / Not (Örn: Maaş)'"
)
content = content.replace(
    "'Not (Örn: 1. Gün Antrenmanı)'",
    "AppStrings.get(ref, 'source_note_prog') ?? 'Not (Örn: 1. Gün Antrenmanı)'"
)
content = content.replace(
    "'Eklenen Adet / Gün'",
    "AppStrings.get(ref, 'added_units_day') ?? 'Eklenen Adet / Gün'"
)

with open(detail_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated all files with comprehensive localization!")
