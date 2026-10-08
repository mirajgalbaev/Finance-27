import io
import re

def process_file(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Find the block where Gal.putImage is called
    # We want to replace:
    # await Gal.putImage(filePath);
    # with:
    # if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) { await Gal.putImage(filePath); }
    
    new_text = re.sub(
        r"(await\s+Gal\.putImage\(filePath\);)",
        r"if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) { \1 } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }",
        text
    )

    # Also, let's change the directory for Windows so it goes to Downloads, not Temp
    # Replace:
    # dir = await getTemporaryDirectory();
    # with:
    # dir = Platform.isWindows ? (await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory()) : await getTemporaryDirectory();
    
    new_text = re.sub(
        r"dir = await getTemporaryDirectory\(\);",
        r"dir = Platform.isWindows ? (await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory()) : await getTemporaryDirectory();",
        new_text
    )

    if text != new_text:
        with io.open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f"Fixed {path}")
    else:
        print(f"No changes for {path}")

process_file('lib/ui/screens/analytics_screen.dart')
process_file('lib/ui/screens/planner_screen.dart')

