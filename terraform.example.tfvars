kafka_credentials = {
    username = ""
    password = ""
}

postgres_credentials = {
    username = ""
    password = ""
    database = "ticketpond"
}

frontend_url = "http://localhost:3000"

jwt_secret = "secret"

auth0 = {
  issuer_url = ""
  audience   = "https://localhost:3001"
  client_id  = ""
  client_secret = ""
  callback_url = "http://localhost/auth/callback"
  domain = ""
  cookie_domain = "localhost"
}

email = {
  host         = "smtp.eu.mailgun.org"
  port         = "465"
  secure       = "true"
  username     = ""
  password     = ""
  from_name    = "Ticketpond"
  from_address = ""
}

wallet = {
  pass_type_identifier = ""
  organization_name    = ""
  team_identifier      = ""
  passphrase           = ""
}

stripe = {
  secret_key     = ""
  webhook_secret = ""
}