FROM alpine:3.20

RUN apk add --no-cache ca-certificates wget

COPY lims-server /usr/local/bin/lims-server

EXPOSE 8443

HEALTHCHECK --interval=10s --timeout=5s --retries=12 CMD wget -q -O - http://localhost:8443/ping >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/lims-server"]
