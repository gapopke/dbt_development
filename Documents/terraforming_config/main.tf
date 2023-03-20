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
  warehouse_size = "large"

  auto_suspend = 60
}

  provider "snowflake" {
        alias = "security_admin"
        role  = "SECURITYADMIN"
    }

    resource "snowflake_role" "role" {
        provider = snowflake.security_admin
        name     = "TF_DEMO_SVC_ROLE"
    }

    resource "snowflake_database_grant" "grant" {
        provider          = snowflake.security_admin
        database_name     = snowflake_database.db.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }

    resource "snowflake_schema" "schema" {
        database   = snowflake_database.db.name
        name       = "TF_DEMO"
        is_managed = false
    }

    resource "snowflake_schema_grant" "grant" {
        provider          = snowflake.security_admin
        database_name     = snowflake_database.db.name
        schema_name       = snowflake_schema.schema.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }

    resource "snowflake_warehouse_grant" "grant" {
        provider          = snowflake.security_admin
        warehouse_name    = snowflake_warehouse.warehouse.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }

    resource "tls_private_key" "svc_key" {
        algorithm = "RSA"
        rsa_bits  = 2048
    }

    resource "snowflake_user" "user" {
        provider          = snowflake.security_admin
        name              = "tf_demo_user"
        default_warehouse = snowflake_warehouse.warehouse.name
        default_role      = snowflake_role.role.name
        default_namespace = "${snowflake_database.db.name}.${snowflake_schema.schema.name}"
        rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
    }

    resource "snowflake_role_grants" "grants" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.role.name
        users     = [snowflake_user.user.name]
    }