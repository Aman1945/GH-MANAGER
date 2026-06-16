/**
 * Check if two date ranges overlap.
 * Returns true if an overlap exists.
 */
function checkOverlap(existingCheckIn, existingCheckOut, newCheckIn, newCheckOut) {
  return existingCheckIn < newCheckOut && existingCheckOut > newCheckIn;
}

/**
 * Create an error with a statusCode attached.
 */
function createError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

module.exports = { checkOverlap, createError };
