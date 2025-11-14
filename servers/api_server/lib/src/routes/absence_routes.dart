
import 'package:api_server/src/controllers/absence_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router absenceRoutes() {
  final router = Router();

  // OPTIONS support for CORS preflight
  router.options('/absences', _handleOptions);
  router.options('/absences/<id>', _handleOptions);
  router.options('/subjects/<subjectId>/absences', _handleOptions);

  // Subject absences routes
  router.get('/subjects/<subjectId>/absences', AbsenceController.getSubjectAbsences);
  router.post('/subjects/<subjectId>/absences', AbsenceController.createAbsence);

  // Absence routes
  router.get('/absences', AbsenceController.getUserAbsences);
  router.get('/absences/<id>', AbsenceController.getAbsence);
  router.put('/absences/<id>', AbsenceController.updateAbsence);
  router.delete('/absences/<id>', AbsenceController.deleteAbsence);

  return router;
}

Response _handleOptions(Request request) => Response.ok(null);
