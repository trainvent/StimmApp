import { randomUUID } from 'node:crypto';

export type PidVerifierLogEnvironment = 'sandbox' | 'production';
export type PidVerifierLogEvent =
  | 'request_created'
  | 'wallet_response_rejected'
  | 'session_verified'
  | 'session_accepted'
  | 'session_expired'
  | 'session_failed'
  | 'operation_failed'
  | 'verifier_started'
  | 'verifier_start_failed';
export type PidVerifierLogOutcome = 'success' | 'failure' | 'rejected';
export type PidVerifierErrorCategory =
  | 'authentication'
  | 'authorization'
  | 'configuration'
  | 'cryptographic'
  | 'storage'
  | 'transport'
  | 'validation'
  | 'unexpected';

type PidVerifierLogInput = {
  traceId?: string;
  event: PidVerifierLogEvent;
  outcome: PidVerifierLogOutcome;
  invocationMethod?: 'same-device';
  latencyMs?: number;
  status?: number;
  errorCategory?: PidVerifierErrorCategory;
  errorCode?: string;
  validationOutcome?: 'success' | 'failure' | 'not_applicable';
  protocolStage?: 'request_creation' | 'wallet_response' | 'status_check' | 'acceptance' | 'initialization';
};

export type PidVerifierLogEventRecord = {
  timestamp: string;
  traceId: string;
  event: PidVerifierLogEvent;
  outcome: PidVerifierLogOutcome;
  invocationMethod: 'same-device';
  latencyMs?: number;
  status?: number;
  errorCategory?: PidVerifierErrorCategory;
  errorCode?: string;
  validationOutcome: 'success' | 'failure' | 'not_applicable';
  protocolStage?: PidVerifierLogInput['protocolStage'];
};

function logEnvironment(): PidVerifierLogEnvironment {
  const configured = process.env.PID_VERIFIER_LOG_ENV?.trim();
  if (configured === 'production' || configured === 'sandbox') return configured;
  return process.env.GCLOUD_PROJECT?.trim() === 'stimmapp-f0141' ?
    'production' : 'sandbox';
}

/**
 * Emits one JSON record with a fixed, privacy-safe schema. Do not add request
 * bodies, tokens, claims, wallet identifiers, certificates, session IDs, or
 * error objects here: production and sandbox share the same data boundary.
 */
export function logPidVerifierEvent(
  input: PidVerifierLogInput,
  write: (record: PidVerifierLogEventRecord) => void = (record) => {
    console.log(JSON.stringify(record));
  },
): PidVerifierLogEventRecord {
  const record: PidVerifierLogEventRecord = {
    timestamp: new Date().toISOString(),
    traceId: input.traceId ?? randomUUID(),
    event: input.event,
    outcome: input.outcome,
    invocationMethod: input.invocationMethod ?? 'same-device',
    validationOutcome: input.validationOutcome ?? 'not_applicable',
  };
  if (typeof input.latencyMs === 'number') record.latencyMs = Math.max(0, Math.round(input.latencyMs));
  if (typeof input.status === 'number') record.status = input.status;
  if (input.errorCategory) record.errorCategory = input.errorCategory;
  if (input.errorCode) record.errorCode = input.errorCode;
  // Sandbox is allowed a small extra diagnostic enum; it never gets protocol data.
  if (logEnvironment() === 'sandbox' && input.protocolStage) {
    record.protocolStage = input.protocolStage;
  }
  write(record);
  return record;
}

export function pidVerifierErrorCategory(error: unknown): PidVerifierErrorCategory {
  const code = typeof (error as { code?: unknown })?.code === 'string' ?
    (error as { code: string }).code : '';
  if (code === 'unauthenticated') return 'authentication';
  if (code === 'permission-denied') return 'authorization';
  if (code === 'failed-precondition') return 'configuration';
  if (code === 'unavailable' || code === 'deadline-exceeded') return 'transport';
  return 'unexpected';
}
