# AWS and Kaluza environment variables
set -Ux AWS_PROFILE ia-australia-sandbox

# Note: For secrets like NPM_TOKEN, create ~/.localrc.fish (not tracked in git)
# Example: set -Ux NPM_TOKEN your_token_here

set -Ux SLS_DEBUG *
set -Ux AWS_NODEJS_CONNECTION_REUSE_ENABLED 1 
set -Ux AWS_SDK_LOAD_CONFIG 1
set -Ux AWS_LOG_LEVEL debug

