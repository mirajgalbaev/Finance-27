import re

with open(r'c:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace first IntrinsicHeight Row
pattern1 = r'''              IntrinsicHeight\(\s*child: Row\(\s*crossAxisAlignment: CrossAxisAlignment\.stretch,\s*children: \[\s*Expanded\(\s*flex: 2,\s*child: (Container\(.*?)\)\s*,\s*\)\s*,\s*const SizedBox\(width: 16\),\s*Expanded\(\s*flex: 2,\s*child: (Container\(.*?)\)\s*,\s*\)\s*,\s*\],\s*\),\s*\),'''
def repl1(m):
    return f'''              LayoutBuilder(builder: (context, constraints) {{
                bool isMobile = constraints.maxWidth < 600;
                Widget leftCard = {m.group(1)});
                Widget rightCard = {m.group(2)});
                if (isMobile) {{
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftCard, const SizedBox(height: 16), rightCard]);
                }} else {{
                  return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: leftCard), const SizedBox(width: 16), Expanded(flex: 2, child: rightCard)]));
                }}
              }}),'''
content = re.sub(pattern1, repl1, content, flags=re.DOTALL)

# Replace second IntrinsicHeight Row
pattern2 = r'''        IntrinsicHeight\(\s*child: Row\(\s*crossAxisAlignment: CrossAxisAlignment\.stretch,\s*children: \[\s*Expanded\(\s*flex: 2,\s*child: (Container\(.*?)\)\s*,\s*\)\s*,\s*const SizedBox\(width: 16\),\s*Expanded\(\s*flex: 2,\s*child: (Container\(.*?Expanded\(\s*child: )TextField\((.*?)\)\s*,\s*\)(.*?)\)\s*,\s*\)\s*\]\s*\)\s*\)'''

def repl2(m):
    left = m.group(1)
    right_before_textfield = m.group(2)
    textfield = m.group(3)
    right_after = m.group(4)
    # the second card has Expanded(child: TextField(...)). On mobile (Column), Expanded inside Column with unbounded height fails!
    # So we replace it dynamically
    return f'''        LayoutBuilder(builder: (context, constraints) {{
                bool isMobile = constraints.maxWidth < 600;
                Widget leftCard = {left});
                
                Widget buildRightCard(bool mobile) {{
                  return {right_before_textfield} mobile ? SizedBox(height: 150, child: TextField({textfield})) : Expanded(child: TextField({textfield})){right_after});
                }}
                
                if (isMobile) {{
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftCard, const SizedBox(height: 16), buildRightCard(true)]);
                }} else {{
                  return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: leftCard), const SizedBox(width: 16), Expanded(flex: 2, child: buildRightCard(false))]));
                }}
        }})'''

content = re.sub(pattern2, repl2, content, flags=re.DOTALL)

with open(r'c:\Finance 27\lib\ui\screens\daily_trade_journal_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done daily_trade_journal_screen")
