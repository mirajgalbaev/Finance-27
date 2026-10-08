import re

loc_file = r'C:\Finance 27\lib\core\localization_provider.dart'

additions = {
    'en': {
        'day_in_profit': 'DAY IN PROFIT',
        'day_in_loss': 'DAY IN LOSS',
        'opened_trades': 'OPENED TRADES',
        'closed_trades': 'CLOSED TRADES',
        'losing_trades': 'LOSING TRADES'
    },
    'tr': {
        'day_in_profit': 'GÜN KÂRDA',
        'day_in_loss': 'GÜN ZARARDA',
        'opened_trades': 'AÇILAN İŞLEM',
        'closed_trades': 'KAPANAN İŞLEM',
        'losing_trades': 'KAYBEDEN İŞLEM'
    },
    'ru': {
        'day_in_profit': 'ДЕНЬ В ПЛЮСЕ',
        'day_in_loss': 'ДЕНЬ В МИНУСЕ',
        'opened_trades': 'ОТКРЫТЫЕ СДЕЛКИ',
        'closed_trades': 'ЗАКРЫТЫЕ СДЕЛКИ',
        'losing_trades': 'УБЫТОЧНЫЕ СДЕЛКИ'
    },
    'kg': {
        'day_in_profit': 'КҮН ПАЙДАДА',
        'day_in_loss': 'КҮН ЧЫГЫМДА',
        'opened_trades': 'АЧЫЛГАН СООДАЛАР',
        'closed_trades': 'ЖАБЫЛГАН СООДАЛАР',
        'losing_trades': 'ЧЫГЫМДУУ СООДАЛАР'
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

p_content = p_content.replace(
    "_buildStatBox('KAYBEDEN'",
    "_buildStatBox(AppStrings.get(ref, 'losing_trades') ?? 'KAYBEDEN'"
)
p_content = p_content.replace(
    "'KAZANAN İŞLEM'",
    "AppStrings.get(ref, 'winning_trades') ?? 'KAZANAN İŞLEM'"
)
p_content = p_content.replace(
    "'KAYBEDEN İŞLEM'",
    "AppStrings.get(ref, 'losing_trades') ?? 'KAYBEDEN İŞLEM'"
)
p_content = p_content.replace(
    "'KAZANILAN PARA'",
    "AppStrings.get(ref, 'money_won') ?? 'KAZANILAN PARA'"
)
p_content = p_content.replace(
    "'KAYBEDİLEN PARA'",
    "AppStrings.get(ref, 'money_lost') ?? 'KAYBEDİLEN PARA'"
)
p_content = p_content.replace(
    "'AÇILAN İŞLEM'",
    "AppStrings.get(ref, 'opened_trades') ?? 'AÇILAN İŞLEM'"
)
p_content = p_content.replace(
    "'KAPANAN İŞLEM'",
    "AppStrings.get(ref, 'closed_trades') ?? 'KAPANAN İŞLEM'"
)
p_content = p_content.replace(
    "'KULLANILAN MARJİN'",
    "AppStrings.get(ref, 'used_margin') ?? 'KULLANILAN MARJİN'"
)
p_content = p_content.replace(
    "'GÜN KÂRDA'",
    "AppStrings.get(ref, 'day_in_profit') ?? 'GÜN KÂRDA'"
)
p_content = p_content.replace(
    "'GÜN ZARARDA'",
    "AppStrings.get(ref, 'day_in_loss') ?? 'GÜN ZARARDA'"
)
p_content = p_content.replace(
    "Text('$exchange GÜNLÜK $_selectedTab ÖZETİ'",
    "Text('${exchange.toUpperCase()} ' + (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK') + ' $_selectedTab ' + (AppStrings.get(ref, 'summary_upper') ?? 'ÖZETİ')"
)

with open(planner, 'w', encoding='utf-8') as f:
    f.write(p_content)

print("Patch complete!")
