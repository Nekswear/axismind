$envVars = Get-Content .env | Where-Object { $_ -match '^[A-Z_]+=' } | ForEach-Object { $parts = $_ -split '=', 2; "--dart-define=$($parts[0])=$($parts[1])" }
flutter build apk --release $envVars 2>&1
