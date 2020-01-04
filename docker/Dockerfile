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
    rygel-playbin \
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
    debhelper \
    dh-sysuser \
    libgmime-3.0-dev \
    udev \
    tmux \
    # neeed for apt install shopsystem
    systemd console-setup console-setup-linux dbconfig-common dbconfig-sqlite3 gstreamer1.0-alsa gstreamer1.0-plugins-base iso-codes kbd keyboard-configuration libasound2 libasound2-data libcdparanoia0 \
    libgstreamer-plugins-base1.0-0 libjs-bootstrap libjs-c3 libjs-d3 libjs-jquery libjs-jquery-datatables libjs-jquery-flot libjs-jquery-mousewheel liblocale-gettext-perl libogg0 libopus0 liborc-0.4-0 \
    libpam-systemd libpolkit-agent-1-0 libpolkit-gobject-1-0 libtheora0 libvisual-0.4-0 libvorbis0a libvorbisenc2 policykit-1 systemd-sysv sysuser-helper xkb-data \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    useradd shop && \
    mkdir /var/run/dbus

ENV SBC_DIR /mnt/serial-barcode-scanner
WORKDIR $SBC_DIR

COPY tmux-config /root/.tmux.conf
COPY init.sh /root/
COPY config.ini /root/

ENTRYPOINT ["/root/init.sh"]
