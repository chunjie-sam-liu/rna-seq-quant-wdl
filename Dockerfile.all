
FROM mambaorg/micromamba:1.5.6
LABEL maintainer="Chun-Jie Liu <chunjie.sam.liu@gmail.com>"
# kallisto.salmon.cufflinks
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
  micromamba clean --all --yes
ARG MAMBA_DOCKERFILE_ACTIVATE=1

ENV PATH /opt/conda/bin/:$PATH