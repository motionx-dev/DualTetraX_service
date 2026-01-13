import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/firmware_info.dart';

abstract class LocalFirmwareDataSource {
  Future<FirmwareInfo?> pickFirmwareFile();
  Future<Uint8List> readFirmwareData(String path);
  Future<Uint8List> getChunk(String path, int chunkIndex, int chunkSize);
  Future<String> calculateMd5(String path);
  Future<void> deleteFirmwareFile(String path);
}

/// Implementation of local firmware file operations
class LocalFirmwareDataSourceImpl implements LocalFirmwareDataSource {
  static const int defaultChunkSize = 240;
  static const int maxFirmwareSize = 2 * 1024 * 1024; // 2MB

  @override
  Future<FirmwareInfo?> pickFirmwareFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final path = file.path;

      if (path == null) {
        return null;
      }

      final fileInfo = File(path);
      final size = await fileInfo.length();

      if (size > maxFirmwareSize) {
        throw Exception(
            'Firmware file too large: ${(size / 1024 / 1024).toStringAsFixed(2)}MB (max 2MB)');
      }

      if (size == 0) {
        throw Exception('Firmware file is empty');
      }

      // Calculate MD5 checksum
      final md5Hash = await calculateMd5(path);

      return FirmwareInfo.fromLocalFile(
        path: path,
        size: size,
        name: file.name,
        md5: md5Hash,
      );
    } catch (e) {
      throw Exception('Failed to pick firmware file: $e');
    }
  }

  @override
  Future<Uint8List> readFirmwareData(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Firmware file not found: $path');
      }

      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read firmware file: $e');
    }
  }

  @override
  Future<Uint8List> getChunk(String path, int chunkIndex, int chunkSize) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Firmware file not found: $path');
      }

      final raf = await file.open(mode: FileMode.read);
      try {
        final offset = chunkIndex * chunkSize;
        final fileLength = await file.length();

        // Calculate actual chunk size (last chunk may be smaller)
        final remaining = fileLength - offset;
        final actualSize = remaining < chunkSize ? remaining : chunkSize;

        if (actualSize <= 0) {
          return Uint8List(0);
        }

        await raf.setPosition(offset);
        final bytes = await raf.read(actualSize);
        return bytes;
      } finally {
        await raf.close();
      }
    } catch (e) {
      throw Exception('Failed to read firmware chunk: $e');
    }
  }

  @override
  Future<String> calculateMd5(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Firmware file not found: $path');
      }
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate MD5: $e');
    }
  }

  @override
  Future<void> deleteFirmwareFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}
