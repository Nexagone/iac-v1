terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.34.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_generic_secret" "ovh_credentials" {
  path = "secret/ovh"
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = data.vault_generic_secret.ovh_credentials.data["application_key"]
  application_secret = data.vault_generic_secret.ovh_credentials.data["application_secret"]
  consumer_key       = data.vault_generic_secret.ovh_credentials.data["consumer_key"]
} 