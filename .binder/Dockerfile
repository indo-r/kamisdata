FROM rocker/binder:3.6.0
LABEL maintainer='Muhammad Aswan Syahputra'
USER root
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}
USER ${NB_USER}
RUN wget https://github.com/indo-r/kamisdata/raw/master/DESCRIPTION && R -e "options(repos = list(CRAN = 'http://mran.revolutionanalytics.com/snapshot/2019-09-21/')); devtools::install_deps()"
