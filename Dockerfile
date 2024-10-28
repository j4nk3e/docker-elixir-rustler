FROM erlang:27-alpine

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.17.3" \
	LANG=C.UTF-8 \
	RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	PATH=/usr/local/cargo/bin:$PATH \
	RUST_VERSION=1.82.0

RUN set -eux \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="6116c14d5e61ec301240cebeacbf9e97125a4d45cd9071e65e0b958d5ebf3890" \
	&& buildDeps=' \
		ca-certificates \
		curl \
		make \
		gcc \
		musl-dev \
		pkgconfig \
		openssl-dev \
		openssl-libs-static \
		python3 \
		ansible \
		openssh \
		tar \
		git \
	' \
	&& apk add --no-cache $buildDeps \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/local/src/elixir \
	&& tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
	&& rm elixir-src.tar.gz \
	&& cd /usr/local/src/elixir \
	&& make install clean \
	&& find /usr/local/src/elixir/ -type f -not -regex "/usr/local/src/elixir/lib/[^\/]*/lib.*" -exec rm -rf {} + \
	&& find /usr/local/src/elixir/ -type d -depth -empty -delete \
	&& apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) rustArch='x86_64-unknown-linux-musl'; rustupSha256='1455d1df3825c5f24ba06d9dd1c7052908272a2cae9aa749ea49d67acbe22b47' ;; \
		aarch64) rustArch='aarch64-unknown-linux-musl'; rustupSha256='7087ada906cd27a00c8e0323401a46804a03a742bd07811da6dead016617cc64' ;; \
		*) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
	esac; \
	url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init"; \
	wget "$url"; \
	echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
	chmod +x rustup-init; \
	./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
	rm rustup-init; \
	chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
	rustup --version; \
	cargo --version; \
	rustc --version; \
	rustup component add rustfmt clippy; \
	rustup target add wasm32-unknown-unknown; \
	cargo install wasm-pack;

CMD ["iex"]
