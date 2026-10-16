# Clínica Dental — Sprint 2

Aplicación Flutter de demostración con navegación por roles y citas locales.

## Acceso de prueba

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Doctor / administrador | `admin@test.com` | `admin123` |
| Paciente | `paciente@test.com` | `paciente123` |

La autenticación y las citas son datos locales para el Sprint 2. No existe un
backend ni persistencia; registrar una cuenta solo abre una sesión temporal.
Tras cerrar sesión se elimina el historial de navegación del dashboard.

## Ejecutar y comprobar

```sh
flutter pub get
flutter test
flutter run
```

El flujo de GitHub Actions ejecuta `flutter test` antes de compilar el APK de
depuración en push y pull request hacia `main`. Los archivos de la carpeta
`Sprint2_LoginApp_patch` son una copia histórica: la app y el pipeline se
ejecutan desde la raíz de este repositorio.
