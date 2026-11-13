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

## Panel web (administración, recepción y odontología)

El panel es un segundo punto de entrada del mismo proyecto Flutter
(`lib/main_admin.dart`) y comparte modelos, repositorio y Firebase con la app.

```sh
flutter run -d chrome -t lib/main_admin.dart
flutter build web -t lib/main_admin.dart -o build/web_admin
```

Crea el usuario en Firebase Authentication y su documento `users/{uid}` con
`name`, `email` y `role`. Para odontología, agrega también `doctorId` con el id
del odontólogo (`d1`, `d2` o `d3`) para abrir automáticamente su fila:

| Rol | `role` | Qué puede hacer en el panel |
|---|---|---|
| Administrador | `admin` | Pacientes, citas y turnos |
| Recepción | `receptionist` | Citas y turnos |
| Odontólogo | `doctor` | Llamar y cerrar turnos desde la vista web |

La vista **Turnos** genera números secuenciales por odontólogo y día. Recepción
puede registrar una llegada sin cita o marcar la llegada de una cita de hoy; el
ticket conserva su origen y pasa por los estados `waiting` (en espera),
`inService` (en atención), `served` (atendido) y `cancelled` (cancelado). El
odontólogo llama al siguiente turno y marca el actual como atendido antes de
continuar. La asignación usa transacciones de Firestore e impide números
duplicados cuando hay altas simultáneas.

El turno actual se publica en `queueBoards/{doctorId}_YYYY-MM-DD`. El endpoint
REST de Firestore es:

```text
https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/queueBoards/{doctorId}_{YYYY-MM-DD}
```

El documento contiene únicamente el número y estado del turno actual, sin
información personal. Puede consultarse por REST y observarse en vivo con el
listener de Firestore (`snapshots()` / `onSnapshot`). Las reglas permiten su
lectura pública y restringen las escrituras a doctores y personal; los tickets
con nombres permanecen privados. Despliega las reglas actualizadas antes de
habilitar la función en producción:

```sh
firebase deploy --only firestore:rules
```

### Mi Turno y notificaciones push (Sprint 8)

Al registrar la llegada desde una cita vinculada a una cuenta, el ticket queda
asociado a su `patientId`. **Mi Turno** escucha el ticket propio y el tablero
público en tiempo real; los demás tickets y sus datos personales siguen
privados. Cloud Functions actualiza el número de personas que esperan delante
del paciente y envía el mensaje **“¡Prepárate! Faltan pocos turnos para que
seas atendido.”** al llegar a exactamente dos turnos de espera. Llegadas sin
cita no pueden recibir push si no están asociadas a una cuenta.

La app registra los tokens FCM del dispositivo en
`users/{uid}/pushTokens/{tokenHash}`. Las notificaciones se muestran como
notificación local en primer plano y como notificación FCM del sistema en
segundo plano o con la app cerrada. Se requiere permitir notificaciones en el
dispositivo; en iOS también configurar una clave APNs en Firebase y habilitar
Push Notifications para el identificador de la app en Apple Developer y Xcode,
con perfiles de firma que incluyan el entitlement `aps-environment`.

Después de publicar los índices, reglas y backend en el proyecto Firebase:

```sh
npm --prefix functions install
npm --prefix functions test
firebase deploy --only firestore:rules,firestore:indexes,functions
```

La recepción real de notificaciones en primer plano, segundo plano y con la
app cerrada debe verificarse en dispositivos Android/iOS con permisos y
credenciales APNs/FCM configurados; `flutter test` no puede simular esos
servicios del sistema.

Las cuentas de administración y recepción no pueden entrar a la app móvil. La
baja de un paciente es lógica (`active: false`): deja de aparecer y no se le
agendan citas, pero conserva su historial y se puede reactivar. Al crear o
modificar una cita, el panel marca los horarios ocupados del odontólogo; cada
odontólogo tiene su consultorio, así que un horario libre también garantiza el
consultorio.

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
