// Web平台专用导入
export 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// 提供Web平台专用的databaseFactory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;
final getDatabaseFactoryFfiWeb = () => ffi_web.databaseFactoryFfiWeb;

