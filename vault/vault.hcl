storage "consul" {
  address = "consul.server:8500"
  path    = "vault"
  scheme  = "http"
  token   = "<<ACL_TOKEN>>"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}