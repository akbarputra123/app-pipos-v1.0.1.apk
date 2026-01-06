// plan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';
import '../models/plan_model.dart';

class PlanService {
  final String _url = "${BaseUrl.api}/api/subscription";

  Future<PlanModel?> fetchPlan({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlanModel.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode} - ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Exception fetching plan: $e');
      return null;
    }
  }
}
