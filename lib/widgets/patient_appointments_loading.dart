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

/// Evita repetir la logica de carga, retry y descarte de solicitudes viejas.
/// Sigue usando AppState en memoria hasta que se integre el backend.
mixin PatientAppointmentsLoading<T extends PatientAppointmentsScreen> on State<T> {
  PatientViewStatus patientStatus = PatientViewStatus.loading;
  List<Appointment> loadedAppointments = const [];
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    refreshAppointments();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.appointmentLoader != widget.appointmentLoader) {
      refreshAppointments();
    }
  }

  @override
  void dispose() {
    _loadRequest++;
    super.dispose();
  }

  /// Siempre se obtienen los datos vigentes de AppState mientras sea Mock.
  List<Appointment> get appointmentSource => widget.appointmentLoader == null
      ? widget.state.appointments
      : loadedAppointments;

  Future<void> refreshAppointments() async {
    final request = ++_loadRequest;
    setState(() => patientStatus = PatientViewStatus.loading);
    try {
      final appointments = await (widget.appointmentLoader?.call() ??
          Future<List<Appointment>>.delayed(
            const Duration(milliseconds: 350),
            () => List<Appointment>.of(widget.state.appointments),
          ));
      if (!mounted || request != _loadRequest) return;
      setState(() {
        loadedAppointments = appointments;
        patientStatus = PatientViewStatus.ready;
      });
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() => patientStatus = PatientViewStatus.error);
    }
  }
}
