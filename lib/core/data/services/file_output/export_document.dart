class ExportDocument {
  const ExportDocument({
    required this.rows,
    this.details,
    this.rowsTitle = 'Results',
  });

  final List<List<String>> rows;
  final List<ExportDetail>? details;
  final String rowsTitle;

  bool get hasDetails => details != null && details!.isNotEmpty;
}

class ExportDetail {
  const ExportDetail(this.label, this.value);

  final String label;
  final String value;
}
