FROM debian:bullseye

# Install basics
RUN apt update && apt install -y curl jq gnupg1 apt-transport-https dirmngr

# Install speedtest cli
RUN curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
RUN apt install speedtest

COPY ./speedtest.sh .
CMD ["./speedtest.sh"]
