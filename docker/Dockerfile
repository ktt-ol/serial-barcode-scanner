FROM debian:jessie

RUN set -ex && \
  apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
    build-essential \
    valac \
    libesmtp-dev \
    libgpgme11-dev \
    libncursesw5-dev \
    libncurses5-dev \
    libgee-dev \
    libgmime-2.6-dev \
    libarchive-dev \
    libgstreamer1.0-dev \
    gstreamer1.0-alsa \
    rygel-playbin \
    librsvg2-dev \
    libsqlite3-dev \
    libpango1.0-dev \
    libssl-dev \
    dbus-x11 \
    fonts-lmodern \
    sqlite3 \
    libgtk2.0-dev \
    libsoup2.4-dev \
    libgee-0.8-dev \
    tmux \
    mdbus2 \
	&& rm -rf /var/lib/apt/lists/*

  RUN set -ex && \
    useradd shop && \
    mkdir /var/run/dbus

ENV SBC_DIR /mnt/serial-barcode-scanner

COPY tmux-config /root/.tmux.conf
COPY init.sh /root/

WORKDIR $SBC_DIR

ENTRYPOINT ["/root/init.sh"]
