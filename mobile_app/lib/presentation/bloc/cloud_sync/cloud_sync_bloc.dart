import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/usecases/sync/upload_sessions_to_server.dart';
import 'cloud_sync_event.dart';
import 'cloud_sync_state.dart';

class CloudSyncBloc extends Bloc<CloudSyncEvent, CloudSyncState> {
  final UploadSessionsToServer uploadSessionsToServer;
  final SharedPreferences sharedPreferences;

  static const String _serverDeviceIdKey = 'server_device_id';

  CloudSyncBloc({
    required this.uploadSessionsToServer,
    required this.sharedPreferences,
  }) : super(const CloudSyncInitial()) {
    on<SyncToServerRequested>(_onSyncToServer);
  }

  Future<void> _onSyncToServer(SyncToServerRequested event, Emitter<CloudSyncState> emit) async {
    final serverDeviceId = sharedPreferences.getString(_serverDeviceIdKey);
    if (serverDeviceId == null) {
      emit(const CloudSyncError('Device not registered on server'));
      return;
    }

    emit(const CloudSyncing());

    final result = await uploadSessionsToServer(
      UploadSessionsParams(serverDeviceId: serverDeviceId),
    );

    result.fold(
      (failure) => emit(CloudSyncError(failure.message)),
      (uploadResult) {
        if (uploadResult.uploaded == 0 && uploadResult.duplicates == 0 && uploadResult.errors == 0) {
          emit(const CloudSyncNoData());
        } else {
          emit(CloudSyncSuccess(
            uploaded: uploadResult.uploaded,
            duplicates: uploadResult.duplicates,
          ));
        }
      },
    );
  }
}
