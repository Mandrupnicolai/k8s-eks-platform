'use strict';
const express  = require('express');
const helmet   = require('helmet');
const pinoHttp = require('pino-http');
const router   = require('./router');
const PORT = parseInt(process.env.PORT || '3000', 10);
const ENV  = process.env.APP_ENV || 'development';
const app = express();
app.use(helmet());
app.use(pinoHttp({ level: ENV === 'production' ? 'info' : 'debug' }));
app.use(express.json());
app.use('/', router);
app.use((err, _req, res, _next) => {
  res.status(err.status || 500).json({ error: ENV === 'production' ? 'Internal server error' : err.message });
});
if (require.main === module) {
  app.listen(PORT, () => console.log(`API listening on port ${PORT} [${ENV}]`));
}
module.exports = app;
