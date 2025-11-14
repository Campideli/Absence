
import 'package:api_server/src/controllers/subject_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router subjectRoutes() {
  final router = Router();

  // OPTIONS support for CORS preflight
  router.options('/subjects', _handleOptions);
  router.options('/subjects/<id>', _handleOptions);

  // Subject routes
  router.get('/subjects', SubjectController.listSubjects);
  router.post('/subjects', SubjectController.createSubject);
  router.get('/subjects/<id>', SubjectController.getSubject);
  router.put('/subjects/<id>', SubjectController.updateSubject);
  router.delete('/subjects/<id>', SubjectController.deleteSubject);

  return router;
}

Response _handleOptions(Request request) => Response.ok(null);
