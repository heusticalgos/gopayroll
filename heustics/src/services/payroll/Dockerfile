FROM debian:stretch

RUN apt-get update && apt-get install -y ca-certificates net-tools && rm -rf /var/lib/apt/lists/*

COPY /entrypoint.sh /entrypoint.sh
COPY /payroll /payroll

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/payroll"]
