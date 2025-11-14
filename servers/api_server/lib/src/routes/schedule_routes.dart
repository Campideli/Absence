import 'package:api_server/src/controllers/schedule_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router scheduleRoutes(String pdfServiceUrl) {
  final router = Router();
  final controller = ScheduleController(
    pdfServiceUrl: pdfServiceUrl,
  );

  router.options('/schedule/import', _handleOptions);

  router.post('/schedule/import', controller.importSchedule);

  return router;
}

Response _handleOptions(Request request) => Response.ok(null);

