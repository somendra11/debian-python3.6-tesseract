# VERSION 0.1
# AUTHOR: Somendra Joshi
# DESCRIPTION: Python tesseract container

FROM debian:stretch
MAINTAINER somendra11

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install python and its packages
RUN echo "deb http://ftp.de.debian.org/debian testing main"  >> /etc/apt/sources.list \
 && echo 'APT::Default-Release "stable";' | tee -a /etc/apt/apt.conf.d/00local \
 && apt-get update \
 && apt-get -t testing install -y python3.6 python3-pip git vim wget procps screen \
 && apt-get install -y curl unzip \
 && ln -s /usr/bin/python3.6 /usr/bin/python \
 && ln -s /usr/bin/pip3 /usr/bin/pip \
 && pip install py4j fuzzywuzzy inflect jupyter \
   nltk scipy widgetsnbextension unidecode \
 && mkdir /root/.jupyter \
 && echo "c.NotebookApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.password = u'sha1:a83f58e93d8d:224a80c49eff21735f7356ffa92a10c5a529585b'" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.password_required = True" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.port = 8022" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.allow_root = True" >> /root/.jupyter/jupyter_notebook_config.py \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_UPDATE_VERSION=181
ARG JAVA_BUILD_NUMBER=13
ENV JAVA_HOME /usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}

ENV PATH $PATH:$JAVA_HOME/bin
RUN curl -sL --retry 3 --insecure \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/96a7b8442fe848ef90c96a2fad6ed6d1/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_HOME /usr/java \
  && rm -rf $JAVA_HOME/man

# Installing Tesseract
RUN apt-get --yes update; \
  apt-get --yes install autoconf automake libtool; \
  apt-get --yes install autoconf-archive; \
  apt-get --yes install pkg-config; \
  apt-get --yes install libjpeg-dev; \
  apt-get --yes --allow-downgrades install zlib1g=1:1.2.8.dfsg-5 zlib1g-dev; \
  apt-get --yes --allow-downgrades install libpng16-16=1.6.28-1 libpng-dev; \
  apt-get clean \
  && rm -rf /var/lib/apt/lists/*
  # apt-get --yes --allow-downgrades install libtiff5-dev=4.0.9-1;

RUN cd /tmp/ && \
  wget http://www.leptonica.com/source/leptonica-1.76.0.tar.gz && \
  tar xvzf leptonica-1.76.0.tar.gz && \
  cd leptonica-1.76.0 && \
  ./configure && \
  make && \
  make install && \
  rm -rf /tmp/* && \
  cd /tmp/ && \
  wget https://github.com/tesseract-ocr/tesseract/archive/3.05.01.tar.gz && \
  tar xvzf 3.05.01.tar.gz && \
  cd tesseract-3.05.01 && \
  sed -i '$ d' api/Makefile.am && \
  sed -i '$ d' api/Makefile.am && \
  echo 'tesseract_LDADD += -lrt -llept' >> api/Makefile.am && \
  echo 'endif' >> api/Makefile.am && \
  ./autogen.sh && \
  ./configure --enable-debug && \
  LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" make && \
  make install && \
  ldconfig && \
  rm -rf /tmp/* && \
  wget -O /usr/local/share/tessdata/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata

# install python packages
RUN pip3 install tesserocr matplotlib  pandas \
pdf2image python-Levenshtein scikit-learn  seaborn pytesseract

CMD ["jupyter, "notebook"]
