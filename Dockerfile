# Base our tests on the tools image
FROM docker.io/ethcomsec/cellift:cellift-tools-main
COPY . /cellift-designs/cellift-pulpissimo-hdac-2018
WORKDIR /cellift-designs/cellift-pulpissimo-hdac-2018/cellift
CMD bash tests.sh

