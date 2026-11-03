import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors.js';

// Body-parser errors are client errors; internal SyntaxErrors are server errors.
const bodyErrors: Record<
  string,
  { status: number; code: string; message: string }
> = {
  'entity.parse.failed': {
    status: 400,
    code: 'INVALID_REQUEST',
    message: 'Malformed JSON request.',
  },
  'entity.too.large': {
    status: 413,
    code: 'PAYLOAD_TOO_LARGE',
    message: 'Request body is too large.',
  },
  'encoding.unsupported': {
    status: 415,
    code: 'UNSUPPORTED_ENCODING',
    message: 'Unsupported request encoding.',
  },
  'charset.unsupported': {
    status: 415,
    code: 'UNSUPPORTED_CHARSET',
    message: 'Unsupported request charset.',
  },
};

export const errorHandler: ErrorRequestHandler = (
  error: unknown,
  _req,
  res,
  next,
) => {
  if (res.headersSent) {
    next(error);
    return;
  }

  if (error instanceof ZodError) {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request.',
        fields: error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      },
    });
    return;
  }

  if (error instanceof AppError) {
    res
      .status(error.status)
      .json({ error: { code: error.code, message: error.message } });
    return;
  }

  if (
    error instanceof Error &&
    'type' in error &&
    typeof error.type === 'string'
  ) {
    const response = Object.hasOwn(bodyErrors, error.type)
      ? bodyErrors[error.type]
      : undefined;
    if (response) {
      const { status, ...details } = response;
      res.status(status).json({ error: details });
      return;
    }
  }

  // Express marks path-decoding failures as HTTP 400.
  if (error instanceof URIError && 'status' in error && error.status === 400) {
    res.status(400).json({
      error: { code: 'INVALID_REQUEST', message: 'Malformed request path.' },
    });
    return;
  }

  console.error('Unhandled request error');
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    },
  });
};
