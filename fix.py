import re

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"Text\('[^']*G[^']*REV[^']*STAT[^']*ST[^']*KLER[^']*',\s*style:\s*const\s*TextStyle\(color:\s*Colors\.white,\s*fontWeight:\s*FontWeight\.bold,\s*fontSize:\s*16\)\)",
    "Text(AppStrings.get(ref, 'task_stats') ?? 'GÖREV İSTATİSTİKLERİ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))",
    content
)

content = re.sub(
    r"_buildStatItem\('Toplam G[^']*rev',\s*total\.toString\(\),\s*Colors\.blueAccent\)",
    "_buildStatItem((AppStrings.get(ref, 'total_task') ?? 'Toplam Görev').replaceAll('\\n', ' '), total.toString(), Colors.blueAccent)",
    content
)

content = re.sub(
    r"_buildStatItem\('Tamamlanan',\s*completedCount\.toString\(\),\s*Colors\.greenAccent\)",
    "_buildStatItem(AppStrings.get(ref, 'completed_task') ?? 'Tamamlanan', completedCount.toString(), Colors.greenAccent)",
    content
)

content = re.sub(
    r"_buildStatItem\('Bekleyen',\s*pendingCount\.toString\(\),\s*Colors\.orangeAccent\)",
    "_buildStatItem(AppStrings.get(ref, 'pending_task') ?? 'Bekleyen', pendingCount.toString(), Colors.orangeAccent)",
    content
)

with open('c:\\Finance 27\\lib\\ui\\screens\\planner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
