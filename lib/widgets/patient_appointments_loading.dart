import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../state/app_state.dart';
import 'patient_dashboard_feedback.dart';

/// Contrato comun para las dos pantallas del dashboard del paciente.
abstract class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  AppState get state;
  PatientAppointmentsLoader? get appointmentLoader;
}

/// Estado de carga, error y reintento de las citas del paciente.
///
/// Sin [PatientAppointmentsScreen.appointmentLoader] se usa el stream de
/// Firestore que mantiene AppState; con un loader (por ejemplo en pruebas)
/// las citas se obtienen de ese Future.
mixin PatientAppointmentsLoading<T extends PatientAppointmentsScreen> on State<T> {
  PatientViewStatus _loaderStatus = PatientViewStatus.loading;
  List<Appointment> loadedAppointments = const [];
  int _loadRequest = 0;

  bool get _usesLoader => widget.appointmentLoader != null;

  PatientViewStatus get patientStatus {
    if (_usesLoader) return _loaderStatus;
    if (widget.state.appointmentsError != null) return PatientViewStatus.error;
    if (!widget.state.appointmentsLoaded) return PatientViewStatus.loading;
    return PatientViewStatus.ready;
  }

  /// Las citas vienen de la copia local porque no hay red.
  bool get appointmentsOffline =>
      !_usesLoader && widget.state.appointmentsOffline;

  @override
  void initState() {
    super.initState();
    if (_usesLoader) refreshAppointments();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usesLoader &&
        (oldWidget.state != widget.state ||
            oldWidget.appointmentLoader != widget.appointmentLoader)) {
      refreshAppointments();
    }
  }

  @override
  void dispose() {
    _loadRequest++;
    super.dispose();
  }

  /// Citas del paciente: las de AppState (ya filtradas por su uid en
  /// Firestore) o las que devolvió el loader.
  List<Appointment> get appointmentSource =>
      _usesLoader ? loadedAppointments : widget.state.appointments;

  Future<void> refreshAppointments() async {
    final loader = widget.appointmentLoader;
    if (loader == null) return widget.state.retryAppointments();

    final request = ++_loadRequest;
    setState(() => _loaderStatus = PatientViewStatus.loading);
    try {
      final appointments = await loader();
      if (!mounted || request != _loadRequest) return;
      setState(() {
        loadedAppointments = appointments;
        _loaderStatus = PatientViewStatus.ready;
      });
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _loaderStatus = PatientViewStatus.error);
    }
  }
}
