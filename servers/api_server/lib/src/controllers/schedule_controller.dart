import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

class ScheduleController {

  ScheduleController({
    required this.pdfServiceUrl,
  });
  final String pdfServiceUrl;
  final Logger _logger = Logger('ScheduleController');

  Future<Response> importSchedule(Request request) async {
    try {
      final userId = request.context['userId'] as String?;
      final contentType = request.headers['content-type'];

      if (contentType == null || !contentType.startsWith('multipart/form-data')) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Content-Type must be multipart/form-data'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final boundary = contentType.split('boundary=').last;
      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      
      final parts = _parseMultipartForm(bodyBytes, boundary);
      final filePart = parts['file'];

      if (filePart == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'File part not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileContentType = filePart['contentType'] as String?;
      
      // Validar content type (aceitar variações)
      final isValidPdf = fileContentType != null && 
          (fileContentType == 'application/pdf' || 
           fileContentType.contains('pdf'));
      
      if (!isValidPdf) {
        _logger.warning('Invalid content type received: $fileContentType');
        return Response.badRequest(
          body: jsonEncode({'error': 'Only PDF files are allowed', 'receivedType': fileContentType}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileBytes = filePart['data'] as List<int>;
      
      if (fileBytes.length > 10 * 1024 * 1024) {
        return Response.badRequest(
          body: jsonEncode({'error': 'File too large (max 10MB)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final multipartRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$pdfServiceUrl/extract-schedule'),
      );
      
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: 'schedule.pdf',
        ),
      );

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logger.info(
        'Schedule import: userId=${userId ?? 'anonymous'}, fileSize=${fileBytes.length}, status=${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return Response(
          response.statusCode,
          body: response.body,
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        response.body,
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e, stackTrace) {
      _logger.severe('Error importing schedule: $e', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to import schedule'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Map<String, Map<String, dynamic>> _parseMultipartForm(List<int> bodyBytes, String boundary) {
    final parts = <String, Map<String, dynamic>>{};
    final boundaryBytes = utf8.encode('--$boundary');
    
    var start = 0;
    while (start < bodyBytes.length) {
      final boundaryIndex = _findBytes(bodyBytes, boundaryBytes, start);
      if (boundaryIndex == -1) break;
      
      final nextBoundaryIndex = _findBytes(bodyBytes, boundaryBytes, boundaryIndex + boundaryBytes.length);
      if (nextBoundaryIndex == -1) break;
      
      final partBytes = bodyBytes.sublist(boundaryIndex + boundaryBytes.length + 2, nextBoundaryIndex);
      
      final headerEndIndex = _findBytes(partBytes, [13, 10, 13, 10], 0);
      if (headerEndIndex == -1) {
        start = nextBoundaryIndex;
        continue;
      }
      
      final headerBytes = partBytes.sublist(0, headerEndIndex);
      final dataBytes = partBytes.sublist(headerEndIndex + 4);
      
      final headers = utf8.decode(headerBytes);
      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(headers);
      final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(headers);
      final contentTypeMatch = RegExp(r'Content-Type:\s*([^\r\n]+)', caseSensitive: false).firstMatch(headers);
      
      if (nameMatch != null) {
        final name = nameMatch.group(1)!;
        parts[name] = {
          'data': dataBytes.sublist(0, dataBytes.length - 2),
          'filename': filenameMatch?.group(1),
          'contentType': contentTypeMatch?.group(1)?.trim(),
        };
      }
      
      start = nextBoundaryIndex;
    }
    
    return parts;
  }

  int _findBytes(List<int> haystack, List<int> needle, int start) {
    for (var i = start; i <= haystack.length - needle.length; i++) {
      var found = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}
