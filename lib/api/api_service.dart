import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../model/cs.dart';

class ApiService {
  static const baseUrl =
      'https://simobile.singapoly.com/api/trpl/customer-service';

  // Mendapatkan laporan
  static Future<List<CusServ>> getReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/2355011002'),
      headers: {'Accept': 'application/json'},
    );

    print('Response code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['datas'];

      if (data == null) {
        print('DATA NULL');
        return [];
      }

      if (data is List) {
        print('DATA LIST: ${data.length} item');
        return data.map((json) => CusServ.fromJson(json)).toList();
      } else if (data is Map<String, dynamic>) {
        print('DATA OBJECT tunggal');
        return [CusServ.fromJson(data)];
      } else {
        print('FORMAT DATA TIDAK DIKENALI');
        return [];
      }
    } else {
      throw Exception('Status: ${response.statusCode}');
    }
  }

  // CREATE Report
  static Future<void> createReport(CusServ rep, File? imageFile) async {
    final uri = Uri.parse('$baseUrl/2355011002');
    final request = http.MultipartRequest('POST', uri);

    request.fields['title_issues'] = rep.titleIssues;
    request.fields['description_issues'] = rep.descriptionIssues;
    request.fields['rating'] = rep.rating.toString();
    request.fields['id_division_target'] = rep.idDivisionTarget.toString();
    request.fields['id_priority'] = rep.idPriority.toString();

    if (imageFile != null && imageFile.path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 201) {
        throw Exception('Gagal membuat laporan: $responseBody');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat membuat laporan: $e');
    }
  }

  // UPDATE Report
  static Future<Map<String, dynamic>> updateReport(
  String id,
  CusServ rep,
  File? imageFile, {
  String? currentImageUrl,
}) async {
  final uri = Uri.parse('$baseUrl/$id');
  final request = http.MultipartRequest('POST', uri);

  request.headers['Accept'] = 'application/json';

  request.fields.addAll({
    'title_issues': rep.titleIssues,
    'description_issues': rep.descriptionIssues,
    'rating': rep.rating.toString(),
    'id_division_target': rep.idDivisionTarget.toString(),
    'id_priority': rep.idPriority.toString(),
  });

  if (imageFile != null) {
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();
    var multipartFile = http.MultipartFile(
      'image',
      stream,
      length,
      filename: imageFile.path.split('/').last,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);
  } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
    request.fields['existing_image_url'] = currentImageUrl;
  }

  try {
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      print('Error Response: $responseBody'); // Debug
      throw Exception('Failed to update report: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e'); // Debug
    throw Exception('Error updating report: $e');
  }
}

  // DELETE Report
  static Future<void> deleteReport(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/2355011002/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete report');
    }
  }
}
