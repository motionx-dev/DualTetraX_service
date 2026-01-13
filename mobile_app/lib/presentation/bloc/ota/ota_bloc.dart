import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/ota_repository.dart';
import '../../../domain/entities/ota_state.dart' as domain;
import 'ota_event.dart';
import 'ota_state.dart';

class OtaBloc extends Bloc<OtaEvent, OtaBlocState> {
  final OtaRepository otaRepository;

  StreamSubscription? _otaStatusSubscription;
  bool _isSendingChunks = false;

  OtaBloc({required this.otaRepository}) : super(const OtaInitial()) {
    on<InitializeOtaRequested>(_onInitializeOta);
    on<PickFirmwareRequested>(_onPickFirmware);
    on<ClearFirmwareRequested>(_onClearFirmware);
    on<StartOtaRequested>(_onStartOta);
    on<CancelOtaRequested>(_onCancelOta);
    on<OtaStatusChanged>(_onStatusChanged);
    on<ChunkProgressUpdated>(_onChunkProgressUpdated);
    on<OtaFinishRequested>(_onFinishOta);
  }

  Future<void> _onInitializeOta(
    InitializeOtaRequested event,
    Emitter<OtaBlocState> emit,
  ) async {
    try {
      await otaRepository.initializeOtaService();
      final isAvailable = await otaRepository.isOtaAvailable();

      if (isAvailable) {
        // Listen to OTA status updates from device
        _otaStatusSubscription?.cancel();
        _otaStatusSubscription = otaRepository.otaStatusStream.listen((status) {
          add(OtaStatusChanged(status));
        });

        emit(state.copyWith(isOtaServiceReady: true, clearError: true));
      } else {
        emit(state.copyWith(
          isOtaServiceReady: false,
          errorMessage: 'OTA service not available on device',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isOtaServiceReady: false,
        errorMessage: 'Failed to initialize OTA service: $e',
      ));
    }
  }

  Future<void> _onPickFirmware(
    PickFirmwareRequested event,
    Emitter<OtaBlocState> emit,
  ) async {
    try {
      final firmware = await otaRepository.pickLocalFirmware();
      if (firmware != null) {
        emit(state.copyWith(selectedFirmware: firmware, clearError: true));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to pick firmware: $e'));
    }
  }

  void _onClearFirmware(
    ClearFirmwareRequested event,
    Emitter<OtaBlocState> emit,
  ) {
    emit(state.copyWith(clearFirmware: true, clearError: true));
  }

  Future<void> _onStartOta(
    StartOtaRequested event,
    Emitter<OtaBlocState> emit,
  ) async {
    if (!state.canStartOta) {
      emit(state.copyWith(errorMessage: 'Cannot start OTA in current state'));
      return;
    }

    try {
      emit(state.copyWith(
        isTransferring: true,
        sendProgress: 0,
        sentChunks: 0,
        totalChunks: event.firmware.chunkCount,
        clearError: true,
      ));

      // Start OTA on device
      await otaRepository.startOtaUpdate(event.firmware);

      // Start sending chunks
      _isSendingChunks = true;
      _sendChunksLoop();
    } catch (e) {
      emit(state.copyWith(
        isTransferring: false,
        errorMessage: 'Failed to start OTA: $e',
      ));
    }
  }

  Future<void> _sendChunksLoop() async {
    while (_isSendingChunks) {
      try {
        final hasMore = await otaRepository.sendNextChunk();
        final progress = otaRepository.currentProgress;

        add(ChunkProgressUpdated(
          progress: progress,
          sentChunks: (progress * state.totalChunks) ~/ 100,
          totalChunks: state.totalChunks,
        ));

        if (!hasMore) {
          _isSendingChunks = false;
          add(const OtaFinishRequested());
          break;
        }
      } catch (e) {
        _isSendingChunks = false;
        add(CancelOtaRequested());
        break;
      }
    }
  }

  void _onChunkProgressUpdated(
    ChunkProgressUpdated event,
    Emitter<OtaBlocState> emit,
  ) {
    emit(state.copyWith(
      sendProgress: event.progress,
      sentChunks: event.sentChunks,
      totalChunks: event.totalChunks,
    ));
  }

  Future<void> _onFinishOta(
    OtaFinishRequested event,
    Emitter<OtaBlocState> emit,
  ) async {
    try {
      await otaRepository.finishOtaUpdate();
      // Device will send status updates via notification
    } catch (e) {
      emit(state.copyWith(
        isTransferring: false,
        errorMessage: 'Failed to finish OTA: $e',
      ));
    }
  }

  Future<void> _onCancelOta(
    CancelOtaRequested event,
    Emitter<OtaBlocState> emit,
  ) async {
    _isSendingChunks = false;

    try {
      await otaRepository.cancelOtaUpdate();
      emit(state.copyWith(
        isTransferring: false,
        sendProgress: 0,
        sentChunks: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTransferring: false,
        errorMessage: 'Failed to cancel OTA: $e',
      ));
    }
  }

  void _onStatusChanged(
    OtaStatusChanged event,
    Emitter<OtaBlocState> emit,
  ) {
    final status = event.status;

    // If OTA completed (success or error), stop transferring
    bool isTransferring = state.isTransferring;
    if (status.state == domain.OtaState.success ||
        status.state == domain.OtaState.error ||
        status.state == domain.OtaState.idle) {
      isTransferring = false;
      _isSendingChunks = false;
    }

    emit(state.copyWith(
      deviceStatus: status,
      isTransferring: isTransferring,
    ));
  }

  @override
  Future<void> close() {
    _isSendingChunks = false;
    _otaStatusSubscription?.cancel();
    otaRepository.dispose();
    return super.close();
  }
}
