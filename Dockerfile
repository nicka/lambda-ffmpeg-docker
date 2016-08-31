FROM lambci/lambda:build

# Configure yum dependencies
RUN rm -rf /etc/yum.repos.d/amzn*
COPY *.repo /etc/yum.repos.d/
RUN rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6
RUN yum -y install freetype-devel nasm

# Setup build dir for libav
RUN mkdir ~/ffmpeg_sources
RUN mkdir $HOME/ffmpeg_build

# Yasm - a complete rewrite of the NASM assembler.
WORKDIR ~/ffmpeg_sources
RUN curl -L -O http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
RUN tar xzvf yasm-1.2.0.tar.gz
WORKDIR yasm-1.2.0
RUN autoreconf -fiv
RUN ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" \
&& make && make install && make distclean

# x264 - a free software library and application for encoding video streams into
# the H.264/MPEG-4 AVC compression format, and is released under the terms of
# the GNU GPL.
WORKDIR ~/ffmpeg_sources
RUN git clone --depth 1 git://git.videolan.org/x264
WORKDIR x264
RUN PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
./configure \
--prefix="$HOME/ffmpeg_build" \
--bindir="$HOME/bin" \
--disable-asm \
--enable-static \
&& make && make install && make distclean

# x265 - a H.265 / HEVC video encoder application library, designed to encode
# video or images into an H.265 / HEVC encoded bitstream.
WORKDIR ~/ffmpeg_sources
RUN git clone --depth 1 git://github.com/videolan/x265
WORKDIR x265/build/linux
RUN cmake -G "Unix Makefiles" \
-DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" \
-DENABLE_SHARED:bool=off ../../source \
&& make && make install

# fdk-aac - A standalone library of the Fraunhofer FDK AAC code from Android.
WORKDIR ~/ffmpeg_sources
RUN git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
WORKDIR fdk-aac
RUN autoreconf -fiv \
&& ./configure \
--prefix="$HOME/ffmpeg_build" \
--disable-shared \
&& make && make install && make distclean

# LAME - a high quality MPEG Audio Layer III (MP3) encoder licensed under the
# LGPL.
WORKDIR ~/ffmpeg_sources
RUN curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
RUN tar xzvf lame-3.99.5.tar.gz
WORKDIR lame-3.99.5
RUN ./configure \
--prefix="$HOME/ffmpeg_build" \
--bindir="$HOME/bin" \
--disable-shared \
--enable-nasm \
&& make && make install && make distclean

# Opus - a totally open, royalty-free, highly versatile audio codec.
WORKDIR ~/ffmpeg_sources
RUN git clone --depth 1 git://git.opus-codec.org/opus
WORKDIR opus
RUN autoreconf -fiv
RUN PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
./configure \
--prefix="$HOME/ffmpeg_build" \
--disable-shared \
&& make && make install && make distclean

# OGG - for video, audio, and applications there's video/ogg, audio/ogg and
# application/ogg respectively.
WORKDIR ~/ffmpeg_sources
RUN curl -L -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
RUN tar xzvf libogg-1.3.2.tar.gz
WORKDIR libogg-1.3.2
RUN ./configure \
--prefix="$HOME/ffmpeg_build" \
--disable-shared \
&& make && make install && make distclean

# libvorbis - reference implementation provides both a standard encoder and
# decoder under a BSD license.
WORKDIR ~/ffmpeg_sources
RUN curl -L -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
RUN tar xzvf libvorbis-1.3.4.tar.gz
WORKDIR libvorbis-1.3.4
RUN LDFLAGS="-L$HOME/ffmpeg_build/lib"
RUN CPPFLAGS="-I$HOME/ffmpeg_build/include"
RUN ./configure \
--prefix="$HOME/ffmpeg_build" \
--with-ogg="$HOME/ffmpeg_build" \
--disable-shared \
&& make && make install && make distclean

# WebM - an open, royalty-free, media file format designed for the web.
WORKDIR ~/ffmpeg_sources
RUN curl -L -O http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.6.0.tar.bz2
RUN tar xvfj libvpx-1.6.0.tar.bz2
WORKDIR libvpx-1.6.0
RUN PATH="$HOME/bin:$PATH" \
./configure \
--prefix="$HOME/ffmpeg_build" \
--disable-examples \
&& PATH="$HOME/bin:$PATH" make && make install && make clean

# Libav(Avconv) - a fork of FFMpeg
WORKDIR ~/ffmpeg_sources
RUN git clone -b release/3.1 git://git.ffmpeg.org/ffmpeg
WORKDIR ffmpeg
RUN PATH="$HOME/bin:$PATH" \
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
./configure \
--prefix="$HOME/ffmpeg_build" \
--extra-cflags="-I$HOME/ffmpeg_build/include" \
--extra-ldflags="-L$HOME/ffmpeg_build/lib" \
--bindir="$HOME/bin" \
--pkg-config-flags="--static" \
--enable-gpl \
--enable-nonfree \
--enable-libfreetype \
--enable-libmp3lame \
--enable-libopus \
--enable-libfdk-aac \
--enable-libvorbis \
--enable-libvpx \
--enable-libx264 \
# --enable-libx265 \
&& PATH="$HOME/bin:$PATH" make && make install && make distclean

# Make ffmpeg available
RUN cp $HOME/bin/ffmpeg /usr/bin/
RUN cp $HOME/bin/ffprobe /usr/bin/

# Test ffmpeg and ffprobe
COPY example.wav .
RUN ffprobe example.wav -v quiet -show_format -show_streams -of json
RUN ffmpeg -y -i example.wav -vn -codec:a libmp3lame -b:a 128k example.mp3
RUN ffmpeg -y -i example.wav -vn -strict -2 -codec:a libfdk_aac -b:a 96k example.m4a
RUN ffmpeg -y -i example.wav -vn -codec:a libvorbis example.ogg
RUN ffmpeg -y -i example.wav -filter_complex aformat=channel_layouts=mono,showwavespic=s=1200x400 -frames:v 1 example.png
RUN rm example.*

# Copy over binaries
COPY copy-binaries.sh .
RUN chmod +x copy-binaries.sh
RUN mkdir -p /ffmpeg/binaries
RUN ./copy-binaries.sh $(which ffmpeg) /ffmpeg/binaries
RUN ./copy-binaries.sh $(which ffprobe) /ffmpeg/binaries

# Test objects
WORKDIR /
COPY test-object.sh .
RUN chmod +x test-object.sh

ENTRYPOINT ["./test-object.sh"]
