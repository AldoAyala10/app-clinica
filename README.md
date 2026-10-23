# Clínica Dental

Aplicación Flutter con autenticación y persistencia de citas y pacientes en Firebase.

## Acceso de doctor / administrador

La app no incluye credenciales de administrador de prueba. Crea el usuario en
Firebase Authentication y agrega en Firestore un documento `users/{uid}` con
`role: "doctor"`, `name` y `email`. En el inicio de sesión selecciona **Doctor**;
ese rol abre el dashboard con pacientes, agenda e inventario. Las cuentas creadas
desde el formulario de registro quedan como pacientes.

Para probar el listado global, registra pacientes o créalos desde el botón `+`
del tab **Pacientes**. El buscador filtra por nombre o correo y la lista pagina
de ocho en ocho. Para probar HU-10, entra con una cuenta de paciente, abre
**Mis Citas**, toca una cita activa y elige **Cancelar** o **Reprogramar**.
El historial pasado aparece en **Mis Citas > Historial** y desde **Mi Perfil**.

## Panel Administrativo Web (Sprint 5)

El panel es un segundo punto de entrada del mismo proyecto Flutter
(`lib/main_admin.dart`) y comparte modelos, repositorio y Firebase con la app.

```sh
flutter run -d chrome -t lib/main_admin.dart
flutter build web -t lib/main_admin.dart -o build/web_admin
```

En la versión web de la app también se entra desde el login, con el enlace
**Acceso administrativo** debajo de "¿No tienes una cuenta?".

Cuentas del personal: crea el usuario en Firebase Authentication y su documento
`users/{uid}` con `name`, `email` y `role`:

| Rol | `role` | Qué puede hacer en el panel |
|---|---|---|
| Administrador | `admin` | US03: alta, consulta, edición y baja de pacientes; US05: citas |
| Recepción | `receptionist` | US05: crear, modificar, confirmar y cancelar citas |

Estas cuentas no pueden entrar a la app móvil. La baja de un paciente es
lógica (`active: false`): deja de aparecer y no se le agendan citas, pero
conserva su historial y se puede reactivar. Al crear o modificar una cita, el
panel marca los horarios ocupados del odontólogo; cada odontólogo tiene su
consultorio, así que un horario libre también garantiza el consultorio.

En la app móvil, el paciente encuentra su **carnet digital con QR** en
**Mi Perfil > Mi carnet digital** (US04). El QR contiene
`clinica-dental:paciente:{id}`; recepción puede pegar ese texto o el ID en el
buscador de Pacientes del panel. **Mis Citas** (US06) muestra fecha, hora,
odontólogo y consultorio, y avisa cuando no hay red y muestra la copia guardada.

## Ejecutar y comprobar

```sh
flutter pub get
flutter test
flutter run -d chrome
```

El flujo de GitHub Actions ejecuta `flutter test` antes de compilar el APK de
depuración en push y pull request hacia `main`. Los archivos de la carpeta
`Sprint2_LoginApp_patch` son una copia histórica: la app y el pipeline se
ejecutan desde la raíz de este repositorio.
