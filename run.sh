#!/bin/bash

envvars_exception(){
  echo "-------------------------------------------------------------------------------"
  echo "# The following environment vars are read"
  echo "  - DOMAIN_NAME - *.domain.com"
  echo "  - DOMAIN_OUTPUT_PATH - domain.com"
  echo "  - CONTACT_EMAIL - john@doe.com"
  echo "  - AWS_DEFAULT_REGION - us-east-1"
  echo "  - AWS_ACCESS_KEY_ID - F9Y6KUHL86BTTTEL"
  echo "  - AWS_SECRET_ACCESS_KEY - YVSECDHAJVHBV437DZ65GTG59NF923G9"
  echo "  - AWS_CONTAINER_CREDENTIALS_RELATIVE_URI - to use the utility without key/secret"
  echo "  - CERT_ARN (optional) - Only if you're renewing and want to update it on AWS"
  echo "  - DRYRUN=true (optional) - Runs certbot only with the --dry-run for testing"
  echo "-------------------------------------------------------------------------------\n"
  exit 0;
}

mandatory_vars=(
  "DOMAIN_NAME"
  "DOMAIN_OUTPUT_PATH"
  "CONTACT_EMAIL"
  "AWS_DEFAULT_REGION"
)

check_vars(){
  for each in "${mandatory_vars[@]}"; do
      if [ -z "${!each+x}" ]; then
          echo "$each is not defined"
          envvars_exception
      fi
  done
}

call_certbot(){
  certbot \
    certonly \
    --agree-tos \
    --keep \
    --eff-email \
    --dns-route53 \
    --dns-route53-propagation-seconds 30 \
    --key-type rsa \
    -m $CONTACT_EMAIL \
    -d $DOMAIN_NAME
}

test_certbot(){
  certbot \
    certonly \
    --agree-tos \
    --keep \
    --eff-email \
    --dns-route53 \
    --dry-run \
    --dns-route53-propagation-seconds 30 \
    --key-type rsa \
    -m $CONTACT_EMAIL \
    -d $DOMAIN_NAME 
}

aws_create_cert(){
  aws acm import-certificate \
    --certificate file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/cert.pem \
    --private-key file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/privkey.pem \
    --certificate-chain file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/chain.pem
}

aws_update_cert(){
  aws acm import-certificate \
    --certificate file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/cert.pem \
    --private-key file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/privkey.pem \
    --certificate-chain file:///etc/letsencrypt/live/$DOMAIN_OUTPUT_PATH/chain.pem \
    --certificate-arn $CERT_ARN
}

new_cert(){ 
  call_certbot && aws_create_cert 
}

renew_cert(){ 
  call_certbot && aws_update_cert 
}

check_vars

if [ "$DRYRUN" = "true" ]; then
  test_certbot
  exit 0
fi

if [ -z "$CERT_ARN" ] ; then
    new_cert
else
    renew_cert
fi
