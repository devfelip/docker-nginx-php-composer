[![Docker Hub; felipecs8/nginx-php-composer](https://img.shields.io/badge/docker%20hub-felipecs8%2Fnginx--php--fpm-blue.svg?&logo=docker&style=for-the-badge)](https://hub.docker.com/r/felipecs8/nginx-php-composer/) [![](https://badges.weareopensource.me/docker/pulls/felipecs8/nginx-php-composer?style=for-the-badge)](https://hub.docker.com/r/felipecs8/nginx-php-composer/) [![](https://img.shields.io/docker/image-size/felipecs8/nginx-php-composer/php80?style=for-the-badge)](https://hub.docker.com/r/felipecs8/nginx-php-composer/) [![nginx 1.21.6](https://img.shields.io/badge/nginx-1.21.6-brightgreen.svg?&logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES) [![php 8.0.16](https://img.shields.io/badge/php--fpm-8.0.16-blue.svg?&logo=php&logoColor=white&style=for-the-badge)](https://secure.php.net/releases/8_0_16.php) [![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](https://github.com/felipecs8/nginx-php-composer/blob/master/LICENSE)

## Introduction
This is a Dockerfile to build a debian based container image running nginx and php-fpm 8.0.x / 7.4.x / 7.3.x / 7.2.x / 7.1.x / 7.0.x & Composer.

### Versioning
| Docker Tag | GitHub Release | Nginx Version | PHP Version | Debian Version | Composer
|-----|-------|-----|--------|--------|------|
| latest | main Branch |1.27.2 | 8.0.30 | bookworm | 2.8.3 |
| php80 | php80 Branch |1.27.2 | 8.0.30 | bookworm | 2.8.3 |
| php74 | php74 Branch |1.27.2 | 7.4.33 | bookworm | 2.8.3 |
| php73 | php73 Branch |1.27.2 | 7.3.33 | bookworm | 2.8.3 |

## Building from source
To build from source you need to clone the git repo and run docker build:
```
$ git clone https://github.com/felipecs8/nginx-php-composer.git
$ cd nginx-php-composer
```

followed by
```
$ docker build -t nginx-php-composer:php74 . # PHP 7.4.x
```


## Pulling from Docker Hub
```
$ docker pull felipecs8/nginx-php-composer:php80
```

## Running
To run the container:
```
$ sudo docker run -d felipecs8/nginx-php-composer:php80
```

Default web root:
```
/usr/share/nginx/html
```

## REFS
https://www.oracle.com/br/database/technologies/instant-client/linux-x86-64-downloads.html

https://pecl.php.net/package/pdo_oci

https://getcomposer.org/download/

https://pecl.php.net/package/oci8
