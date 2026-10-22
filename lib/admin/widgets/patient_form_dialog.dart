import 'package:flutter/material.dart';

import '../../models/patient.dart';

/// Datos capturados en el formulario de paciente.
class PatientFormData {
  const PatientFormData({
    required this.name,
    required this.phone,
    required this.email,
    required this.treatment,
    required this.medicalAlerts,
  });

  final String name;
  final String phone;
  final String email;
  final String treatment;
  final List<String> medicalAlerts;
}

/// Alta (sin [patient]) o edición de un paciente. Devuelve [PatientFormData]
/// al guardar, o null si se cancela.
class PatientFormDialog extends StatefulWidget {
  const PatientFormDialog({super.key, this.patient});

  final Patient? patient;

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.patient?.name);
  late final _phone = TextEditingController(text: widget.patient?.phone);
  late final _email = TextEditingController(text: widget.patient?.email);
  late final _treatment =
      TextEditingController(text: widget.patient?.treatment);
  late final _alerts = TextEditingController(
      text: widget.patient?.medicalAlerts.join(', '));

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _treatment, _alerts]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      PatientFormData(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        treatment: _treatment.text.trim(),
        medicalAlerts: _alerts.text
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.patient != null;
    return AlertDialog(
      title: Text(editing ? 'Editar paciente' : 'Nuevo paciente'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('patient_form_name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre completo *'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Escribe el nombre completo.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('patient_form_phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono *'),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 10
                        ? 'El teléfono debe tener 10 dígitos.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('patient_form_email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico *'),
                  validator: (v) => _emailRegex.hasMatch((v ?? '').trim())
                      ? null
                      : 'Escribe un correo válido.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('patient_form_treatment'),
                  controller: _treatment,
                  decoration: const InputDecoration(labelText: 'Tratamiento actual'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('patient_form_alerts'),
                  controller: _alerts,
                  decoration: const InputDecoration(
                    labelText: 'Alertas médicas',
                    helperText: 'Separadas por comas (ej. alergia a penicilina)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('patient_form_save'),
          onPressed: _save,
          child: Text(editing ? 'Guardar cambios' : 'Dar de alta'),
        ),
      ],
    );
  }
}
