SSL_PEM_FILE=${SSL_PEM_FILE:-${APP_DATA}/mongodb-ssl/mongodb.pem}
SSL_CA_FILE=${SSL_CA_FILE:-${APP_DATA}/mongodb-ssl/ca.pem}

if [ -f "${SSL_PEM_FILE}" ]; then
  log_info "SSL/TLS enabled"
  mongo_common_args+=" --sslMode requireSSL --sslPEMKeyFile ${SSL_PEM_FILE}"
  shell_args+=" --ssl --sslPEMKeyFile ${SSL_PEM_FILE}"

  if [ ! -f "${SSL_CA_FILE:-}" ]; then
    log_info "A certificate authority was not set. Assuming self-signed"
    shell_args+=" --sslAllowInvalidCertificates"
  else
    mongo_common_args+=" --sslCAFile ${SSL_CA_FILE}"
    shell_args+=" --sslCAFile ${SSL_CA_FILE}"
  fi
fi
