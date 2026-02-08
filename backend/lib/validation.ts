/**
 * Validation Schemas using Zod
 *
 * All input validation for API endpoints
 */

import { z } from 'zod';

/**
 * Email validation schema
 */
export const emailSchema = z.string().email('Invalid email format');

/**
 * Password validation schema
 * Requirements: 8+ chars, uppercase, lowercase, number, special char
 */
export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must include at least one uppercase letter')
  .regex(/[a-z]/, 'Password must include at least one lowercase letter')
  .regex(/[0-9]/, 'Password must include at least one number')
  .regex(/[@$!%*?&#]/, 'Password must include at least one special character (@$!%*?&#)');

/**
 * User signup schema
 */
export const signupSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  name: z.string().min(1, 'Name is required').max(100, 'Name is too long').optional()
});

/**
 * User login schema
 */
export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required')
});

/**
 * Device registration schema
 */
export const deviceRegistrationSchema = z.object({
  serial_number: z
    .string()
    .min(1, 'Serial number is required')
    .regex(/^DTX-\d{4}-\d{6}$/, 'Invalid serial number format (expected: DTX-YYYY-NNNNNN)'),
  model_name: z.enum(['DualTetraX Pro', 'DualTetraX Lite'], {
    errorMap: () => ({ message: 'Invalid model name' })
  }),
  firmware_version: z
    .string()
    .regex(/^\d+\.\d+\.\d+$/, 'Invalid firmware version format (expected: X.Y.Z)')
    .optional(),
  ble_mac_address: z
    .string()
    .regex(/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/, 'Invalid MAC address format')
    .optional()
});

/**
 * UUID validation schema
 */
export const uuidSchema = z.string().uuid('Invalid UUID format');

/**
 * Helper function to validate request body
 * Returns validated data or throws error
 */
export function validateBody<T>(schema: z.ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data);

  if (!result.success) {
    const errors = result.error.errors.map(err => ({
      field: err.path.join('.'),
      message: err.message
    }));

    throw {
      status: 400,
      error: 'Validation error',
      details: errors
    };
  }

  return result.data;
}
