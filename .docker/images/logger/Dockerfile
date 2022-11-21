ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as base

RUN apk add --update  \
    apk-cron \
    logrotate \
    tzdata \
    && rm -rf /etc/periodic/* \
    && rm -rf /etc/logrotate.d/* \
    && rm -rf /var/cache/apk/*

# Timezone
ARG TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

COPY ./images/logger/logrotate.d/* /etc/logrotate.d/

COPY ./images/logger/logrotate.conf /etc/logrotate.conf

ARG PATH_TO_LOG_DIR=/var/log/cron
ARG PATH_TO_CRON_OUTPUT_LOG=$PATH_TO_LOG_DIR/cron-output.log
# TODO: Use "0 0 * * *"
RUN echo "*  *  *  *  * $(which logrotate) /etc/logrotate.conf -v >> ${PATH_TO_CRON_OUTPUT_LOG} 2>&1" > /etc/crontabs/root

RUN chmod 644 -R /etc/crontabs/root \
    /etc/logrotate.conf \
    /etc/logrotate.d/ \
    && mkdir -p $PATH_TO_LOG_DIR

CMD [ "crond", "-l", "2", "-f", "-L", "/var/log/cron/cron.log" ]

FROM base as local
