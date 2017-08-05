################################################################################
# The goal of this container is to provide a VA Appeals specific app
# environment that includes all the basic tools to run any appeals applications.
#
################################################################################
FROM ubuntu:16.04

################################################################################
# Basic development packages and tools
################################################################################
RUN apt-get update && apt-get install -y \
	sudo \
	curl \
	wget \
	grep \
	tar \
	build-essential \
	autoconf \
	zlib1g-dev \
	openssl \
	libssl-dev \
	libpq-dev \
	iputils-ping \
	netcat \
	libsqlite3-dev \
	pdftk \
	chrpath \
	libxft-dev \
	vim \
	git \
	libaio1

################################################################################
# Ruby 2.3, copied from the Ruby Dockerhub (https://hub.docker.com/_/ruby/)
################################################################################

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.1
ENV RUBY_DOWNLOAD_SHA256 b87c738cb2032bf4920fef8e3864dc5cf8eae9d89d8d523ce0236945c5797dcd
ENV RUBYGEMS_VERSION 2.6.6

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -ex \
	\
	&& buildDeps=' \
		bison \
		libgdbm-dev \
		ruby \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
	&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
	\
	&& mkdir -p /usr/src/ruby \
	&& tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.gz \
	\
	&& cd /usr/src/ruby \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	&& { \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new \
	&& mv file.c.new file.c \
	\
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& make install \
	\
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd / \
	&& rm -r /usr/src/ruby \
	\
	&& gem update --system "$RUBYGEMS_VERSION"

ENV BUNDLER_VERSION 1.15.3

RUN gem install bundler --version "$BUNDLER_VERSION"
RUN gem install rails

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"


################################################################################
# Oracle Instant Client for VACOLS
################################################################################
RUN curl -O https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/instant-client-12-1.tar.gz
RUN mkdir /opt/oracle
RUN tar xvfz instant-client-12-1.tar.gz -C /opt/oracle/
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so

################################################################################
# Node js
################################################################################
RUN curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
RUN apt-get install -y nodejs

################################################################################
# Create User $username
################################################################################
ARG username=dsva
ARG usergroup=users

RUN echo $username
RUN useradd -ms /bin/bash $username
RUN usermod -g $usergroup $username
RUN usermod -a -G $usergroup $username
RUN echo "$username:$usergroup" | chpasswd && adduser $username sudo
RUN echo "$username ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
ENV HOME /home/$username
WORKDIR /home/$username

################################################################################
# Permissions and Paths
################################################################################
RUN chown -R $username:users /home/$username/

USER $username

ENV TERM=xterm

ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1/

# Expose the Appeals app port number
EXPOSE 3000