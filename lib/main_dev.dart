import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/main.dart' as app;

void main() {
  Environment.init(EnvironmentType.dev);
  app.main();
}
