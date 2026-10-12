import 'package:stimmapp/core/data/models/form_template.dart';

/// A complete unfinished petition, including a locally selected image.
class PetitionDraft {
  const PetitionDraft({required this.form, this.imageBase64});

  final FormTemplate form;
  final String? imageBase64;

  Map<String, dynamic> toJson() => {
    'form': form.toJson(),
    'imageBase64': imageBase64,
  };

  factory PetitionDraft.fromJson(Map<String, dynamic> json) => PetitionDraft(
    form: FormTemplate.fromJson(Map<String, dynamic>.from(json['form'] as Map)),
    imageBase64: json['imageBase64'] as String?,
  );
}
