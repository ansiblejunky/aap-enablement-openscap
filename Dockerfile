FROM	debian:stable as scap_training

# make sure the package repository is up to date
RUN echo "deb http://deb.debian.org/debian/ buster main contrib non-free" > /etc/apt/sources.list
RUN apt-get update

# debian packages dependencies to build uptodate openscap & scap-security-guide
RUN apt-get install -yq \
    bzip2 \
    libpcre3-dev \
    libxml2-dev \
    libxslt1-dev \
    swig \
    python3 \
    python3-pip \
    python3-dev \
    python3-requests \
    python3-yaml \
    python3-jinja2 \
    python3-lxml \
    python3-pytest \
    python3-pytest-cov \
    valgrind \
    xsltproc \
    expat \
    libxml2-utils \
    cmake \
    build-essential \
    libperl-dev \
    libcurl4-openssl-dev \
    libgcrypt-dev \
    libapt-pkg-dev \
    libselinux1-dev \
    libcap-dev \
    libldap2-dev \
    libbz2-dev \
    pkg-config \
    libdbus-1-dev \
    ssh-askpass \
    ksshaskpass \
    libyaml-dev \
    libopendbx1-dev \
    libgconf2-dev \
    libblkid-dev \
    libqt5xmlpatterns5-dev \
    librpm-dev \
    valgrind \
    asciidoc \
    doxygen \
    openssh-client \
    util-linux \
    shellcheck \
    linkchecker \
    ansible \
    ansible-lint \
    yamllint \
    bats \
    firefox-esr \
    bash \
    sudo \
    policykit-1 \
    wget

# get back openscap & ssg last releases
RUN mkdir -p /tmp/build/
WORKDIR  /tmp/build
RUN wget -q -O openscap-1.3.4.tar.gz https://github.com/OpenSCAP/openscap/releases/download/1.3.4/openscap-1.3.4.tar.gz
RUN wget -q -O openscap-1.3.4.tar.gz.sha512 https://github.com/OpenSCAP/openscap/releases/download/1.3.4/openscap-1.3.4.tar.gz.sha512
RUN sha512sum -c openscap-1.3.4.tar.gz.sha512

RUN wget -q -O ssg-0.1.53.tar.gz https://github.com/ComplianceAsCode/content/archive/v0.1.53.tar.gz
# no delivered checksum for SSG
RUN echo "a908828fdf1ef0bbe6d5fe92b8e7a4192c0fd06f447de6f851f46b929a4e1b17  ssg-0.1.53.tar.gz" > ssg-0.1.53.tar.gz.sha256sum
RUN sha256sum -c ssg-0.1.53.tar.gz.sha256sum

RUN wget -q -O scap-workbench-1.2.1.tar.bz2 https://github.com/OpenSCAP/scap-workbench/releases/download/1.2.1/scap-workbench-1.2.1.tar.bz2
RUN wget -q -O scap-workbench-1.2.1.tar.bz2.sha512sum https://github.com/OpenSCAP/scap-workbench/releases/download/1.2.1/scap-workbench-1.2.1.tar.bz2.sha512sum
RUN sha512sum -c scap-workbench-1.2.1.tar.bz2.sha512sum

# decompress archives
RUN tar -xf openscap-1.3.4.tar.gz
RUN tar -xf ssg-0.1.53.tar.gz
RUN tar -xf scap-workbench-1.2.1.tar.bz2

# add missing unpackaged dependency
RUN pip3 install json2html

# Building openscap probes
WORKDIR  /tmp/build/openscap-1.3.4/build
RUN cmake ..
RUN make -j$(nproc)
RUN make install

# building Content (ex. SSG) Security Policies & Guides
WORKDIR  /tmp/build/content-0.1.53/build
RUN cmake ..
RUN make -j$(nproc)
RUN make install

# building SCAP Workbench graphial tool
WORKDIR  /tmp/build/scap-workbench-1.2.1/build

RUN cmake -DSCAP_WORKBENCH_LOCAL_SCAN_ENABLED=TRUE \
          -DSCAP_WORKBENCH_SSG_DIRECTORY:PATH=/usr/local/share/xml/scap/ssg/content \
          -DSCAP_WORKBENCH_SCAP_CONTENT_DIRECTORY:PATH=/usr/local/share/xml/scap \
          -DOPENSCAP_VERSION:STRING="1.3.4" \
          ..
RUN make -j$(nproc)
RUN make install

# removing build-depends
RUN echo "set -x; for i in \$(dpkg -l |grep 'ii'|grep -- '-dev' | awk '{ print \$2 }'); do apt-get remove -yq \$i; done" > purge.sh
RUN chmod +x purge.sh
RUN ./purge.sh
RUN rm purge.sh
RUN apt-get remove -yq gcc cmake make
WORKDIR  /tmp
RUN rm -rf /tmp/build

# create sample user
RUN groupadd oscap
RUN useradd -d /home/oscap -ms /bin/bash -g oscap oscap;
RUN /bin/dash -c 'echo "oscap    ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/oscap; \
                  chmod 0440 /etc/sudoers.d/oscap'

# and select him
USER oscap:oscap
WORKDIR  /home/oscap

# set proper LD_LIBRARY_PATH as compiled content is in /usr/local
ENV LD_LIBRARY_PATH /usr/local/lib

# ready now
CMD ["/bin/bash"] 