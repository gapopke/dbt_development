terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.35"
    }
  }
}

provider "snowflake" {
    account = "JPB37970.us-east-1"
    # region = "your-region-here" # fill-in only if required
    username = "GARRISONPOPKE"
    password = "G703860p" # do not use, we'll set an env var instead
    role = "accountadmin"

}

resource "snowflake_database" "database" {
  name      = "tf_database"

}

resource "snowflake_schema" "schema" {
  database  = snowflake_database.database.name
  name      = "my_tf_schema"
}

resource "snowflake_table" "table" {
  database  = snowflake_database.database.name
  schema    = snowflake_schema.schema.name
  name      = "my_tf_table"
column {
    name     = "id"
    type     = "int"
  }
  column {
    name     = "data"
    type     = "text"
  }
}


resource "snowflake_warehouse" "warehouse" {
  name           = "TF_DEMO"
  warehouse_size = "medium"

  auto_suspend = 60
}