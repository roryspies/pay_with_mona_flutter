import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

/// A class to manage caching data for the Mona SDK merchant key.
///
/// This class provides methods to save, read, and retrieve specific values
/// from a cached JSON file.
class MonaSdkMerchantKeyCache {
  static final _instance = MonaSdkMerchantKeyCache._internal();

  factory MonaSdkMerchantKeyCache() => _instance;

  MonaSdkMerchantKeyCache._internal();

  static const _fileName = 'mona_sdk_merchant_key.json';

  /// Returns the local file path for the cache.
  Future<String> get _localPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// Returns the local file instance.
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  /// Saves or updates the provided [data] in the cache file.
  ///
  /// This method reads the existing data, merges the new data into it,
  /// and then writes the combined result back to the file, ensuring
  /// no data is lost.
  Future<void> save(Map<String, dynamic> data) async {
    // 1. Read the existing data
    final Map<String, dynamic> currentData = await read() ?? {};

    // 2. Merge the new data into the existing data
    // The addAll method will add new keys and update existing ones.
    currentData.addAll(data);

    // 3. Write the complete, merged data back to the file
    final file = await _localFile;
    "SAVE TO APP FILE (MERGED) ::: $currentData".log();
    await file.writeAsString(jsonEncode(currentData));
  }

  /// Reads the entire content of the cache file.
  ///
  /// Returns a `Map<String, dynamic>` if the file exists and is not empty,
  /// otherwise returns `null`.
  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _localFile;
      // Check if file exists before reading to avoid exceptions on first run
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      "READ FROM APP FILE ::: $contents".log();

      if (contents.isNotEmpty) {
        return jsonDecode(contents) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      // If any other error occurs, return null.
      "Error reading cache file: $e".log();
      return null;
    }
  }

  /// Retrieves the value of a specific [key] from the cache.
  ///
  /// This method reads the entire cache file and returns the value
  /// associated with the given key. Returns `null` if the key is not found
  /// or if the cache is empty.
  Future<dynamic> getValue(String key) async {
    final data = await read();
    return data?[key];
  }
}
