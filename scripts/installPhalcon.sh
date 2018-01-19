#!/usr/bin/env bash
thisDir=$(pwd)
sourceDir="${thisDir}/../resources"
cd $sourceDir

#[ ! -e cphalcon-3.3.1  ] && tar zxvf cphalcon-3.3.1.tar.gz
#pushd cphalcon-3.3.1/build

#sudo ./install --phpize /usr/local/php5.6/bin/phpize --php-config /usr/local/php5.6/bin/php-config
#sudo ./install --phpize /usr/local/php7.0/bin/phpize --php-config /usr/local/php7.0/bin/php-config
#sudo ./install --phpize /usr/local/php7.1/bin/phpize --php-config /usr/local/php7.1/bin/php-config
#sudo ./install --phpize /usr/local/php7.2/bin/phpize --php-config /usr/local/php7.2/bin/php-config
#popd
#[  -e cphalcon-3.3.1  ] && rm -rf cphalcon-3.3.1


#[ ! -e php-zephir-parser-1.1.1  ] && tar zxvf php-zephir-parser-1.1.1.tar.gz
#pushd php-zephir-parser-1.1.1
#sudo ./install-development --phpize /usr/local/php5.6/bin/phpize --php-config /usr/local/php5.6/bin/php-config --install
#sudo ./install-development --phpize /usr/local/php7.0/bin/phpize --php-config /usr/local/php7.0/bin/php-config --install
#sudo ./install-development --phpize /usr/local/php7.1/bin/phpize --php-config /usr/local/php7.1/bin/php-config --install
#sudo ./install-development --phpize /usr/local/php7.2/bin/phpize --php-config /usr/local/php7.2/bin/php-config --install
#popd
#[  -e php-zephir-parser-1.1.1  ] && rm -rf php-zephir-parser-1.1.1

[ ! -e zephir-0.10.7  ] && tar zxvf zephir-0.10.7.tar.gz
sudo cp -r  zephir-0.10.7 /opt/
pushd /opt/zephir-0.10.7
sudo ./install -c
popd
[  -e zephir-0.10.7  ] && rm -rf zephir-0.10.7