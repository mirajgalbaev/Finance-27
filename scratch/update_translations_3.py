import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'winning_trades': 'Winning Trades',
        'losing_trades': 'Losing Trades',
        'open_trades': 'Open Trades',
        'total_trades': 'Total Trades',
        'total_colon': 'Total:',
        'tasks_suffix': 'Tasks',
        'goals_suffix': 'Goals',
        'completed': 'Completed',
        'pending': 'Pending',
        'success_rate': 'Success Rate',
        'collected_money': 'Collected Money',
        'fin_goals': 'Financial Goals',
        'prog_goals': 'Progress Goals (Personal Dev)',
        'overall_goal_progress': 'Overall Goal Progress',
        'date_colon': 'Date: ',
        'progress_colon': 'Progress: ',
        'budget_colon': 'Budget: ',
        'status_colon': 'Status: ',
        'daily_required_colon': 'Daily Required: ',
        'daily_target_colon': 'Daily Target: ',
        'time_up': 'Time Up',
        'pnl_colon': 'PnL:',
        'sell_colon': 'Sell: ',
        'buy_colon': 'Buy: '
    },
    'tr': {
        'winning_trades': 'Kazanan İşlemler',
        'losing_trades': 'Kaybeden İşlemler',
        'open_trades': 'Açık İşlemler',
        'total_trades': 'Toplam İşlem',
        'total_colon': 'Toplam:',
        'tasks_suffix': 'Görev',
        'goals_suffix': 'Hedef',
        'completed': 'Tamamlanan',
        'pending': 'Bekleyen',
        'success_rate': 'Başarı Oranı',
        'collected_money': 'Toplanan Para',
        'fin_goals': 'Finansal Hedefler',
        'prog_goals': 'İlerleme Hedefleri (Kişisel Gelişim)',
        'overall_goal_progress': 'Genel Hedef İlerlemesi',
        'date_colon': 'Tarih: ',
        'progress_colon': 'İlerleme: ',
        'budget_colon': 'Bütçe: ',
        'status_colon': 'Durum: ',
        'daily_required_colon': 'Günlük Gereken: ',
        'daily_target_colon': 'Günlük Hedef: ',
        'time_up': 'Süre Bitti',
        'pnl_colon': 'Kâr / Zarar:',
        'sell_colon': 'Satış: ',
        'buy_colon': 'Alış: '
    },
    'ru': {
        'winning_trades': 'Прибыльные сделки',
        'losing_trades': 'Убыточные сделки',
        'open_trades': 'Открытые сделки',
        'total_trades': 'Всего сделок',
        'total_colon': 'Всего:',
        'tasks_suffix': 'Задач',
        'goals_suffix': 'Целей',
        'completed': 'Завершено',
        'pending': 'В ожидании',
        'success_rate': 'Процент успеха',
        'collected_money': 'Собранные деньги',
        'fin_goals': 'Финансовые цели',
        'prog_goals': 'Цели прогресса (Развитие)',
        'overall_goal_progress': 'Общий прогресс целей',
        'date_colon': 'Дата: ',
        'progress_colon': 'Прогресс: ',
        'budget_colon': 'Бюджет: ',
        'status_colon': 'Статус: ',
        'daily_required_colon': 'Требуется в день: ',
        'daily_target_colon': 'Ежедневная цель: ',
        'time_up': 'Время вышло',
        'pnl_colon': 'PnL:',
        'sell_colon': 'Продажа: ',
        'buy_colon': 'Покупка: '
    },
    'kg': {
        'winning_trades': 'Пайдалуу транзакциялар',
        'losing_trades': 'Зыяндуу транзакциялар',
        'open_trades': 'Ачык транзакциялар',
        'total_trades': 'Жалпы транзакциялар',
        'total_colon': 'Жалпы:',
        'tasks_suffix': 'Тапшырмалар',
        'goals_suffix': 'Максаттар',
        'completed': 'Аткарылды',
        'pending': 'Күтүлүүдө',
        'success_rate': 'Ийгилик көрсөткүчү',
        'collected_money': 'Чогулган акча',
        'fin_goals': 'Финансылык максаттар',
        'prog_goals': 'Прогресс максаттары (Өнүгүү)',
        'overall_goal_progress': 'Жалпы максат прогресси',
        'date_colon': 'Дата: ',
        'progress_colon': 'Прогресс: ',
        'budget_colon': 'Бюджет: ',
        'status_colon': 'Абал: ',
        'daily_required_colon': 'Күнүмдүк талап: ',
        'daily_target_colon': 'Күнүмдүк максат: ',
        'time_up': 'Убакыт бүттү',
        'pnl_colon': 'Пайда/Чыгым:',
        'sell_colon': 'Сатуу: ',
        'buy_colon': 'Сатып алуу: '
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
                new_lines.append(f"      '{k}': '{v}',")
        continue
    if current_lang is not None and line.strip() == '},':
        current_lang = None
    new_lines.append(line)

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))


