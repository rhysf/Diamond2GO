FROM buchfink/diamond:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tzdata \
    perl \
    cpanminus \
    git \
    curl \
    unzip \
    make \
    build-essential \
    libxml-simple-perl \
    libwww-perl \
    liblwp-protocol-https-perl \
    liblist-allutils-perl \
    libscalar-util-numeric-perl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install BioPerl
RUN cpanm --notest Bio::Perl

# Set working directory
WORKDIR /opt/diamond2go

# Copy source code into container
COPY . /opt/diamond2go

# Default entrypoint
ENTRYPOINT ["perl", "Diamond2go.pl"]
