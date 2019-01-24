FROM java:8

RUN dpkg-reconfigure -f noninteractive tzdata

ENV HADOOP_VERSION 2.7.6
ENV HADOOP_URL https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_INSTALL_DIR /opt/hadoop

# Use aliyun source
RUN echo "deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib" > /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib" >>  /etc/apt/sources.list
RUN echo "deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib" >> /etc/apt/sources.list

RUN  apt-get update && \
     apt-get install -y --no-install-recommends git curl tar ssh dnsutils net-tools && \
     apt-get clean autoclean && \
     apt-get autoremove --yes && \
     rm -rf /var/lib/apt/lists/*

RUN  mkdir -p ${HADOOP_INSTALL_DIR} && \
     curl -sSL ${HADOOP_URL} | tar -xz --strip-components 1 -C ${HADOOP_INSTALL_DIR}

# build LZO
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y build-essential maven lzop liblzo2-2 && \
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.09.tar.gz && \
    tar zxvf lzo-2.09.tar.gz && \
    cd lzo-2.09 && \
    ./configure --enable-shared --prefix /usr/local/lzo-2.09 && \
    make && make install && \
    cd .. && git clone https://github.com/twitter/hadoop-lzo.git && cd hadoop-lzo && \
    git checkout release-0.4.20 && \
    C_INCLUDE_PATH=/usr/local/lzo-2.09/include LIBRARY_PATH=/usr/local/lzo-2.09/lib mvn clean package && \
    apt-get remove -y build-essential maven && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache.log}/ && \
    cd target/native/Linux-amd64-64 && \
    tar -cBf - -C lib . | tar -xBvf - -C /tmp && \
    cp /tmp/libgplcompression* ${HADOOP_INSTALL_DIR}/lib/native/ && \
    cd /tmp/hadoop-lzo && cp target/hadoop-lzo-0.4.20.jar ${HADOOP_INSTALL_DIR}/share/hadoop/common/ && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lzo-2.09/lib" >> ${HADOOP_INSTALL_DIR}/etc/hadoop/hadoop-env.sh && \
    rm -rf /tmp/lzo-2.09* hadoop-lzo lib libgplcompression*
