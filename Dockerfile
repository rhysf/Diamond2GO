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

# Make entry scripts executable
# - wrapper: ./diamond2go  (bash)
# - core:    ./util/Diamond2go.pl (perl with #!/usr/bin/env perl at top)
RUN chmod +x /opt/diamond2go/diamond2go \
    && chmod +x /opt/diamond2go/util/Diamond2go.pl

# Put repo bin on PATH so "diamond2go" resolves
ENV PATH="/opt/diamond2go:${PATH}"

# Use the wrapper as entrypoint so help/usage shows "diamond2go"
ENTRYPOINT ["diamond2go"]
