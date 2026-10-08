import 'package:stimmapp/core/data/models/poll_template.dart';

/// A complete unfinished petition, including a locally selected image.
class PetitionDraft {
  const PetitionDraft({required this.form, this.imageBase64});

  final PollTemplate form;
  final String? imageBase64;

  Map<String, dynamic> toJson() => {
    'form': form.toJson(),
    'imageBase64': imageBase64,
  };

  factory PetitionDraft.fromJson(Map<String, dynamic> json) => PetitionDraft(
    form: PollTemplate.fromJson(Map<String, dynamic>.from(json['form'] as Map)),
    imageBase64: json['imageBase64'] as String?,
  );
}
