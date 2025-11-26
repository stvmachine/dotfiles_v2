# AWS and Kaluza environment variables
set -Ux AWS_PROFILE ia-australia-sandbox

set -Ux SLS_DEBUG *
set -Ux AWS_NODEJS_CONNECTION_REUSE_ENABLED 1 
set -Ux AWS_SDK_LOAD_CONFIG 1
set -Ux AWS_LOG_LEVEL debug

