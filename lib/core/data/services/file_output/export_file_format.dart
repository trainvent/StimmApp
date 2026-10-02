import 'package:flutter/widgets.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

enum ExportFileFormat {
  csv('csv', 'text/csv; charset=utf-8'),
  json('json', 'application/json; charset=utf-8'),
  pdf('pdf', 'application/pdf'),
  pdfSlim('pdf', 'application/pdf');

  const ExportFileFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

class CsvExportCanceledException implements Exception {
  const CsvExportCanceledException();
}

class CsvExportLabels {
  const CsvExportLabels({
    required this.result,
    required this.name,
    required this.surname,
    required this.email,
    required this.livingAddress,
    required this.reason,
    required this.signed,
    required this.submitted,
  });

  factory CsvExportLabels.fromContext(BuildContext context) {
    return CsvExportLabels(
      result: context.l10n.result,
      name: context.l10n.name,
      surname: context.l10n.surname,
      email: context.l10n.email,
      livingAddress: context.l10n.livingAddress,
      reason: context.l10n.exportReason,
      signed: context.l10n.exportSigned,
      submitted: context.l10n.exportSubmitted,
    );
  }

  final String result;
  final String name;
  final String surname;
  final String email;
  final String livingAddress;
  final String reason;
  final String signed;
  final String submitted;
}

class ExportLabels {
  const ExportLabels({
    this.writtenAnswer = 'Written answer',
    required this.type,
    required this.id,
    required this.header,
    required this.body,
    required this.tags,
    required this.signatureCount,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.openUntilClosed,
    required this.status,
    required this.scopeType,
    required this.continent,
    required this.country,
    required this.stateOrRegion,
    required this.town,
    required this.imageUrl,
    required this.options,
    required this.votes,
    required this.totalVotes,
    required this.responseCount,
    required this.groupId,
    required this.groupName,
    required this.visibility,
    required this.signature,
    required this.petition,
    required this.poll,
    required this.survey,
    required this.signed,
    required this.submitted,
  });

  factory ExportLabels.fromContext(BuildContext context) {
    final l10n = context.l10n;
    return ExportLabels(
      writtenAnswer: l10n.writtenAnswer,
      type: l10n.exportType,
      id: l10n.exportId,
      header: l10n.exportHeader,
      body: l10n.exportBody,
      tags: l10n.exportTags,
      signatureCount: l10n.exportSignatureCount,
      createdBy: l10n.exportCreatedBy,
      createdAt: l10n.exportCreatedAt,
      expiresAt: l10n.exportExpiresAt,
      openUntilClosed: l10n.exportOpenUntilClosed,
      status: l10n.exportStatus,
      scopeType: l10n.exportScopeType,
      continent: l10n.exportContinent,
      country: l10n.exportCountry,
      stateOrRegion: l10n.exportStateOrRegion,
      town: l10n.exportTown,
      imageUrl: l10n.exportImageUrl,
      options: l10n.exportOptions,
      votes: l10n.exportVotes,
      totalVotes: l10n.exportTotalVotes,
      responseCount: l10n.exportResponseCount,
      groupId: l10n.exportGroupId,
      groupName: l10n.exportGroupName,
      visibility: l10n.exportVisibility,
      signature: l10n.exportSignature,
      petition: l10n.exportPetition,
      poll: l10n.exportPoll,
      survey: l10n.exportSurvey,
      signed: l10n.exportSigned,
      submitted: l10n.exportSubmitted,
    );
  }

  final String writtenAnswer;
  final String type;
  final String id;
  final String header;
  final String body;
  final String tags;
  final String signatureCount;
  final String createdBy;
  final String createdAt;
  final String expiresAt;
  final String openUntilClosed;
  final String status;
  final String scopeType;
  final String continent;
  final String country;
  final String stateOrRegion;
  final String town;
  final String imageUrl;
  final String options;
  final String votes;
  final String totalVotes;
  final String responseCount;
  final String groupId;
  final String groupName;
  final String visibility;
  final String signature;
  final String petition;
  final String poll;
  final String survey;
  final String signed;
  final String submitted;
}
