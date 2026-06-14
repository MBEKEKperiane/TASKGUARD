const notFound = (req, res, next) => {
  const error = new Error(`Not found: ${req.originalUrl}`);
  error.status = 404;
  next(error);
};

const errorHandler = (err, req, res, next) => {
  const status = err.status || err.statusCode || 500;

  // Prisma unique constraint violation
  if (err.code === 'P2002') {
    return res.status(409).json({ error: 'A record with this value already exists.' });
  }

  // Prisma record not found
  if (err.code === 'P2025') {
    return res.status(404).json({ error: 'Record not found.' });
  }

  // Validation errors from express-validator
  if (err.type === 'validation') {
    return res.status(422).json({ error: err.message, details: err.details });
  }

  if (process.env.NODE_ENV === 'development') {
    console.error(err.stack);
  }

  res.status(status).json({
    error: status === 500 ? 'Internal server error.' : err.message,
  });
};

module.exports = { notFound, errorHandler };
