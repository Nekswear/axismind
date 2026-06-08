import 'package:sqflite_common_ffi_web/src/sw/shared_worker.dart';

/// Shared worker для SQLite в веб-версии.
///
/// Компилируется в отдельный JS-файл (sqflite_sw.js),
/// который запускается в Web Worker для обработки SQLite запросов
/// через WebAssembly (sqlite3.wasm).
void main(List<String> args) {
  mainSharedWorker(args);
}
