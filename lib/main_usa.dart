import 'bootstrap.dart';
import 'country/usa/usa_config.dart';

/// I Want USA. Run with `--flavor usaDev|usaStaging|usaProd -t lib/main_usa.dart`.
Future<void> main() => bootstrap(usaConfig);
