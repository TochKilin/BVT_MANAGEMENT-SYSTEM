import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/vet_api.dart';
import '../../services/unit_api.dart';

enum VetFormType { patient, medicine, vaccination, appointment }

/// Opens the bottom sheet form
Future<bool?> showVetForm(
  BuildContext context,
  VetFormType type, {
  Map<String, dynamic>? owner,
  Map<String, dynamic>? animal,
  Map<String, dynamic>? record,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _VetForm(type: type, owner: owner, animal: animal, record: record),
  );
}

class _VetForm extends StatefulWidget {
  final VetFormType type;
  final Map<String, dynamic>? owner;
  final Map<String, dynamic>? animal;
  final Map<String, dynamic>? record;

  const _VetForm({required this.type, this.owner, this.animal, this.record});

  @override
  State<_VetForm> createState() => _VetFormState();
}

class _VetFormState extends State<_VetForm> {
  final _formKey = GlobalKey<FormState>();

  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _animal = TextEditingController();
  final _breed = TextEditingController();
  final _weight = TextEditingController();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _reason = TextEditingController();

  String _species = 'Dog';
  String _gender = 'Male';
  String _selectedOwnerId = '';
  String _selectedAnimalId = '';
  DateTime _date = DateTime.now().add(const Duration(days: 30));
  String _image = '';
  bool _saving = false;
  bool _loadingPatients = false;
  List<Map<String, dynamic>> _patients = [];
  List<String> _units = [];
  String _selectedUnit = '';
  bool _loadingUnits = false;

  bool get _needsPatientPicker =>
      widget.type == VetFormType.vaccination ||
      widget.type == VetFormType.appointment;

  bool get _canPickImage => widget.type != VetFormType.appointment;

  @override
  void initState() {
    super.initState();
    final owner = widget.owner;
    final animal = widget.animal;
    if (owner != null && animal != null) {
      _owner.text = owner['name']?.toString() ?? '';
      _phone.text = owner['phone']?.toString() ?? '';
      _animal.text = animal['name']?.toString() ?? '';
      _species = animal['species']?.toString() ?? 'Dog';
      _breed.text = animal['breed']?.toString() ?? '';
      _gender = animal['gender']?.toString() ?? 'Male';
      _weight.text = animal['weight']?.toString() ?? '';
      _image = animal['photo']?.toString() ?? '';
    }
    if (widget.type == VetFormType.vaccination && widget.record != null) {
      final record = widget.record!;
      _name.text = record['vaccine_name']?.toString() ?? '';
      _image = record['image']?.toString() ?? '';
      _selectedOwnerId = record['owner_id']?.toString() ?? '';
      _selectedAnimalId = record['animal_id']?.toString() ?? '';
      _date =
          DateTime.tryParse(record['next_due_at']?.toString() ?? '') ?? _date;
    }
    if (widget.type == VetFormType.appointment && widget.record != null) {
      final record = widget.record!;
      _reason.text = record['reason']?.toString() ?? '';
      _selectedOwnerId = record['owner_id']?.toString() ?? '';
      _selectedAnimalId = record['animal_id']?.toString() ?? '';
      _date = DateTime.tryParse(record['scheduled_at']?.toString() ?? '') ?? _date;
    }
    if (_needsPatientPicker) _loadPatients();
    if (widget.type == VetFormType.medicine || widget.type == VetFormType.vaccination) {
      _loadUnits(widget.type == VetFormType.vaccination ? 'vaccine' : 'medicine');
      _selectedUnit = widget.record?['unit']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _owner,
      _phone,
      _animal,
      _breed,
      _weight,
      _name,
      _quantity,
      _price,
      _reason,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      _patients = await VetApi.getPatients();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _loadUnits(String type) async {
    setState(() => _loadingUnits = true);
    try {
      final units = await UnitApi.getUnits();
      final names = units.where((unit) => unit['type'] == type).map((unit) => unit['name'].toString()).toList();
      if (mounted) setState(() {
        _units = names;
        if (_selectedUnit.isEmpty && names.isNotEmpty) _selectedUnit = type == 'vaccine' && names.contains('ml') ? 'ml' : names.first;
        if (_selectedUnit.isNotEmpty && !_units.contains(_selectedUnit)) _units.add(_selectedUnit);
      });
    } catch (error) {
      if (mounted) _snack('មិនអាចទាញបញ្ជីខ្នាតបាន៖ $error');
    } finally {
      if (mounted) setState(() => _loadingUnits = false);
    }
  }

  // Pick a photo from the gallery
  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1000,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _image = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _date = date);
  }

