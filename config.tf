terraform {
  required_version = "~> 0.14.0"

  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.1.3"
    }
  }

  // create bucket in advance
  // @see README.md
//  backend "s3" {
//    bucket = "kiyotake-todo-vultr-terraform"
//    key = "terraform.tfstate"
//    region = "ap-northeast-1"
//  }
}

# Configure the Vultr Provider
provider "vultr" {
  // export VULTR_API_KEY="ABCDEFG1234567890101112HIJKLMNOPQRST"
  // api_key = VULTR_API_KEY
  rate_limit = 700
  retry_limit = 3
}

