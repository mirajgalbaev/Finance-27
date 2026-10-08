import os
import re
import subprocess

def check():
    proc = subprocess.run(["dart", "analyze", "lib/ui/screens/planner_screen.dart"], capture_output=True, text=True, shell=True)
    out = proc.stdout + proc.stderr
    with open("dart_analyze_planner.log", "w", encoding="utf-8") as f:
        f.write(out)

    proc2 = subprocess.run(["dart", "analyze", "lib/ui/screens/daily_trade_journal_screen.dart"], capture_output=True, text=True, shell=True)
    out2 = proc2.stdout + proc2.stderr
    with open("dart_analyze_daily.log", "w", encoding="utf-8") as f:
        f.write(out2)

check()
