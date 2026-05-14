# Настройка Firebase проекта для ZenBalance

## 1. Создать Firebase проект

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите **"Создать проект"**
3. Введите название проекта (например, `zenbalance`)
4. Отключите **Google Analytics** (не нужен для Spark плана)
5. Нажмите **"Создать проект"**

## 2. Добавить приложения в Firebase проект

### Android

1. В консоли Firebase нажмите **Android** иконку
2. Введите `com.example.zenbalance` (пакет приложения)
3. App nickname: `ZenBalance Android`
4. Нажмите **"Зарегистрировать приложение"**
5. **Скачайте** `google-services.json`
6. Поместите файл в: `android/app/google-services.json`
7. Нажмите **"Далее"** — всё остальное уже настроено в `build.gradle.kts`

### iOS

1. В консоли Firebase нажмите **iOS** иконку
2. Введите `com.example.zenbalance` (Bundle ID)
3. App nickname: `ZenBalance iOS`
4. Нажмите **"Зарегистрировать приложение"**
5. **Скачайте** `GoogleService-Info.plist`
6. Откройте `ios/Runner.xcworkspace` в Xcode
7. Перетащите `GoogleService-Info.plist` в корень проекта Runner в Xcode
8. Убедитесь, что файл добавлен во все таргеты (Runner)

### Web

1. В консоли Firebase нажмите **Web** иконку (`</>`)
2. App nickname: `ZenBalance Web`
3. Нажмите **"Зарегистрировать приложение"**
4. Скопируйте объект `firebaseConfig` из появившегося кода
5. Откройте `web/index.html`
6. Добавьте следующий код **перед** закрывающим `</body>`:

```html
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.0.0/firebase-app.js';
  import { getAuth, connectAuthEmulator } from 'https://www.gstatic.com/firebasejs/11.0.0/firebase-auth.js';
  import { getFirestore, connectFirestoreEmulator } from 'https://www.gstatic.com/firebasejs/11.0.0/firebase-firestore.js';

  const firebaseConfig = {
    apiKey: "ВАШ_API_KEY",
    authDomain: "ВАШ_PROJECT.firebaseapp.com",
    projectId: "ВАШ_PROJECT_ID",
    storageBucket: "ВАШ_PROJECT.appspot.com",
    messagingSenderId: "ВАШ_SENDER_ID",
    appId: "ВАШ_APP_ID"
  };

  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);
</script>
```

## 3. Включить Google Sign-In в Firebase

1. В консоли Firebase перейдите в **Authentication** → **Sign-in method**
2. Нажмите **"Добавить новый провайдер"** → **Google**
3. Включите тумблер **"Включено"**
4. В поле **"Название проекта для общего доступа"** введите `ZenBalance`
5. В поле **"Email для поддержки проекта"** введите ваш email
6. Нажмите **"Сохранить"**

### Для Web дополнительно:
1. В разделе Google Sign-In нажмите **"Web SDK configuration"** (внизу)
2. Скопируйте `Web client ID` — он понадобится для настройки `google_sign_in` на вебе

## 4. Настроить Firestore

1. В консоли Firebase перейдите в **Firestore Database**
2. Нажмите **"Создать базу данных"**
3. Выберите **"Начать в тестовом режиме"** (потом настроим правила)
4. Выберите регион (ближайший к вам, например `europe-west1`)
5. Нажмите **"Готово"**

### Правила безопасности Firestore

После создания БД, перейдите в **Rules** и замените содержимое на:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Только авторизованные пользователи могут читать/писать свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## 5. Настроить OAuth consent screen (для Web и Desktop)

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Выберите ваш проект
3. Перейдите в **APIs & Services** → **OAuth consent screen**
4. Выберите **External** → **Create**
5. App name: `ZenBalance`
6. User support email: ваш email
7. Developer contact email: ваш email
8. Нажмите **Save and Continue**
9. В разделе **Scopes** нажмите **Add or Remove Scopes**
10. Добавьте: `.../auth/userinfo.email`, `.../auth/userinfo.profile`
11. Нажмите **Save and Continue**
12. В разделе **Test users** нажмите **Add Users** и добавьте свой Google аккаунт
13. Нажмите **Save and Continue**

## 6. Проверка установки

После выполнения всех шагов, запустите приложение:

```bash
flutter clean
flutter pub get
flutter run
```

### Для Web:
```bash
flutter run -d chrome
```

### Для Android:
```bash
flutter run
```

### Для iOS:
```bash
cd ios && pod install && cd ..
flutter run
```

## 7. Структура данных в Firestore

После первого входа пользователя, данные будут автоматически синхронизироваться в следующую структуру:

```
users/{userId}/
  └── sessions/{sessionId}/
        ├── id: string
        ├── startTime: timestamp
        ├── endTime: timestamp
        ├── durationSeconds: number
        ├── completed: boolean
        ├── note: string (optional)
        └── createdAt: timestamp
```

## Примечания

- **Spark Plan (Free)**: 50k MAU, 1GB Firestore, 50k reads/day, 20k writes/day
- **Без Firebase приложение работает в локальном режиме** (только SQLite)
- **Для Windows Desktop**: Firebase Auth не поддерживается напрямую — используйте Web версию
- **Для публикации**: потребуется перейти на **Flame Plan** ($25/мес) или **Blaze Plan** (pay-as-you-go)
