FROM ubuntu:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        python \
        python-dev \
        tar \
        curl \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py
RUN pip --no-cache-dir install \
        Jinja2
