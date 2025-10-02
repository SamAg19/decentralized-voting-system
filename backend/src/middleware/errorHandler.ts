import { Request, Response, NextFunction } from "express";

export interface ApiError extends Error {
  statusCode?: number;
  code?: string;
  details?: any;
}

/**
 * Global error handling middleware
 */
export function errorHandler(
  err: ApiError,
  req: Request,
  res: Response,
  next: NextFunction
) {
  console.error("Error:", err);

  // Default status code
  let statusCode = err.statusCode || 500;

  // Determine error type and message
  let errorType = "ServerError";
  let message = err.message || "An unexpected error occurred";
  let details = err.details || {};

  // Handle blockchain/contract errors
  if (err.code === "CALL_EXCEPTION" || err.message?.includes("execution reverted") || err.message?.includes("Returned error") || err.message?.includes("Internal error")) {
    errorType = "ContractError";
    message = "Contract execution failed. Please check the transaction parameters and contract state.";
    statusCode = 400;
  }

  // Send error response
  res.status(statusCode).json({
    success: false,
    error: errorType,
    message,
    ...(process.env.NODE_ENV === "development" && { details: err.stack }),
  });
}


/**
 * Async handler wrapper to catch errors in async route handlers
 */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}
