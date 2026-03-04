import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/brand_config.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_vivot_prod.dart';

void main() {
  Environment.init(BrandConfig.vivotProd);
  startApp(
    firebaseOptions: DefaultFirebaseOptionsVivotProd.currentPlatform,
  );
}
