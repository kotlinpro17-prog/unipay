import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalStorageService extends GetxService {
  final _storage = GetStorage();

  Future<void> init() async {
    await GetStorage.init();
  }

  void write(String key, dynamic value) => _storage.write(key, value);
  T? read<T>(String key) => _storage.read<T>(key);
  void remove(String key) => _storage.remove(key);
  void clear() => _storage.erase();
}
