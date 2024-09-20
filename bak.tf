terraform {
backend "s3" {
bucket = "sharief123"
region = "us-east-1"
key = "terform/terform.tfstate"
dynamodb_table = "hameed"
}
}
