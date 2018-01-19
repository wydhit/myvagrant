#!/usr/bin/env bash

defaultPhpVersion=php5.6
defaultPhpVersion=$1

if [ -e /usr/local/${defaultPhpVersion}/bin/php ] ; then
    [ -e /usr/bin/php ] && rm /usr/bin/php
    [ -e /usr/bin/phpize ] && rm /usr/bin/phpize
    [ -e /usr/bin/php-config ] && rm /usr/bin/php-config
    [ -e /usr/bin/pecl ] && rm /usr/bin/pecl
    [ -e /usr/bin/pear ] && rm /usr/bin/pear
    [ -e /usr/sbin/php-fpm ] && rm /usr/sbin/php-fpm

    ln -sf /usr/local/${defaultPhpVersion}/bin/php /usr/bin/php
    ln -sf /usr/local/${defaultPhpVersion}/bin/phpize /usr/bin/phpize
    ln -sf /usr/local/${defaultPhpVersion}/bin/php-config /usr/bin/php-config
    ln -sf /usr/local/${defaultPhpVersion}/bin/pear /usr/bin/pear
    ln -sf /usr/local/${defaultPhpVersion}/bin/pecl /usr/bin/pecl
    ln -sf /usr/local/${defaultPhpVersion}/sbin/php-fpm /usr/sbin/php-fpm
    echo "更改php版本 ${defaultPhpVersion} 成功！"
else
    echo "php版本必须为 'php5.6','php7.0','php7.1','php7.2'  中的一个"
fi

