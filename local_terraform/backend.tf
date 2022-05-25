terraform {
  backend "s3" {
    region  = "eu-west-1"
    bucket  = "mybucketname"
    key     = "local.tfstate"
  }
}