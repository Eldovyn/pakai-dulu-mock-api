# ---------------------------------------------------------------------------
# pakdul-mock-api — json-server based mock backend (db.json + static images)
#
# json-server is pinned to 0.17.4 on purpose: the 1.x line dropped the
# `--static` flag and the `/db` route this mock relies on.
# ---------------------------------------------------------------------------
FROM docker.io/library/node:20-alpine

# `--static ./public` serves /srv/public, so `images/product-1.png` in db.json
# is reachable as http://<host>:4000/images/product-1.png
RUN npm install --global --no-fund --no-audit json-server@0.17.4 \
    && npm cache clean --force

# Static assets live outside the data dir, so mounting the project at /data
# (needed for db.json write-back) does not shadow them.
COPY images /srv/public/images
COPY db.json /data/db.json

# Run from /srv: json-server resolves `--static` against the CWD, so a relative
# `./public` is the only portable form (an absolute path gets prefixed by it).
# The DB is passed as an absolute path instead, and /data is where compose mounts
# the host project so POST/PUT/DELETE are written back to the repo.
WORKDIR /srv

ENV NODE_ENV=production
EXPOSE 4000

# 0.0.0.0 is required, otherwise the API is only reachable from inside the container
CMD ["json-server", \
     "--host", "0.0.0.0", \
     "--port", "4000", \
     "--static", "./public", \
     "--watch", \
     "/data/db.json"]
