storage "consul" {
  address = "<<CONSUL_SERVER>>"
  path    = "vault"
  scheme  = "https"
  token   = "<<ACL_TOKEN>>"
  tls_cert_file = "/consul/certs/cert.pem"
  tls_ca_file   = "/consul/certs/fullchain.pem"
  tls_key_file  = "/consul/certs/key.pem"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/consul/certs/cert.pem"
  tls_key_file  = "/consul/certs/key.pem"
}