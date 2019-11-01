FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    ruby \
    barcode \
    texlive-latex-base texlive-font-utils ghostscript \
    && rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANGUAGE=C.UTF-8

WORKDIR /gen
