import os
#import oracledb

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

ENABLE_PROXY_FIX = True

SECRET_KEY = os.environ.get("SECRET_KEY")

SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE")
