FROM rust:latest

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && \
	apt-get install -y \
		gcc \
		grub2 \
		nasm \
		qemu-system \
		xorriso

RUN rustup default nightly
RUN rustup component add rust-src
RUN cargo install xargo

WORKDIR /build
COPY . /build

RUN make clean && \
	make iso