  // Animals that belong to the currently selected owner
  List<Map<String, dynamic>> get _animals {
    final owner = _patients
        .where((item) => item['_id'] == _selectedOwnerId)
        .cast<Map<String, dynamic>>()
        .firstOrNull;
    return ((owner?['animals'] as List?) ?? [])
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsPatientPicker &&
        (_selectedOwnerId.isEmpty || _selectedAnimalId.isEmpty)) {
      _snack('សូមជ្រើសម្ចាស់ និងសត្វជាមុន');
      return;
    }

    setState(() => _saving = true);
    try {
      switch (widget.type) {
        case VetFormType.patient:
          if (widget.owner != null && widget.animal != null) {
            await VetApi.updatePatient(
              ownerId: widget.owner!['_id'].toString(),
              animalId: widget.animal!['_id'].toString(),
              ownerName: _owner.text.trim(),
              phone: _phone.text.trim(),
              animalName: _animal.text.trim(),
              species: _species,
              breed: _breed.text.trim(),
              gender: _gender,
              weight: _weight.text.trim(),
              photo: _image,
            );
          } else {
            await VetApi.createPatient(
              ownerName: _owner.text.trim(),
              phone: _phone.text.trim(),
              animalName: _animal.text.trim(),
              species: _species,
              breed: _breed.text.trim(),
              gender: _gender,
              weight: _weight.text.trim(),
              photo: _image,
            );
          }
        case VetFormType.medicine:
          await VetApi.createMedicine(
            name: _name.text.trim(),
            category: _breed.text.trim(),
            quantity: _quantity.text.trim(),
            sellingPrice: _price.text.trim(),
            unit: _selectedUnit,
            image: _image,
          );
        case VetFormType.vaccination:
          if (widget.record != null) {
            await VetApi.updateVaccination(
              id: widget.record!['_id'].toString(),
              ownerId: _selectedOwnerId,
              animalId: _selectedAnimalId,
              vaccineName: _name.text.trim(),
              unit: _selectedUnit,
              nextDueAt: _date,
              image: _image,
            );
          } else {
            await VetApi.createVaccination(
              ownerId: _selectedOwnerId,
              animalId: _selectedAnimalId,
              vaccineName: _name.text.trim(),
              unit: _selectedUnit,
              nextDueAt: _date,
              image: _image,
            );
          }
        case VetFormType.appointment:
          if (widget.record != null) {
            await VetApi.updateAppointment(
              id: widget.record!['_id'].toString(),
              ownerId: _selectedOwnerId,
              animalId: _selectedAnimalId,
              reason: _reason.text.trim(),
              scheduledAt: _date,
            );
          } else {
            await VetApi.createAppointment(
              ownerId: _selectedOwnerId,
              animalId: _selectedAnimalId,
              reason: _reason.text.trim(),
              scheduledAt: _date,
            );
          }
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      _snack(error.message);
    } catch (error) {
      _snack('មិនអាចភ្ជាប់ API server: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String get _title => switch (widget.type) {
    VetFormType.patient =>
      widget.animal == null ? 'បន្ថែមអ្នកជំងឺ' : 'កែប្រែអ្នកជំងឺ',
    VetFormType.medicine => 'បន្ថែមថ្នាំ',
    VetFormType.vaccination =>
      widget.record == null ? 'កត់ត្រាវ៉ាក់សាំង' : 'កែប្រែវ៉ាក់សាំង',
    VetFormType.appointment => widget.record == null ? 'កំណត់ការណាត់ជួប' : 'កែប្រែការណាត់ជួប',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .88,
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_needsPatientPicker) ..._patientPicker(),
                      if (widget.type == VetFormType.patient)
                        ..._patientFields(),
                      if (widget.type == VetFormType.medicine)
                        ..._medicineFields(),
                      if (widget.type == VetFormType.vaccination) ...[
                        _field(_name, 'ឈ្មោះវ៉ាក់សាំង *'),
                        _unitDropdown(),
                        _dateField('ថ្ងៃ dose បន្ទាប់'),
                      ],
                      if (widget.type == VetFormType.appointment) ...[
                        _field(_reason, 'មូលហេតុណាត់ជួប *'),
                        _dateField('ថ្ងៃ និងពេលណាត់ជួប'),
                      ],
                      if (_canPickImage) _imageField(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E6B5C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('រក្សាទុក'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _patientFields() {
    return [
      _field(_owner, 'ឈ្មោះម្ចាស់សត្វ *'),
      _field(_phone, 'លេខទូរស័ព្ទ *', keyboard: TextInputType.phone),
      _field(_animal, 'ឈ្មោះសត្វ *'),
      _select('ប្រភេទសត្វ', _species, [
        'Dog',
        'Cat',
        'Bird',
        'Other',
      ], (v) => setState(() => _species = v!)),
      _field(_breed, 'ពូជសត្វ'),
      _select('ភេទ', _gender, [
        'Male',
        'Female',
      ], (v) => setState(() => _gender = v!)),
      _field(_weight, 'ទម្ងន់ (kg)', keyboard: TextInputType.number),
    ];
  }

  List<Widget> _medicineFields() {
    return [
      _field(_name, 'ឈ្មោះថ្នាំ *'),
      _field(_breed, 'ប្រភេទថ្នាំ *'),
      _unitDropdown(),
      _field(_quantity, 'បរិមាណក្នុងស្តុក *', keyboard: TextInputType.number),
      _field(_price, 'តម្លៃលក់', keyboard: TextInputType.number),
    ];
  }

  Widget _unitDropdown() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: _units.contains(_selectedUnit) ? _selectedUnit : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'ខ្នាត *', border: OutlineInputBorder()),
      items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
      onChanged: _loadingUnits ? null : (value) => setState(() => _selectedUnit = value ?? ''),
      validator: (value) => value == null ? (_loadingUnits ? 'កំពុងទាញបញ្ជីខ្នាត' : 'សូមជ្រើសរើសខ្នាត') : null,
      hint: Text(_loadingUnits ? 'កំពុងទាញខ្នាត...' : 'ជ្រើសរើសខ្នាត'),
    ),
  );

  // Owner and animal dropdowns used by vaccination and appointment forms
  List<Widget> _patientPicker() {
    return [
      if (_loadingPatients)
        const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        )
      else if (_patients.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'មិនទាន់មានអ្នកជំងឺទេ។ សូមបន្ថែមអ្នកជំងឺជាមុន។',
            style: TextStyle(color: Color(0xFFE05C86)),
          ),
        )
      else ...[
        _select(
          'ម្ចាស់សត្វ *',
          _selectedOwnerId,
          _patients.map((p) => p['_id'].toString()).toList(),
          (value) => setState(() {
            _selectedOwnerId = value!;
            _selectedAnimalId = '';
          }),
          labels: {
            for (final p in _patients)
              p['_id'].toString(): p['name'].toString(),
          },
        ),
        if (_selectedOwnerId.isNotEmpty)
          _select(
            'សត្វ *',
            _selectedAnimalId,
            _animals.map((a) => a['_id'].toString()).toList(),
            (value) => setState(() => _selectedAnimalId = value!),
            labels: {
              for (final a in _animals)
                a['_id'].toString(): a['name'].toString(),
            },
          ),
      ],
    ];
  }

  // Fields whose label contains are required
  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) =>
            label.contains('*') && (value == null || value.trim().isEmpty)
            ? 'សូមបំពេញព័ត៌មាននេះ'
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged, {
    Map<String, String>? labels,
  }) {
    // Patient data can contain duplicate IDs, and an edited vaccine may
    // reference an owner or animal that has since been removed. Dropdown
    // values must be unique and the selected value must still be available.
    final uniqueValues = values.toSet().toList();
    final selectedValue = uniqueValues.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        items: uniqueValues
            .map(
              (v) => DropdownMenuItem(value: v, child: Text(labels?[v] ?? v)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (v) =>
            label.contains('*') && v == null ? 'សូមជ្រើសរើស' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label) {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_month_rounded),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label: ${_date.year}-$month-$day'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0E6B5C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _imageField() {
    Widget? preview;
    if (_image.isNotEmpty) {
      try {
        final bytes = base64Decode(
          _image.contains(',') ? _image.split(',').last : _image,
        );
        preview = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover),
        );
      } catch (_) {
        preview = const Icon(Icons.broken_image_outlined, size: 48);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEAF5F2),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickImage,
              child: SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (preview != null)
                      preview
                    else
                      const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF0E6B5C),
                          size: 38,
                        ),
                      ),
                    if (preview != null)
                      const Positioned(
                        right: 8,
                        bottom: 8,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFEAF5F2),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF0E6B5C),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_image.isNotEmpty)
            IconButton(
              tooltip: 'លុបរូបភាព',
              onPressed: () => setState(() => _image = ''),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
