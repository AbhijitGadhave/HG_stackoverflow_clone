FROM elixir:1.17-alpine AS build

RUN apk add --no-cache build-base git

WORKDIR /app

RUN mix do local.hex --force, local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only dev
RUN MIX_ENV=dev mix deps.compile

COPY lib lib
COPY priv priv

RUN MIX_ENV=dev mix compile

FROM elixir:1.17-alpine

RUN apk add --no-cache postgresql-client

WORKDIR /app
ENV MIX_ENV=dev

COPY --from=build /app /app

COPY --from=build /root/.mix /root/.mix

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4000
CMD ["/entrypoint.sh"]
