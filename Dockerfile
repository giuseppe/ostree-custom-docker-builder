FROM openshift/origin-base
RUN yum install -y --enablerepo=centosplus gettext automake make docker yum-utils
RUN yum-config-manager --add-repo http://cbs.centos.org/kojifiles/repos/atomic7-el7.centos-build/latest/x86_64/
RUN yum install -y --nogpgcheck --enablerepo=* ostree
ENV HOME /root
ADD ./build.sh /tmp/build.sh
CMD ["/tmp/build.sh"]
