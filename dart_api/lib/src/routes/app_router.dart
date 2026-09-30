import 'package:dart_api/src/controllers/auth_controller.dart';
import 'package:dart_api/src/controllers/medicine_controller.dart';
import 'package:dart_api/src/controllers/owner_controller.dart';
import 'package:dart_api/src/controllers/record_controller.dart';
import 'package:dart_api/src/controllers/appointment_controller.dart';
import 'package:dart_api/src/controllers/dashboard_controller.dart';
import 'package:dart_api/src/controllers/vaccination_controller.dart';
import 'package:dart_api/src/controllers/supplyer_controller.dart';
import 'package:dart_api/src/controllers/purchase_controller.dart';
import 'package:dart_api/src/controllers/sales_controller.dart';
import 'package:dart_api/src/controllers/prescription_controller.dart';
import 'package:dart_api/src/controllers/medicine_category_controller.dart';
import 'package:dart_api/src/controllers/report_controller.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

class AppRouter {
  final AuthController _authController = AuthController();
  final OwnerController _ownerController = OwnerController();
  final MedicineController _medicineController = MedicineController();
  final RecordController _recordController = RecordController();
  final VaccinationController _vaccinationController = VaccinationController();
  final AppointmentController _appointmentController = AppointmentController();
  final DashboardController _dashboardController = DashboardController();
  final SupplierController _supplierController = SupplierController();
  final PurchaseController _purchaseController = PurchaseController();
  final SalesController _salesController = SalesController();
  final PrescriptionController _prescriptionController =
      PrescriptionController();
  final MedicineCategoryController _medicineCategoryController =
      MedicineCategoryController();
  final ReportController _reportController = ReportController();

  Router get router {
    final router = Router();

    // Route api
    final uploadsHandler = createStaticHandler(
      'uploads',
      defaultDocument: null,
      serveFilesOutsidePath: false,
    );
    router.mount('/uploads/', uploadsHandler);
    // Auth
    router.post('/api/v1/auth/register', _authController.register);
    router.post('/api/v1/auth/login', _authController.login);
    router.get('/api/v1/auth/me', _authController.me);
    router.put('/api/v1/auth/profile', _authController.updateProfile);
    router.put('/api/v1/auth/password', _authController.changePassword);
    router.post('/api/v1/auth/reset-password', _authController.resetPassword);
    router.put('/api/v1/auth/avatar', _authController.updateAvatar);
    // Owner
    router.get('/api/v1/owners', _ownerController.getAll);
    router.get('/api/v1/owners/<id>', _ownerController.getById);
    router.post('/api/v1/owners', _ownerController.create);
    router.put('/api/v1/owners/<id>', _ownerController.update);
    router.delete('/api/v1/owners/<id>', _ownerController.delete);
    router.put('/api/v1/owners/<ownerId>/animals/<animalId>', _ownerController.updateAnimal);
    router.delete('/api/v1/owners/<ownerId>/animals/<animalId>', _ownerController.deleteAnimal);
    //Medicine
    router.get('/api/v1/medicines', _medicineController.getAll);
    router.get('/api/v1/medicine-categories', _medicineCategoryController.getAll);
    router.post('/api/v1/medicine-categories', _medicineCategoryController.create);
    router.post('/api/v1/medicines', _medicineController.create);
    router.delete('/api/v1/medicines/<id>', _medicineController.delete);
    // Records
    router.get('/api/v1/records', _recordController.getAll);
    router.get('/api/v1/records/<id>', _recordController.getById);
    router.post('/api/v1/records', _recordController.create);
    router.put('/api/v1/records/<id>', _recordController.update);
    router.delete('/api/v1/records/<id>', _recordController.delete);
    // Home 
    router.get('/api/v1/dashboard/summary', _dashboardController.summary);
    router.get('/api/v1/reports/summary', _reportController.summary);
    // Vaccination
    router.get('/api/v1/vaccinations', _vaccinationController.getAll);
    router.post('/api/v1/vaccinations', _vaccinationController.create);
    router.put('/api/v1/vaccinations/<id>', _vaccinationController.update);
    router.delete('/api/v1/vaccinations/<id>', _vaccinationController.delete);
    // Appointments
    router.get('/api/v1/appointments', _appointmentController.getAll);
    router.post('/api/v1/appointments', _appointmentController.create);
    router.put('/api/v1/appointments/<id>', _appointmentController.update);
    router.delete('/api/v1/appointments/<id>', _appointmentController.delete);
    // Suppliers
    router.get('/api/v1/suppliers', _supplierController.getAll);
    router.get('/api/v1/suppliers/<id>', _supplierController.getById);
    router.post('/api/v1/suppliers', _supplierController.create);
    router.put('/api/v1/suppliers/<id>', _supplierController.update);
    router.delete('/api/v1/suppliers/<id>', _supplierController.delete);
    // Purchase
    router.get('/api/v1/purchases', _purchaseController.getAll);
    router.post('/api/v1/purchases', _purchaseController.create);
    router.post('/api/v1/sales', _salesController.create);
    router.get('/api/v1/prescriptions', _prescriptionController.getAll);
    router.post('/api/v1/prescriptions', _prescriptionController.create);
    // Medicines
    router.get('/api/v1/medicines/<id>', _medicineController.getById);
    router.put('/api/v1/medicines/<id>', _medicineController.update);
    router.post('/api/v1/medicines/<id>/batches', _medicineController.addBatch);
    router.post('/api/v1/medicines/<id>/stock-out', _medicineController.stockOut);
    return router;
  }
}
