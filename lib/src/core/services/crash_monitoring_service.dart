import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pay_with_mona/src/core/api/api_config.dart';

class CrashMonitoringService {
  static CrashMonitoringService? _instance;
  static CrashMonitoringService get instance =>
      _instance ??= CrashMonitoringService._();

  CrashMonitoringService._();

  final _httpClient = HttpClient();
  String? _loggerWebHookURL;
  bool _isInitialized = false;
  Map<String, dynamic>? _deviceInfo;
  String? _appVersion;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _loggerWebHookURL = APIConfig.loggerWebHook;

    await _collectSystemInfo();

    _setupCrashHandlers();

    _isInitialized = true;
    developer.log('🔍 Crash Monitoring Service initialized');
  }

  ///
  /// Set up all crash handling mechanisms
  void _setupCrashHandlers() {
    // 1. Handle Flutter framework errors
    if (kDebugMode || kProfileMode || kReleaseMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        _handleFlutterError(details);
      };
    }

    // 2. Handle errors outside Flutter framework (async errors, isolate errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // 3. Handle isolate errors
    Isolate.current.addErrorListener(
      RawReceivePort(
        (pair) async {
          final List<dynamic> errorAndStacktrace = pair;
          await _handleIsolateError(
            errorAndStacktrace.first,
            errorAndStacktrace.last,
          );
        },
      ).sendPort,
    );
  }

  /// Handle Flutter framework errors
  Future<void> _handleFlutterError(FlutterErrorDetails details) async {
    developer.log('🚨 Flutter Error: ${details.exception}',
        error: details.exception);

    await _sendCrashReport(
      type: 'Flutter Framework Error',
      error: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      context: details.context?.toString(),
      library: details.library,
    );
  }

  /// Handle platform/isolate errors
  Future<void> _handlePlatformError(Object error, StackTrace stackTrace) async {
    developer.log('🚨 Platform Error: $error',
        error: error, stackTrace: stackTrace);

    await _sendCrashReport(
      type: 'Platform Error',
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  /// Handle isolate errors
  Future<void> _handleIsolateError(dynamic error, dynamic stackTrace) async {
    developer.log('🚨 Isolate Error: $error');

    await _sendCrashReport(
      type: 'Isolate Error',
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  ///
  /// Handle zone errors (async errors)
  // ignore: unused_element
  Future<void> _handleZoneError(Object error, StackTrace stackTrace) async {
    developer.log('🚨 Zone Error: $error',
        error: error, stackTrace: stackTrace);

    await _sendCrashReport(
      type: 'Zone Error (Async)',
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  /// Manual crash reporting for try-catch blocks
  Future<void> reportError({
    required String error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    developer.log('🚨 Manual Error Report: $error');

    await _sendCrashReport(
      type: 'Manual Error Report',
      error: error,
      stackTrace: stackTrace?.toString(),
      context: context,
      additionalData: additionalData,
    );
  }

  /// Send crash report to MonitoringService
  Future<void> _sendCrashReport({
    required String type,
    required String error,
    String? stackTrace,
    String? context,
    String? library,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_loggerWebHookURL == null) return;

    try {
      final timestamp = DateTime.now();
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

      // Create the crash report payload
      final crashReport = {
        'embeds': [
          {
            'title': '💥 SDK CRASH REPORT',
            'color': 15158332, // Red color
            'timestamp': timestamp.toIso8601String(),
            'fields': [
              {
                'name': '🔴 Error Type',
                'value': type,
                'inline': true,
              },
              {
                'name': '📱 Platform',
                'value': _getPlatformInfo(),
                'inline': true,
              },
              {
                'name': '📦 App Version',
                'value': _appVersion ?? 'Unknown',
                'inline': true,
              },
              {
                'name': '❌ Error Message',
                'value': _truncateText(error, 1024),
                'inline': false,
              },
              if (context != null)
                {
                  'name': '📍 Context',
                  'value': _truncateText(context, 1024),
                  'inline': false,
                },
              if (library != null)
                {
                  'name': '📚 Library',
                  'value': library,
                  'inline': true,
                },
              if (stackTrace != null)
                {
                  'name': '📋 Stack Trace',
                  'value': '```\n${_truncateText(stackTrace, 1000)}\n```',
                  'inline': false,
                },
              if (additionalData != null && additionalData.isNotEmpty)
                {
                  'name': '🔧 Additional Data',
                  'value':
                      '```json\n${_truncateText(jsonEncode(additionalData), 1000)}\n```',
                  'inline': false,
                },
              {
                'name': '🖥️ Device Info',
                'value': _getDeviceInfoSummary(),
                'inline': false,
              },
            ],
            'footer': {
              'text': 'SDK Crash Monitor • $formattedTime',
            },
          }
        ],
      };

      await _sendToMonitoringService(crashReport);
    } catch (e) {
      developer.log('❌ Failed to send crash report to MonitoringService: $e');
    }
  }

  /// Send payload to MonitoringService webhook
  Future<void> _sendToMonitoringService(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse(_loggerWebHookURL!);
      final request = await _httpClient.openUrl('POST', uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('MonitoringService webhook timeout'),
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        developer.log('✅ Crash report sent to MonitoringService successfully');
      } else {
        developer.log(
            '⚠️ MonitoringService webhook returned status: ${response.statusCode}');
      }

      await response.drain();
    } catch (e) {
      developer.log('❌ Error sending crash report to MonitoringService: $e');
    }
  }

  Future<void> _collectSystemInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'product': androidInfo.product,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
          'machine': iosInfo.utsname.machine,
        };
      }
    } catch (e) {
      developer.log('⚠️ Failed to collect system info: $e');
      _deviceInfo = {'platform': Platform.operatingSystem};
    }
  }

  String _getPlatformInfo() {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  String _getDeviceInfoSummary() {
    if (_deviceInfo == null) return 'Unknown';

    final info = <String>[];
    _deviceInfo!.forEach((key, value) {
      info.add('$key: $value');
    });

    return info.join('\n');
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  void dispose() {
    _httpClient.close();
  }
}

extension CrashReportingExtension on Object {
  Future<void> reportToCrashMonitoring({
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await CrashMonitoringService.instance.reportError(
      error: toString(),
      stackTrace: stackTrace,
      context: context,
      additionalData: additionalData,
    );
  }
}
