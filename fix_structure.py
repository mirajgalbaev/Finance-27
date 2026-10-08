import codecs

file_path = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    lines = f.read().splitlines()

idx1 = -1
idx2 = -1
idx3 = -1
for i, line in enumerate(lines):
    if line.startswith("class MultiDateSelectionDialog extends StatefulWidget {"):
        idx1 = i
    elif line.startswith("  Widget _buildFinanceStyleCalendarGrid(List<ReminderModel> allReminders) {"):
        idx2 = i
    elif line.startswith("class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {"):
        idx3 = i

print(f"idx1: {idx1}, idx2: {idx2}, idx3: {idx3}")

if idx1 != -1 and idx2 != -1 and idx3 != -1:
    # Lift the dialog block
    dialog_block = lines[idx1:idx2]
    dialog_block.append("}")
    dialog_block.append("")

    brace_idx = -1
    for j in range(idx1 - 1, idx1 - 5, -1):
        if lines[j].strip() == "}":
            brace_idx = j
            break
    
    if brace_idx != -1:
        print(f"Removing brace at {brace_idx}")
        partA = lines[:brace_idx]
        partB = lines[idx2:idx3]
        partC = dialog_block
        partD = lines[idx3:]

        new_lines = partA + [""] + partB + partC + partD
        with codecs.open(file_path, 'w', 'utf-8') as f:
            f.write('\n'.join(new_lines) + '\n')
        print("Reorganization successful")
    else:
        print("Could not find closing brace for PlannerSetupFullScreenState")
else:
    print("Could not find indices")
