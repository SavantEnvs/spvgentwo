# syntax=docker/dockerfile:1.7
# Commit-image Dockerfile for SpvGenTwo (SMALL form) — on top of the org C/C++ base.
FROM ghcr.io/mayhemheroes/base:20260621

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS
ARG COVERAGE_FLAGS=
ARG MAYHEM_JOBS=

# Pre-fetch the test suite's FetchContent dependencies at their pinned tags so
# mayhem/build.sh can configure fully offline (FETCHCONTENT_FULLY_DISCONNECTED).
USER root
RUN mkdir -p /opt/fetchcontent \
 && git clone -q --depth 1 --branch v3.4.0 https://github.com/catchorg/Catch2.git /opt/fetchcontent/catch2 \
 && git clone -q --depth 1 --branch sdk-1.3.261.1 https://github.com/KhronosGroup/SPIRV-Headers.git /opt/fetchcontent/spirv-headers \
 && git clone -q --depth 1 --branch sdk-1.3.261.1 https://github.com/KhronosGroup/SPIRV-Tools.git /opt/fetchcontent/spirv-tools \
 && chown -R 2000:2000 /opt/fetchcontent

USER mayhem
WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh

RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh — repo ships no functional tests"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
