# hyperf/hyperf:8.0
#
# @link     https://www.hyperf.io
# @document https://hyperf.wiki
# @contact  group@hyperf.io
# @license  https://github.com/hyperf/hyperf/blob/master/LICENSE

ARG ALPINE_VERSION=3.15

FROM hyperf/hyperf:8.0-alpine-v3.12-swoole

LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    #    APP_ENV=dev \
    APP_SYSTEM_ENV=docker \
    SCAN_CACHEABLE=(true)

# update
RUN set -ex \
    #  ---------- some config ----------
    && cd /etc/php8 \
    # - config PHP
    && { \
        echo "upload_max_filesize=128M"; \
        echo "post_max_size=128M"; \
        echo "memory_limit=1G"; \
        echo "opcache.enable_cli = 'On'"; \
        echo "swoole.use_shortname = 'Off'"; \
        echo "date.timezone=${TIMEZONE}"; \
    } | tee conf.d/99_overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"


# fix aliyun oss wrong charset: https://github.com/aliyun/aliyun-oss-php-sdk/issues/101
# https://github.com/docker-library/php/issues/240#issuecomment-762438977

RUN apk --no-cache --allow-untrusted --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ add gnu-libiconv gnu-libiconv-dev \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/local/bin/php* \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

WORKDIR /www

# Composer Cache
# COPY ./composer.* /www/
# RUN composer install --no-dev --no-scripts

COPY . /www
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer && composer install --no-dev -o && php bin/hyperf.php

EXPOSE 9501 9502 9503

ENTRYPOINT ["php","/www/bin/hyperf.php","start"]
