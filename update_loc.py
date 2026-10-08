import os
import re

auth_screen_file = 'lib/ui/screens/auth_screen.dart'
with open(auth_screen_file, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("authState.error!,", "AppStrings.get(ref, authState.error!),")
with open(auth_screen_file, 'w', encoding='utf-8') as f:
    f.write(content)

loc_file = 'lib/core/localization_provider.dart'
with open(loc_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Add translation keys
en_keys = """
      'invalid-credential': 'The email or password you entered is incorrect.',
      'wrong-password': 'The email or password you entered is incorrect.',
      'user-not-found': 'No user found for that email.',
      'user-disabled': 'This account has been disabled.',
      'email-already-in-use': 'This email address is already in use.',
      'invalid-email': 'You entered an invalid email address.',
      'operation-not-allowed': 'This operation is not allowed.',
      'weak-password': 'The password is too weak.',
      'network-request-failed': 'Check your internet connection.',
      'crop_image': 'Crop Image',
"""

tr_keys = """
      'invalid-credential': 'Girdiğiniz şifre veya e-posta hatalı.',
      'wrong-password': 'Girdiğiniz şifre veya e-posta hatalı.',
      'user-not-found': 'Böyle bir kullanıcı bulunamadı.',
      'user-disabled': 'Bu hesap devre dışı bırakılmış.',
      'email-already-in-use': 'Bu e-posta adresi zaten kullanımda.',
      'invalid-email': 'Geçersiz bir e-posta adresi girdiniz.',
      'operation-not-allowed': 'Bu işlem şu anda desteklenmiyor.',
      'weak-password': 'Şifre çok zayıf. Daha güçlü bir şifre seçin.',
      'network-request-failed': 'İnternet bağlantınızı kontrol edin.',
      'crop_image': 'Fotoğrafı Kırp',
"""

ru_keys = """
      'invalid-credential': 'Вы ввели неверный адрес электронной почты или пароль.',
      'wrong-password': 'Вы ввели неверный адрес электронной почты или пароль.',
      'user-not-found': 'Пользователь с таким адресом электронной почты не найден.',
      'user-disabled': 'Эта учетная запись отключена.',
      'email-already-in-use': 'Этот адрес электронной почты уже используется.',
      'invalid-email': 'Вы ввели недействительный адрес электронной почты.',
      'operation-not-allowed': 'Эта операция не разрешена.',
      'weak-password': 'Пароль слишком слабый.',
      'network-request-failed': 'Проверьте подключение к Интернету.',
      'crop_image': 'Обрезать Изображение',
"""

# Insert keys into the maps
def insert_keys(lang, keys, text):
    pattern = f"'{lang}': {{"
    return text.replace(pattern, pattern + keys)

content = insert_keys('en', en_keys, content)
content = insert_keys('tr', tr_keys, content)
content = insert_keys('ru', ru_keys, content)
content = insert_keys('kg', ru_keys, content) # kg uses ru for now

with open(loc_file, 'w', encoding='utf-8') as f:
    f.write(content)
