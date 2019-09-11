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

RUN LD_LIBRARY_PATH="" yum install -y \
    glib2-devel \
	expat-devel \
	libjpeg-turbo-devel \
	giflib-devel \
	libtiff-devel \
	lcms2-devel \
	libpng-devel \
	gobject-introspection \
	gobject-introspection-devel

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
    phpize \
 && ./configure \
        --prefix=${INSTALL_DIR} \
        --with-imagick=${INSTALL_DIR} \
 && make \
 && cp ${IMAGICK_BUILD_DIR}/modules/imagick.so ${INSTALL_DIR}/modules/imagick.so

###############################################################################
# orc
#
ENV VERSION_ORC=0.4.28
ENV ORC_BUILD_DIR=${BUILD_DIR}/orc
RUN set -xe; \
	mkdir -p ${ORC_BUILD_DIR}; \
	curl -Ls https://gstreamer.freedesktop.org/data/src/orc/orc-${VERSION_ORC}.tar.xz \
	| tar xJC ${ORC_BUILD_DIR} --strip-components=1

WORKDIR  ${ORC_BUILD_DIR}/
RUN set -xe; \
    ./configure \
	--prefix=${INSTALL_DIR} \
	--enable-shared \
    --disable-static \
    --disable-dependency-tracking \
 && make install-strip


###############################################################################
# libgsf
#
ENV VERSION_LIBGSF=1.14.45
ENV LIBGSF_BUILD_DIR=${BUILD_DIR}/libgsf
RUN set -xe; \
	mkdir -p ${LIBGSF_BUILD_DIR}; \
	curl -Ls https://download.gnome.org/sources/libgsf/$(echo $VERSION_LIBGSF| sed 's/\.[[:digit:]]\+$//')/libgsf-${VERSION_LIBGSF}.tar.xz\
	| tar xJC ${LIBGSF_BUILD_DIR} --strip-components=1


WORKDIR  ${LIBGSF_BUILD_DIR}/
RUN set -xe; \
    ./configure \
	--prefix=${INSTALL_DIR} \
	--enable-shared \
    --disable-static \
    --disable-dependency-tracking \
 && make install-strip

###############################################################################
# libvips
ENV VERSION_LIBVIPS=8.7.0
ENV LIBVIPS_BUILD_DIR=${BUILD_DIR}/libvips

RUN set -xe; \
    mkdir -p ${LIBVIPS_BUILD_DIR}; \
	curl -Ls https://github.com/libvips/libvips/releases/download/v${VERSION_LIBVIPS}/vips-${VERSION_LIBVIPS}.tar.gz \
  | tar xzC ${LIBVIPS_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBVIPS_BUILD_DIR}/

RUN set -xe; \
	./configure \
    --prefix=${INSTALL_DIR} \
 && make install-strip


###############################################################################
# libvips-phpext
ENV VERSION_EXT_LIBVIPS=1.0.7
ENV LIBVIPS_EXT_BUILD_DIR=${BUILD_DIR}/libvips-ext

RUN set -xe; \
    mkdir -p ${LIBVIPS_EXT_BUILD_DIR}; \
	curl -Ls https://github.com/libvips/php-vips-ext/releases/download/v${VERSION_EXT_LIBVIPS}/vips-${VERSION_EXT_LIBVIPS}.tgz\
  | tar xzC ${LIBVIPS_EXT_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBVIPS_EXT_BUILD_DIR}/

RUN set -xe; \
    phpize \
 && ./configure \
    --prefix=${INSTALL_DIR} \
 && make \
 && cp ${LIBVIPS_EXT_BUILD_DIR}/modules/vips.so ${INSTALL_DIR}/modules/vips.so


###############################################################################
# parallel
ENV VERSION_EXT_PARALLEL=1.1.3
ENV PARALLEL_EXT_BUILD_DIR=${BUILD_DIR}/parallel-ext

RUN set -xe; \
    mkdir -p ${PARALLEL_EXT_BUILD_DIR}; \
	curl -Ls https://github.com/krakjoe/parallel/archive/v${VERSION_EXT_PARALLEL}.tar.gz \
  | tar xzC ${PARALLEL_EXT_BUILD_DIR} --strip-components=1

WORKDIR  ${PARALLEL_EXT_BUILD_DIR}/

RUN set -xe; \
    phpize \
 && ./configure --enable-parallel \
    --prefix=${INSTALL_DIR} \
 && make \
 && cp ${PARALLEL_EXT_BUILD_DIR}/modules/parallel.so ${INSTALL_DIR}/modules/parallel.so

#strip all the unneeded symbols from shared libraries to reduce size.
RUN find ${INSTALL_DIR} -type f -name "*.so*" -o -name "*.a"  -exec strip --strip-unneeded {} \;
RUN find ${INSTALL_DIR} -type f -executable -exec sh -c "file -i '{}' | grep -q 'x-executable; charset=binary'" \; -print|xargs strip --strip-all

# Cleanup all the binaries we don't want.
RUN find ${INSTALL_DIR}/bin -mindepth 1 -maxdepth 1 ! -name "convert" ! -name "gs" ! -name "identify" ! -name "vips" ! -name "vipsthumbnail" -exec rm {} \+

# Cleanup all the files we don't want either
RUN rm -rf ${INSTALL_DIR}/share/doc \
 && rm -rf ${INSTALL_DIR}/share/man \
 && rm -rf ${INSTALL_DIR}/share/gtk-doc \
 && rm -rf ${INSTALL_DIR}/include \
 && rm -rf ${INSTALL_DIR}/tests \
 && rm -rf ${INSTALL_DIR}/doc \
 && rm -rf ${INSTALL_DIR}/docs \
 && rm -rf ${INSTALL_DIR}/man \
 && rm -rf ${INSTALL_DIR}/www \
 && rm -rf ${INSTALL_DIR}/cfg \
 && rm -rf ${INSTALL_DIR}/libexec \
 && rm -rf ${INSTALL_DIR}/var \
 && rm -rf ${INSTALL_DIR}/data

# Symlink all our binaries into /opt/bin so that Lambda sees them in the path.
RUN mkdir -p /opt/bin
RUN ln -s ${INSTALL_DIR}/bin/* /opt/bin

# Zip the layer
WORKDIR /opt
RUN zip --quiet --recurse-paths /tmp/sts-php-73.zip . --exclude "bref*"
