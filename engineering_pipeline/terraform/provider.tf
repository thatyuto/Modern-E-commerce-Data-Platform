terraform {
    required_version = ">= 1.5.0"
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~> 5.0"
        }
    }
}

provider "google" {
    project = "yuto-olist_raw_data"
    region = "us"
}

