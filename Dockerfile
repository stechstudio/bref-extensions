# This is the image we use for compiling things for Lambda.
# It already has all the tools in place, and we can just pull
# it from Dockerhub:
# https://cloud.docker.com/u/stechstudio/repository/docker/stechstudio/aws-lambda-build
FROM  stechstudio/aws-lambda-build
LABEL authors="Bubba Hines <bubba@stechstudio.com>"
LABEL vendor="Signature Tech Studio, Inc."
LABEL home="https://github.com/stechstudio/bref-extensions"

WORKDIR /root

# We need a base path for all the sourcecode we will build from.
ENV BUILD_DIR="/tmp/build"

# We need a base path for the builds to install to. This path must
# match the path that bref will be unpackaged to in Lambda.
ENV INSTALL_DIR="/opt/sts"

# We need some default compiler variables setup
ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig:/opt/bref/lib64/pkgconfig:/opt/bref/lib/pkgconfig:${PKG_CONFIG_PATH}" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:/opt/bref/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib:/opt/bref/lib64:/opt/bref/lib:${LD_LIBRARY_PATH}"

COPY --from=bref/runtime/php-full-73 /opt /opt

RUN mkdir -p ${BUILD_DIR} && mkdir -p ${INSTALL_DIR}/modules




###############################################################################
# Ghostscript
ENV VERSION_GS=9.26
ENV GS_BUILD_DIR=${BUILD_DIR}/ghostscript

RUN set -xe; \
    mkdir -p ${GS_BUILD_DIR}/bin; \
    curl -Ls https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${VERSION_GS//./}/ghostpdl-${VERSION_GS}.tar.gz \
  | tar xzC ${GS_BUILD_DIR} --strip-components=1


WORKDIR  ${GS_BUILD_DIR}/


RUN set -xe; \
    ./configure \
     --prefix=${INSTALL_DIR} \
    --disable-compile-inits \
    --enable-dynamic        \
    --with-drivers=FILES \
    --with-system-libtiff \
 && make install \
 && mkdir -p ${INSTALL_DIR}/include/ghostscript \
 && install -v -m644 base/*.h ${INSTALL_DIR}/include/ghostscript \
 && mkdir -p ${INSTALL_DIR}/share/ghostscript \
 && curl -Ls http://downloads.sourceforge.net/gs-fonts/ghostscript-fonts-std-8.11.tar.gz | tar xzC ${INSTALL_DIR}/share/ghostscript \
 && curl -Ls http://downloads.sourceforge.net/gs-fonts/gnu-gs-fonts-other-6.0.tar.gz | tar xzC ${INSTALL_DIR}/share/ghostscript \
 && /usr/bin/fc-cache -v ${INSTALL_DIR}/share/ghostscript/fonts/


###############################################################################
# Imagemagic
ENV VERSION_IMAGEMAGICK=6.9.10-10
ENV IMAGEMAGICK_BUILD_DIR=${BUILD_DIR}/imagemagick

RUN set -xe; \
    mkdir -p ${IMAGEMAGICK_BUILD_DIR}; \
    curl -Ls ftp://ftp.osuosl.org/pub/blfs/conglomeration/ImageMagick/ImageMagick-${VERSION_IMAGEMAGICK}.tar.xz \
  | tar xJC ${IMAGEMAGICK_BUILD_DIR} --strip-components=1

WORKDIR  ${IMAGEMAGICK_BUILD_DIR}/

RUN set -xe; \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --sysconfdir=${INSTALL_DIR}/etc \
        --enable-hdri     \
        --with-gslib    \
        --with-rsvg     \
        --disable-static \
 && make install-strip

###############################################################################
# Imagic PHP Extension
ENV VERSION_IMAGICK=3.4.3
ENV IMAGICK_BUILD_DIR=${BUILD_DIR}/imagick
RUN set -xe; \
    mkdir -p ${IMAGICK_BUILD_DIR}; \
    curl -Ls https://pecl.php.net/get/imagick-${VERSION_IMAGICK}.tgz\
  | tar xzC ${IMAGICK_BUILD_DIR} --strip-components=1


WORKDIR  ${IMAGICK_BUILD_DIR}/
RUN set -xe; \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --with-imagick=${INSTALL_DIR} \
 && make \
 && cp ${IMAGICK_BUILD_DIR}/modules/imagick.so ${INSTALL_DIR}/modules/imagick.so







