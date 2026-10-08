import os
import glob
import re

# 1. Update dashboard_screen.dart
dashboard_file = 'lib/ui/screens/dashboard_screen.dart'
with open(dashboard_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded text with AppStrings.get(ref, 'crop_image') ?? 'Fotoğrafı Kırp'
content = content.replace("toolbarTitle: 'Fotoğrafı Kırp',", "toolbarTitle: AppStrings.get(ref, 'crop_image') ?? 'Fotoğrafı Kırp',")
with open(dashboard_file, 'w', encoding='utf-8') as f:
    f.write(content)

# 2. Update auth_provider.dart translation logic
auth_file = 'lib/providers/auth_provider.dart'
with open(auth_file, 'r', encoding='utf-8') as f:
    content = f.read()

# I will just replace the strings in _translateAuthError to return the error codes, and the UI will translate them.
# Or better, I can just modify auth_provider to accept ProviderRef and use AppStrings.
if "String _translateAuthError(FirebaseAuthException e)" in content:
    # Instead of translating in AuthProvider, let's just return the error code!
    content = re.sub(
        r"String _translateAuthError\(FirebaseAuthException e\) \{[\s\S]*?\}",
        """String _translateAuthError(FirebaseAuthException e) {
    return e.code;
  }""",
        content
    )
with open(auth_file, 'w', encoding='utf-8') as f:
    f.write(content)

# 3. Update auth_screen.dart and settings_screen.dart to translate the error code
# Wait, let's find where authProvider error is shown.
