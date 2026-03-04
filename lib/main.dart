import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/brand_config.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_prod.dart'; // Rename this file to firebase_options_prod.dart later

void main() {
  Environment.init(BrandConfig.stimmappProd);
  startApp(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
