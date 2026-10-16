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
