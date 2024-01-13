#
#  NOTE: this is the build file for the backend application. For the
#  agent application, see Dockerfile.agent. We use two files because
#  we do not want everything to land everywhere.
#
ARG ELIXIR_VERSION=1.14.4
ARG OTP_VERSION=25.3.1
ARG DEBIAN_VERSION=bullseye-20230227-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder
ARG SUBSYSTEM=backend # pass in agent to build the other thing.
ARG WEBAPP=lm_${SUBSYSTEM}_web
ARG TAG=localdev

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl

# Install NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

RUN apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
COPY apps apps
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN cd apps/${WEBAPP}; mix deps.get --only $MIX_ENV
RUN cd apps/${WEBAPP}; mix deps.compile

RUN npm ci --prefix apps/lm_web/assets
RUN npm ci --prefix apps/${WEBAPP}/assets

# compile assets
RUN cd apps/${WEBAPP}; mix assets.deploy

# Compile the release
RUN cd apps/${WEBAPP}; mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/*runtime.exs config/

RUN cd apps/${WEBAPP}; echo Revision: ${TAG} >priv/static/build.txt
RUN cd apps/${WEBAPP}; echo Build-Date: `date` >>priv/static/build.txt

RUN cd apps/${WEBAPP}; mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}
ARG SUBSYSTEM=backend # pass in agent to build the other thing.
ARG WEBAPP=lm_${SUBSYSTEM}_web

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/${WEBAPP} ./

USER nobody

CMD ["/app/bin/server"]

