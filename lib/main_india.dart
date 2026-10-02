import 'bootstrap.dart';
import 'country/india/india_config.dart';

/// I Want India. Run with `--flavor indiaDev|indiaStaging|indiaProd -t lib/main_india.dart`.
Future<void> main() => bootstrap(indiaConfig);
