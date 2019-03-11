FROM php:7.1-apache-stretch

# Install Linux basic packages for development
RUN apt-get update \
    && apt-get install -yq \
       git \
       vim \
       mysql-client \
       zip unzip \
       curl \ 
       apt-utils apt-transport-https \
       debconf-utils \
       gcc g++ \ 
       gnupg \
       build-essential \
    && rm -rf /var/lib/apt/lists/*

# Hack for debian-slim to make the jdk install work below.
RUN mkdir -p /usr/share/man/man1

# repo needed for jdk install below.
RUN echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/backports.list

# Update image & install application dependant packages.
RUN apt-get update && apt-get install -y \
nano \
libxext6 \
libfreetype6-dev \
libjpeg62-turbo-dev \
libpng-dev \
libmcrypt-dev \
libxslt-dev \
libpcre3-dev \
libxrender1 \
libfontconfig \
uuid-dev \
ghostscript \
curl \
wget \
ca-certificates-java

RUN apt-get -t stretch-backports install -y default-jdk-headless


# Install PHP Required extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli 

# ADD SUPPORT TO SQL Server

# adding custom MS repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

# install SQL Server drivers
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y unixodbc-dev msodbcsql 

# install SQL Server tools
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y mssql-tools \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
    && /bin/bash -c "source ~/.bashrc"

# install necessary locales
RUN apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

# install SQL Server PHP connector module 
RUN pecl install sqlsrv pdo_sqlsrv

# initial configuration of SQL Server PHP connector
RUN echo "extension=/usr/lib/php/20151012/sqlsrv.so" >> /usr/local/etc/php/sqlsrv.ini \
    && echo "extension=/usr/lib/php/20151012/pdo_sqlsrv.so" >> /usr/local/etc/php/sqlsrv.ini

# Enable apache modules
RUN a2enmod rewrite \
    headers

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

# Show installed packages
RUN php -m
RUN java --version