# Update analytics_screen.dart
analytics_file = r'C:\Finance 27\lib\ui\screens\analytics_screen.dart'
with open(analytics_file, 'r', encoding='utf-8') as f:
    content = f.read()

# simple replacements
replacements = {
    "'Kazanan İşlemler'": "AppStrings.get(ref, 'winning_trades') ?? 'Kazanan İşlemler'",
    "'Kaybeden İşlemler'": "AppStrings.get(ref, 'losing_trades') ?? 'Kaybeden İşlemler'",
    "'Açık İşlemler'": "AppStrings.get(ref, 'open_trades') ?? 'Açık İşlemler'",
    "'Toplam İşlem'": "AppStrings.get(ref, 'total_trades') ?? 'Toplam İşlem'",
    "'Toplam: '": "(AppStrings.get(ref, 'total_colon') ?? 'Toplam:') + ' '",
    "' Görev'": "' ' + (AppStrings.get(ref, 'tasks_suffix') ?? 'Görev')",
    "' Hedef'": "' ' + (AppStrings.get(ref, 'goals_suffix') ?? 'Hedef')",
    "'Tamamlanan'": "AppStrings.get(ref, 'completed') ?? 'Tamamlanan'",
    "'Bekleyen'": "AppStrings.get(ref, 'pending') ?? 'Bekleyen'",
    "'Başarı Oranı'": "AppStrings.get(ref, 'success_rate') ?? 'Başarı Oranı'",
    "'Toplanan Para'": "AppStrings.get(ref, 'collected_money') ?? 'Toplanan Para'",
    "'Finansal Hedefler'": "AppStrings.get(ref, 'fin_goals') ?? 'Finansal Hedefler'",
    "'İlerleme Hedefleri (Kişisel Gelişim)'": "AppStrings.get(ref, 'prog_goals') ?? 'İlerleme Hedefleri (Kişisel Gelişim)'",
    "'Genel Hedef İlerlemesi'": "AppStrings.get(ref, 'overall_goal_progress') ?? 'Genel Hedef İlerlemesi'",
    "'Tarih: '": "AppStrings.get(ref, 'date_colon') ?? 'Tarih: '",
    "'İlerleme: '": "AppStrings.get(ref, 'progress_colon') ?? 'İlerleme: '",
    "'Bütçe: '": "AppStrings.get(ref, 'budget_colon') ?? 'Bütçe: '",
    "'Durum: '": "AppStrings.get(ref, 'status_colon') ?? 'Durum: '",
    "'Günlük Gereken: '": "AppStrings.get(ref, 'daily_required_colon') ?? 'Günlük Gereken: '",
    "'Günlük Hedef: '": "AppStrings.get(ref, 'daily_target_colon') ?? 'Günlük Hedef: '",
    "'Tamamlandı'": "AppStrings.get(ref, 'completed') ?? 'Tamamlandı'",
    "'Süre Bitti'": "AppStrings.get(ref, 'time_up') ?? 'Süre Bitti'",
    "'Kâr / Zarar:'": "AppStrings.get(ref, 'pnl_colon') ?? 'Kâr / Zarar:'",
    "'Satış: '": "AppStrings.get(ref, 'sell_colon') ?? 'Satış: '",
    "'Alış: '": "AppStrings.get(ref, 'buy_colon') ?? 'Alış: '",
    "'Bekliyor'": "AppStrings.get(ref, 'pending') ?? 'Bekliyor'"
}

for k, v in replacements.items():
    content = content.replace(k, v)

with open(analytics_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated analytics_screen.dart and localization_provider.dart")
