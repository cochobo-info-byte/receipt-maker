// Conditional exports for database implementation
export 'database_models.dart';
export 'database_stub.dart'
    if (dart.library.html) 'database_web.dart'
    if (dart.library.io) 'database_mobile.dart';
