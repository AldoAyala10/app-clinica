# LoginApp - Clínica Dental Sonrisas

Aplicación móvil en Flutter para simular el acceso de pacientes y administradores de una clínica dental. El Sprint 2 agrega autenticación local por rol, navegación a dashboards y citas de prueba para el paciente.

## Funcionalidades

- Inicio de sesión local con cuentas de demostración.
- Enrutamiento a un panel distinto según el rol del usuario.
- Panel del paciente con próximas citas cargadas desde datos mock.
- Panel inicial de administración. El listado de pacientes se conectará al backend en el Sprint 3.
- Cierre de sesión que limpia la navegación anterior.
- Tarjeta demostrativa de carnet digital controlada por `kHabilitarCarnetQR`.
- Pruebas unitarias del inicio de sesión y pruebas de widgets para los flujos de la interfaz.

## Cuentas de demostración

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Paciente | `paciente@test.com` | `Paciente123` |
| Administrador | `admin@test.com` | `Admin123` |

La autenticación y las citas son simuladas en memoria. No existe conexión a una base de datos ni persistencia de sesión; el backend se integra en un sprint posterior.

## Estructura

```text
lib/
├── config/app_config.dart
├── data/
│   ├── mock_appointments.dart
│   └── mock_auth_repository.dart
├── models/app_user.dart
├── screens/
│   ├── admin_dashboard.dart
│   ├── login_screen.dart
│   └── patient_dashboard.dart
├── main.dart
└── validar_correo.dart
test/
├── mock_auth_repository_test.dart
├── validar_correo_test.dart
└── widget_test.dart
```

## Ejecución local

Con Flutter instalado, ejecuta:

```bash
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

## Integración continua

El flujo `.github/workflows/ci.yml` se ejecuta en los Pull Requests hacia `main` y en los cambios a `main`. Descarga dependencias, analiza el proyecto y ejecuta las pruebas unitarias y de widgets.

El repositorio sigue GitHub Flow: los cambios se trabajan en una rama `feature/*` y se envían a `main` mediante Pull Request y revisión por pares.


## Integración visual de app-clinica

Se conserva `LoginApp`, el paquete `login_app`, los repositorios en `data/`,
`AppUser`, `validarCorreo`, la configuración del carnet y las tres pantallas
originales. Se adaptaron el logotipo, los colores, degradados, botones,
campos redondeados y tarjetas de app-clinica a esas pantallas.
`widgets/clinic_card.dart` contiene los componentes visuales compartidos.
La tipografía usa la fuente del sistema, sin descargas de Google Fonts.

El selector de rol permite rellenar las cuentas de prueba. El repositorio de
autenticación sigue determinando el rol real. No se importaron el acceso sin
validación, el registro simulado ni el estado global de la aplicación de diseño.
El alcance sigue siendo Sprint 2: no incluye registro, inventario, edición de
pacientes ni agenda de nuevas citas. El QR es una representación de demostración.

### Requisitos y ejecución

Flutter 3.27 o posterior (Dart 3.6 o posterior). Entra en esta carpeta antes de
ejecutar los comandos, no en el proyecto de diseño que está un nivel arriba.
Se incluye `web/` para ejecutar directamente con Chrome:

```bash
cd Sprint2_LoginApp_patch
flutter pub get
flutter run -d chrome
```

La carpeta original era un parche sin proyectos nativos. Para generar los
proyectos de Android/iOS en esta misma carpeta, si aún no los tienes:

```bash
flutter create --project-name login_app --platforms=android,ios .
flutter pub get
flutter run
```

### Validación de esta entrega

Se revisaron rutas de importación, estructura y conservación de los archivos de
lógica. Se actualizaron las pruebas de widgets para el nuevo diseño y se añadieron
casos para rol autenticado, correo inválido, carnet y pantalla de 320 px.
No fue posible ejecutar `flutter analyze`, `flutter test` ni una compilación
porque el entorno de edición no tiene Flutter/Dart instalado. Ejecuta:

```bash
flutter analyze --no-fatal-infos
flutter test
```

El flujo CI existente conserva los mismos pasos de análisis y pruebas.
