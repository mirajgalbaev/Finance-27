import codecs

file_path = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    text = f.read()
lines = text.splitlines()

def get_line_index_starting_with(prefix, start=0, count=1):
    c = 0
    for i in range(start, len(lines)):
        if lines[i].strip().startswith(prefix):
            c += 1
            if c == count:
                return i
    return -1

# Let's find exactly where each block starts in the current file:
idx_PlannerSetupState = get_line_index_starting_with("class _PlannerSetupFullScreenState")
idx_MultiDateDialog = get_line_index_starting_with("class MultiDateSelectionDialog")
idx_buildFinanceGrid = get_line_index_starting_with("Widget _buildFinanceStyleCalendarGrid")
idx_DailyPlanTabState_1 = get_line_index_starting_with("class _DailyPlanTabState", count=1)
idx_DailyPlanTabState_2 = get_line_index_starting_with("class _DailyPlanTabState", count=2)
idx_FinancePlanTabInner = get_line_index_starting_with("class _FinancePlanTabInner ")

print(f"idx_PlannerSetupState: {idx_PlannerSetupState}")
print(f"idx_MultiDateDialog: {idx_MultiDateDialog}")
print(f"idx_buildFinanceGrid: {idx_buildFinanceGrid}")
print(f"idx_DailyPlanTabState_1: {idx_DailyPlanTabState_1}")
print(f"idx_DailyPlanTabState_2: {idx_DailyPlanTabState_2}")
print(f"idx_FinancePlanTabInner: {idx_FinancePlanTabInner}")

if idx_DailyPlanTabState_2 != -1:
    print("Found duplicate DailyPlanTabState, preparing surgery...")
    
    # 1. Everything up to PlannerSetupFullScreenState's MultiDateDialog interception
    # Basically the top of the file down to MultiDateDialog
    top_part = lines[:idx_MultiDateDialog]
    # We must remove the closing brace of PlannerSetupFullScreenState right before MultiDateDialog
    brace_idx = -1
    for j in range(idx_MultiDateDialog - 1, idx_MultiDateDialog - 5, -1):
        if top_part[j].strip() == "}":
            brace_idx = j
            break
    if brace_idx != -1:
        top_part = top_part[:brace_idx]
    
    # 2. Extract MultiDateDialog block
    # It starts at idx_MultiDateDialog and ends right before idx_buildFinanceGrid
    # But wait, in the current file, idx_MultiDateDialog is BEFORE idx_buildFinanceGrid
    multi_dialog_block = lines[idx_MultiDateDialog:idx_buildFinanceGrid]
    # Let's add a brace to close MultiDateDialogState
    multi_dialog_block.append("}")
    
    # 3. Extract PlannerSetup widgets
    # These start at idx_buildFinanceGrid and go until the end of PlannerSetupFullScreenState
    # Wait, in the CURRENT file, idx_DailyPlanTabState_1 is inside the duplicated region!
    # lines[idx_buildFinanceGrid:idx_DailyPlanTabState_1] are the PlannerSetup widgets
    planner_widgets = lines[idx_buildFinanceGrid:idx_DailyPlanTabState_1]
    
    # Let's also add the closing brace for PlannerSetupFullScreenState
    planner_widgets.append("}")
    
    # 4. Extract DailyPlanTabState
    # Wait, the CURRENT file has a duplicate from idx_DailyPlanTabState_1 to idx_DailyPlanTabState_2
    # Because my script did lines[1408:2163] then lines[1842:]!
    # So idx_DailyPlanTabState_2 is the ORIGINAL start of DailyPlanTabState!
    # Let's verify by looking at where idx_DailyPlanTabState_2 goes up to:
    # it goes all the way to idx_FinancePlanTabInner
    daily_plan_block = lines[idx_DailyPlanTabState_2:idx_FinancePlanTabInner]
    
    # 5. The rest of the file
    rest_of_file = lines[idx_FinancePlanTabInner:]
    
    # Reassemble:
    # top_part (header up to end of buildSubtasksList)
    # + planner_widgets (the missing widgets for PlannerSetup)
    # + multi_dialog_block (MultiDateSelectionDialog + State)
    # + daily_plan_block (_DailyPlanTabState proper)
    # + rest_of_file
    
    new_lines = top_part + [""] + planner_widgets + [""] + multi_dialog_block + ["\n"] + daily_plan_block + rest_of_file
    
    with codecs.open(file_path, 'w', 'utf-8') as f:
        f.write('\n'.join(new_lines) + '\n')
        
    print("Surgery completed.")
else:
    print("Did not find duplicated _DailyPlanTabState?")
