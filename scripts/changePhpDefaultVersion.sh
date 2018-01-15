#!/usr/bin/env bash

defaultPhpVersion=php5.6
defaultPhpVersion=$1
sudo rm /usr/bin/php
sudo ln -sf /usr/local/${defaultPhpVersion}/bin/php /usr/bin/php
sudo rm /usr/bin/phpize
sudo ln -sf /usr/local/${defaultPhpVersion}/bin/phpize /usr/bin/phpize
sudo rm /usr/bin/php-config
sudo ln -sf /usr/local/${defaultPhpVersion}/bin/php-config /usr/bin/php-config
sudo rm /usr/bin/pear
sudo ln -sf /usr/local/${defaultPhpVersion}/bin/pear /usr/bin/pear
sudo rm /usr/bin/pecl
sudo ln -sf /usr/local/${defaultPhpVersion}/bin/pecl /usr/bin/pecl
sudo rm /usr/bin/php-fpm
sudo ln -sf /usr/local/${defaultPhpVersion}/sbin/php-fpm /usr/bin/php-fpm