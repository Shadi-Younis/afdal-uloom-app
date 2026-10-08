import {
  FULL_NAME_LENGTH,
  ID_LENGTH,
  PASSWORD_LENGTH,
  ROLES,
  Role,
  STUDENT_CODE_PATTERN,
  USERNAME_LENGTH,
  USERNAME_PATTERN,
} from "./constants.js";
import {invalidArgument} from "./errors.js";

/** Callable input as a plain object; throws `invalid-argument` otherwise. */
export function asObject(data: unknown): Record<string, unknown> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw invalidArgument("Expected an object.");
  }
  return data as Record<string, unknown>;
}

interface StringRules {
  min: number;
  max: number;
  pattern?: RegExp;
  trim?: boolean;
}

/** A required string field, checked against [rules]. */
export function readString(
  data: Record<string, unknown>,
  key: string,
  rules: StringRules,
): string {
  const raw = data[key];
  if (typeof raw !== "string") throw invalidArgument(`${key} must be a string.`);
  const value = rules.trim === false ? raw : raw.trim();
  if (value.length < rules.min || value.length > rules.max) {
    throw invalidArgument(`${key} must be ${rules.min}..${rules.max} characters.`);
  }
  if (rules.pattern && !rules.pattern.test(value)) {
    throw invalidArgument(`${key} has invalid characters.`);
  }
  return value;
}

/** An optional string field: undefined or null when absent. */
export function readOptionalString(
  data: Record<string, unknown>,
  key: string,
  rules: StringRules,
): string | undefined {
  if (data[key] === undefined || data[key] === null) return undefined;
  return readString(data, key, rules);
}

export function readBoolean(data: Record<string, unknown>, key: string): boolean {
  const value = data[key];
  if (typeof value !== "boolean") throw invalidArgument(`${key} must be a boolean.`);
  return value;
}

/** Trimmed and lower-cased, then 3..20 of [a-z0-9._-]. */
export function readUsername(data: Record<string, unknown>): string {
  const raw = data.username;
  if (typeof raw !== "string") throw invalidArgument("username must be a string.");
  return readString({username: raw.trim().toLowerCase()}, "username", {
    ...USERNAME_LENGTH,
    pattern: USERNAME_PATTERN,
  });
}

/** Not trimmed: spaces are part of a password. */
export function readPassword(data: Record<string, unknown>, key: string): string {
  return readString(data, key, {...PASSWORD_LENGTH, trim: false});
}

export function readFullName(data: Record<string, unknown>): string {
  return readString(data, "fullName", FULL_NAME_LENGTH);
}

export function readRole(data: Record<string, unknown>): Role {
  const role = data.role;
  if (typeof role !== "string" || !(ROLES as readonly string[]).includes(role)) {
    throw invalidArgument(`role must be one of ${ROLES.join(", ")}.`);
  }
  return role as Role;
}

export function readStudentCode(data: Record<string, unknown>): string | undefined {
  return readOptionalString(data, "studentCode", {
    min: 4,
    max: 6,
    pattern: STUDENT_CODE_PATTERN,
  });
}

/** A document id (uid, halaqaId, ...). */
export function readId(data: Record<string, unknown>, key: string): string {
  return readString(data, key, {...ID_LENGTH, pattern: /^[^/]+$/});
}

export function readOptionalId(
  data: Record<string, unknown>,
  key: string,
): string | undefined {
  return readOptionalString(data, key, {...ID_LENGTH, pattern: /^[^/]+$/});
}
