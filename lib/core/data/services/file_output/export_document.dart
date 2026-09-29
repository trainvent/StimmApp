class ExportDocument {
  const ExportDocument({
    required this.rows,
    this.details,
    this.rowsTitle = 'Results',
    this.rowTitle = 'Signature',
    this.compactColumns = const [],
    this.documentTitle,
  });

  final List<List<String>> rows;
  final List<ExportDetail>? details;
  final String rowsTitle;
  final String rowTitle;
  final List<ExportColumn> compactColumns;
  final String? documentTitle;

  bool get hasDetails => details != null && details!.isNotEmpty;
}

class ExportColumn {
  const ExportColumn({required this.sourceIndex, required this.label});

  final int sourceIndex;
  final String label;
}

class ExportDetail {
  const ExportDetail(this.label, this.value);

  final String label;
  final String value;
}
