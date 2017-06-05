FROM ubuntu:16.04
MAINTAINER Guy Taylor <thebigguy.co.uk@gmail.com>

# Configure Apt
ARG DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//mirror:\/\/mirrors.ubuntu.com\/mirrors.txt/' /etc/apt/sources.list

# Build reqirments
ENV BUILD_PACKAGES "software-properties-common curl"
RUN apt-get update \
 && apt-get install --yes ${BUILD_PACKAGES}


# tini 0.14.0
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --verify /tini.asc
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


# gqrx
RUN add-apt-repository --yes ppa:ettusresearch/uhd \
 && add-apt-repository --yes ppa:myriadrf/drivers \
 && add-apt-repository --yes ppa:myriadrf/gnuradio \
 && add-apt-repository --yes ppa:gqrx/gqrx-sdr \
 && apt-get update 

RUN apt-get install --yes --no-install-recommends gqrx-sdr libhackrf0 \
 && apt-get install --yes --no-install-recommends rtl-sdr


RUN apt-get install --yes sudo gnuradio vim
RUN apt-get install --yes kmod initramfs-tools

# do these steps on your host not docker
# http://www.rtl-sdr.com/rtl-sdr-quick-start-guide/
# rtlsdr
# Kernel driver is active, or device is claimed by second instance of librtlsdr.
# In the first case, please either detach or blacklist the kernel module
# (dvb_usb_rtl28xxu), or enable automatic detaching at compile time.
# To unload them temporarily type “sudo rmmod dvb_usb_rtl28xxu” into terminal
#RUN echo "blacklist dvb_usb_rtl28xxu" >> /etc/modprobe.d/blacklist.conf
#RUN echo "blacklist e4000" >> /etc/modprobe.d/blacklist.conf
#RUN echo "blacklist rtl2832" >> /etc/modprobe.d/blacklist.conf
#RUN echo "blacklist dvb_usb_rtl28xxu" > /etc/modprobe.d/dvb_usb_rtl28xxu.conf
# RUN depmod -ae
#RUN update-initramfs -v -u


# clean up
RUN echo "${BUILD_PACKAGES}" | xargs apt-get purge --yes \
 && apt-get autoremove --purge --yes \
 && rm -rf /var/lib/apt/lists/*

# Set up PulseAudio
COPY pulse-client.conf /etc/pulse/client.conf
ENV PULSE_SERVER /run/user/1000/pulse/native

# Set up the user
ARG UNAME=gqrx
ARG UID=1000
ARG GID=1000
ARG HOME=/home/${UNAME}
RUN mkdir -p ${HOME} && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:${HOME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R ${HOME} && \
    gpasswd --add ${UNAME} audio && \
    gpasswd --add ${UNAME} video
USER ${UNAME}
ENV HOME=${HOME}

RUN cd ${HOME} && echo export QT_X11_NO_MITSHM=1>>.bashrc

RUN mkdir -p ${HOME}/.config/gqrx/
COPY default.conf ${HOME}/.config/gqrx/default.conf

# run
CMD ["/bin/bash"]
