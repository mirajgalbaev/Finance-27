import os, codecs

file_path = r'C:\Finance 27\lib\ui\screens\planner_screen.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    lines = f.read().splitlines()

# 1) find the first _buildStatBox
idx_first_statbox = -1
for i, line in enumerate(lines):
    if 'Widget _buildStatBox' in line:
        idx_first_statbox = i
        break

section_title_code = [
    "  Widget _buildSectionTitle(String title) {",
    "    return Row(",
    "      children: [",
    "        const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),",
    "        const SizedBox(width: 8),",
    "        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),",
    "      ]",
    "    );",
    "  }",
    ""
]

if idx_first_statbox != -1:
    lines = lines[:idx_first_statbox] + section_title_code + lines[idx_first_statbox:]
    print("Inserted _buildSectionTitle at", idx_first_statbox)

# 2) find the duplicate _buildSectionTitle
idx_titles = [i for i, line in enumerate(lines) if 'Widget _buildSectionTitle' in line]
print("All section title indices:", idx_titles)

if len(idx_titles) >= 3:
    dup_index = idx_titles[2]
    # Delete the 10 lines
    lines = lines[:dup_index] + lines[dup_index+10:]
    print("Deleted duplicate _buildSectionTitle at", dup_index)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write('\n'.join(lines) + '\n')
