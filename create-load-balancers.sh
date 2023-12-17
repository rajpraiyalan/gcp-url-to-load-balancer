#!/bin/bash

domains=("$@")

echo "Please enter the project id, eg:- 'temporal-studio-12345678'"
read project_name

project_name=`echo $project | sed -e 's/^[[:space:]]*//'`

endMessage=""

for domain in "${domains[@]}"; do
  dashed_domain="${domain//./-}"

  echo "-- Starting process for Domain ${domain} --"

  # Create Bucket
  gcloud storage buckets create "gs://$domain" --project="$project_name" --default-storage-class=STANDARD --location=ASIA --uniform-bucket-level-access

  # Set bucket policy public
  gcloud storage buckets add-iam-policy-binding "gs://$domain" --member=allUsers --role=roles/storage.objectViewer

  # Set index config
  gcloud storage buckets update "gs://$domain" --web-main-page-suffix=index.html --web-error-page=index.html

  # Create Static IP
  gcloud compute addresses create "$dashed_domain" --project="$project_name" --global --network-tier=PREMIUM --ip-version=IPV4

  # Create SSL Certificate
  gcloud beta compute ssl-certificates create "$dashed_domain" --project="$project_name" --global --domains="$domain"

  # Create backend bucket
  gcloud compute backend-buckets create "$dashed_domain" --gcs-bucket-name="$domain"

  # Enable CDN
  gcloud compute backend-buckets update "$dashed_domain" --enable-cdn --cache-mode=CACHE_ALL_STATIC

  url_map_redirect="redirects-${dashed_domain}"

  # Config map
  printf '%s\n' 'kind: compute#urlMap' "name: ${url_map_redirect}" 'defaultUrlRedirect:' '  redirectResponseCode: MOVED_PERMANENTLY_DEFAULT' '  httpsRedirect: True' >"/tmp/${url_map_redirect}.yaml"

  # Create Load balancer / UrlMaps
  gcloud compute url-maps create "$url_map_redirect" --default-backend-bucket="$dashed_domain"
  gcloud compute url-maps import "$url_map_redirect" --source "/tmp/${url_map_redirect}.yaml" --quiet
  gcloud compute url-maps create "$dashed_domain" --default-backend-bucket="$dashed_domain"

  http_proxy_name="${dashed_domain}-proxy"
  https_proxy_name="${dashed_domain}-proxy-https"

  # Create Target Proxy
  gcloud compute target-http-proxies create "$http_proxy_name" --url-map="$url_map_redirect"
  gcloud compute target-https-proxies create "$https_proxy_name" --url-map="$dashed_domain" --ssl-certificates="$dashed_domain"

  # Create forwarding rule
  gcloud compute forwarding-rules create "http-${dashed_domain}-f-r" \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --address="$dashed_domain" \
    --global \
    --target-http-proxy="$http_proxy_name" \
    --ports=80

  gcloud compute forwarding-rules create "https-${dashed_domain}-f-r" \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --address="$dashed_domain" \
    --global \
    --target-https-proxy="$https_proxy_name" \
    --ports=443

  ip=$(gcloud compute addresses describe "$dashed_domain" --global --format="value(address)")

  endMessage="$endMessage\n $domain: $ip"

  echo "-- Completed process for Domain ${domain} --"
done

echo -e $endMessage