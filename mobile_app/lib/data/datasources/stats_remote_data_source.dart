import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/server_statistics_model.dart';

abstract class StatsRemoteDataSource {
  Future<ServerDailyStatsModel> getDailyStats({String? date, String? deviceId});
  Future<ServerRangeStatsModel> getRangeStats({required String startDate, required String endDate, String? deviceId, String groupBy = 'day'});
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final ApiClient _apiClient;

  StatsRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ServerDailyStatsModel> getDailyStats({String? date, String? deviceId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.statsDaily,
      queryParameters: {
        if (date != null) 'date': date,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ServerDailyStatsModel.fromJson(data['stats'] as Map<String, dynamic>);
  }

  @override
  Future<ServerRangeStatsModel> getRangeStats({required String startDate, required String endDate, String? deviceId, String groupBy = 'day'}) async {
    final response = await _apiClient.get(
      ApiEndpoints.statsRange,
      queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
        'group_by': groupBy,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
    return ServerRangeStatsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
