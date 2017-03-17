# For this container to build, got to
#    * http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
# and download
#    * instantclient-sdk-linux.x64-XXX.zip
#    * instantclient-basic-linux.x64-XXX.zip
#
# Unzip both ZIPs, rename the resulting directory to "instantclient", then "tar":
#    > unzip instantclient-sdk-linux.x64-XXX.zip
#    > unzip instantclient-basic-linux.x64-XXX.zip
#    > mv instantclientXXX instantclient
#    > tar czvf instantclient.tgz instantclient
#
# Make sure the "instantclient.tgz" is located in the same directory where the
# Dockerfile is located.

FROM python:slim

# ENVs
# Specify the Superset version to pull via "pip":
ENV SUPERSET_VERSION=0.17.0

# Install the Oracle client
WORKDIR /oracle_client
COPY instantclient.tgz .
RUN tar xzvf instantclient.tgz

ENV ORACLE_HOME=/oracle_client/instantclient_12_1
WORKDIR $ORACLE_HOME
RUN ln -s libclntsh.so.12.1 libclntsh.so
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME

# Install dependencies and Superset:
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        libffi-dev \
        libffi6\
        libmariadbd-dev \
        libmariadb-client-lgpl-dev \
        libmysqlclient-dev \
        libsasl2-2 \
        libsasl2-dev \
        python3-dev \
        postgresql-server-dev-all
RUN pip3 install \
        superset==$SUPERSET_VERSION \
        cx_oracle \
        mysqlclient==1.3.7 \
        ldap3==2.1.1 \
        psycopg2==2.6.1 \
        redis==2.10.5 \
        sqlalchemy-redshift==0.5.0

# Default config
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=$PATH:/home/superset/.bin \
    PYTHONPATH=/home/superset/superset_config.py:$PYTHONPATH

# Run as superset user
RUN adduser -q --home /home/superset --disabled-password --gecos "" superset
WORKDIR /home/superset
COPY superset .
RUN chown -R superset:superset /home/superset
USER superset

# Deploy
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
ENTRYPOINT ["superset"]
CMD ["runserver"]
