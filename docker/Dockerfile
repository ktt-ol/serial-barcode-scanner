FROM debian:testing

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    build-essential \
    valac \
    libesmtp-dev \
    libgpgme11-dev \
    libncursesw5-dev \
    libncurses5-dev \
    libgmime-2.6-dev \
    libarchive-dev \
    libgstreamer1.0-dev \
    librsvg2-dev \
    libsqlite3-dev \
    libpango1.0-dev \
    libssl-dev \
    meson \
    dbus-x11 \
    fonts-lmodern \
    sqlite3 \
    libgtk2.0-dev \
    libsoup2.4-dev \
    libgee-0.8-dev \
    tmux \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    useradd shop && \
    mkdir /var/run/dbus

ENV SBC_DIR /mnt/serial-barcode-scanner
WORKDIR $SBC_DIR
ADD . .

RUN dpkg-buildpackage -b && apt install -y ./../shopsystem_*_*.deb
#COPY tmux-config /root/.tmux.conf
#COPY init.sh /root/
#ENTRYPOINT ["/root/init.sh"]
