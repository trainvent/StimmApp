# Importing premade forms

Open the petition or poll creator, choose **Import JSON form** (upload icon in the toolbar), and select a UTF-8 `.json` file. Confirm applying the content, edit the draft, and use the normal publication review. Importing does not publish anything.

Working examples: [poll](examples/poll-import.json) and [petition](examples/petition-import.json).

## Version 1 format

The root is a JSON object. Unknown fields are rejected to catch mistakes.

| Field | Format |
| --- | --- |
| `version` | Required integer `1` |
| `type` | Required `petition`, `poll`, or `survey`, matching the editor; the poll editor also accepts `survey` |
| `title` | Required string, 5–100 characters |
| `description` | Required string, 20–1000 characters |
| `questions` | Required for polls/surveys; forbidden for petitions. 1–20 objects with `title` (1–200 characters), optional `type` (`multipleChoice` by default, or `text`), and type-specific `options` |
| `questions[].options` | For `multipleChoice`: 2–10 distinct strings, each 1–50 characters. For `text`: omit or use `[]`. Explicit `null` is invalid. |
| `tags` | Optional 1–3 distinct tag keys from `AppTagsHelper.getTags`, e.g. `Environment`, `Education`, `Other` |
| `durationDays` | Optional integer 1–42 |
| `openUntilClosed` | Optional boolean |
| `scopeType` | Optional `global`, `countryUnion`, `country`, `stateOrRegion`, or `city` |
| `countryUnion` | Required `EU` or `UN` for `countryUnion` scope; otherwise omit |

Maximum file size: 256 KiB. Text is trimmed. Optional fields omitted from the file retain their draft values. Review those settings before publishing. Geography uses the importing user's profile; unavailable state/union scopes are rejected. Selected group audience and petition images remain unchanged. These files contain form content, not account IDs, results, signatures, images, or publication state.

Polls can mix choice and text questions. All questions require an answer; written answers allow up to 2,000 characters and are visible only to the creator. Version 1 remains unchanged: missing question type means `multipleChoice`.

Finished-form result exports (CSV, JSON and PDF) include written responses alongside selected choice labels. Optional form details identify written questions and only aggregate choice votes. Result JSON is a report, not an importable form template.
