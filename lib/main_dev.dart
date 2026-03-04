import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/brand_config.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart';

void main() {
  Environment.init(BrandConfig.stimmappDev);
  startApp(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
