import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_prod.dart'; // Rename this file to firebase_options_prod.dart later

void main() {
  Environment.init(EnvironmentType.prod);
  startApp(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
