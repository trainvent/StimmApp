import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart';

void main() {
  Environment.init(EnvironmentType.dev);
  startApp(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
