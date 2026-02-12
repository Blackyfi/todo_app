const path = require('path');

module.exports = {
  certPath: process.env.SSL_CERT_PATH || path.join(__dirname, '../ssl/cert.pem'),
  keyPath: process.env.SSL_KEY_PATH || path.join(__dirname, '../ssl/key.pem'),

  // SSL options for HTTPS server
  options: {
    minVersion: 'TLSv1.2',
    ciphers: [
      'ECDHE-ECDSA-AES128-GCM-SHA256',
      'ECDHE-RSA-AES128-GCM-SHA256',
      'ECDHE-ECDSA-AES256-GCM-SHA384',
      'ECDHE-RSA-AES256-GCM-SHA384',
    ].join(':'),
  },
};
