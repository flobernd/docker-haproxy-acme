#!/bin/bash
set -e

echo "Registering ACME account for '$ACME_MAIL' on '$ACME_SERVER' ..."

args=(
    "--server" "$ACME_SERVER"
    "--register-account"
    "-m" "$ACME_MAIL"
)

if [ $ACME_DEBUG -eq 1 ]; then
    args+=("--debug")
fi

input=$(acme.sh "${args[@]}") || (echo "$input" && exit 1)

pattern="^.*ACCOUNT_THUMBPRINT='([a-zA-Z0-9_-]+)'$"

if [[ $input =~ $pattern ]]; then
    export ACME_ACCOUNT_THUMBPRINT="${BASH_REMATCH[1]}"

    if [[ $input == *"Already registered"* ]]; then
        echo "Already registered"
    else
        echo "Account created"
    fi

    echo "ACME account thumbprint:"
    echo "$ACME_ACCOUNT_THUMBPRINT"
else
    echo "Failed to extract ACME account thumbprint:"
    echo "$input"
    exit 1
fi
