FROM r-base@sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7

RUN rm -f /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian-unstable.sources \
    && echo 'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20261006T000000Z sid main' > /etc/apt/sources.list.d/debian-snapshot.list \
    && apt-get -o APT::Default-Release=sid -o Acquire::Check-Valid-Until=false update \
    && apt-get -o APT::Default-Release=sid install -y --no-install-recommends libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY renv.lock /tmp/renv.lock

RUN Rscript -e 'install.packages("https://cloud.r-project.org/src/contrib/curl_8.0.0.tar.gz", repos = NULL, type = "source")' \
    && Rscript -e 'install.packages("https://cloud.r-project.org/src/contrib/renv_1.3.1.tar.gz", repos = NULL, type = "source")'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = "stringi", library = .Library.site, prompt = FALSE, transactional = FALSE)'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = c("Rcpp", "data.table", "farver"), library = .Library.site, prompt = FALSE, transactional = FALSE)'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = c("timechange", "isoband"), library = .Library.site, prompt = FALSE, transactional = FALSE)'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = "vctrs", library = .Library.site, prompt = FALSE, transactional = FALSE)'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = c("insight", "rlang"), library = .Library.site, prompt = FALSE, transactional = FALSE)'

RUN Rscript -e 'renv::restore(lockfile = "/tmp/renv.lock", packages = c("futile.logger", "ggplot2", "plyr", "gridExtra", "scales", "reshape", "xtable", "ggthemes", "stringr", "data.table", "lubridate", "gplots", "gtools", "dplyr", "sjPlot"), library = .Library.site, prompt = FALSE, transactional = FALSE)'

ENV R_LIBS_USER=/usr/local/lib/R/site-library
WORKDIR /workspace
