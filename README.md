## Script to create from URL to Load balancer

This script facilitates the creation of all components necessary for a static website on the Google Cloud Platform. This includes the creation of a storage bucket, IP address, load balancer, HTTP to HTTPS redirection, SSL certificate, and the configuration of permissions for the bucket

### What it does

- Creates Bucket
- Sets bucket policy public
- Creates Static IP
- Creates SSL Certificate
- Creates backend bucket
- Enable CDN
- Creates Load balancers & URL maps (http redirect & https)
- Creates Target proxies
- Creates forwarding rules

### Requirement

- `gcloud` preinstalled and authenticated
- Ownership must be verified for the domain (in order to use the same name as domain for Storage buckets)

### Usage

Download `create-load-balancers.sh`
```
chmod +x create-load-balancers.sh
./create-load-balancers.sh test1.example.com test2.example.com
```

## License

This repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
