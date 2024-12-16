ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.2
ARG ALPINE_VERSION=3.20.3

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS build

# install build dependencies
RUN apk add --update git build-base nodejs yarn

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# build assets
COPY assets assets
RUN cd assets && yarn install && yarn run webpack --mode production
RUN mix phx.digest

# build project
COPY priv priv
COPY lib lib
RUN mix compile

# build release
COPY rel rel
RUN mix release

# prepare release image
FROM alpine:${ALPINE_VERSION} AS app
RUN apk add --no-cache --update bash openssl libstdc++

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/preview ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
