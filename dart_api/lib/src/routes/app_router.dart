import 'package:dart_api/src/controllers/auth_controller.dart';
import 'package:dart_api/src/controllers/medicine_controller.dart';
import 'package:dart_api/src/controllers/owner_controller.dart';
import 'package:dart_api/src/controllers/record_controller.dart'; // ថែម Import នេះ
import 'package:dart_api/src/controllers/appointment_controller.dart';
import 'package:dart_api/src/controllers/dashboard_controller.dart';
import 'package:dart_api/src/controllers/vaccination_controller.dart';
import 'package:dart_api/src/controllers/supplyer_controller.dart'; 
import 'package:shelf_router/shelf_router.dart';

class AppRouter {
  final AuthController _authController = AuthController();
  final OwnerController _ownerController = OwnerController();
  final MedicineController _medicineController = MedicineController();
  final RecordController _recordController = RecordController(); // ថែម Controller នេះ
  final VaccinationController _vaccinationController = VaccinationController();
  final AppointmentController _appointmentController = AppointmentController();
  final DashboardController _dashboardController = DashboardController();
  final SupplierController _supplierController = SupplierController(); // ថែម Controller supplier

  Router get router {
    final router = Router();

   
    router.post('/api/auth/register', _authController.register);
    router.post('/api/auth/login', _authController.login);

  
    router.get('/api/owners', _ownerController.getAll);
    router.get('/api/owners/<id>', _ownerController.getById);
    router.post('/api/owners', _ownerController.create);
    router.put('/api/owners/<id>', _ownerController.update);
    router.delete('/api/owners/<id>', _ownerController.delete);

    
    router.get('/api/medicines', _medicineController.getAll);
    router.post('/api/medicines', _medicineController.create);
    router.delete('/api/medicines/<id>', _medicineController.delete);

    
    router.get('/api/records', _recordController.getAll);
    router.get('/api/records/<id>', _recordController.getById);
    router.post('/api/records', _recordController.create);
    router.put('/api/records/<id>', _recordController.update);
    router.delete('/api/records/<id>', _recordController.delete);

    router.get('/api/dashboard/summary', _dashboardController.summary);

    router.get('/api/vaccinations', _vaccinationController.getAll);
    router.post('/api/vaccinations', _vaccinationController.create);
    router.put('/api/vaccinations/<id>', _vaccinationController.update);
    router.delete('/api/vaccinations/<id>', _vaccinationController.delete);

    router.get('/api/appointments', _appointmentController.getAll);
    router.post('/api/appointments', _appointmentController.create);
    router.put('/api/appointments/<id>', _appointmentController.update);
    router.delete('/api/appointments/<id>', _appointmentController.delete);

    router.get('/api/suppliers', _supplierController.getAll);
    router.get('/api/suppliers/<id>', _supplierController.getById);
    router.post('/api/suppliers', _supplierController.create);
    router.put('/api/suppliers/<id>', _supplierController.update);
    router.delete('/api/suppliers/<id>', _supplierController.delete);

    router.get('/api/medicines/<id>', _medicineController.getById);
    router.put('/api/medicines/<id>', _medicineController.update);
    router.post('/api/medicines/<id>/batches', _medicineController.addBatch);
    return router;
  }
}