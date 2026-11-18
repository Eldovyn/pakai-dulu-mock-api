# pakdul-mock-api

Mock backend for the Pakdul mobile app: a [json-server](https://github.com/typicode/json-server)
serving `db.json` as REST endpoints plus the PNGs in `images/` as static files.

## Endpoints

| Route           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `/products`     | Product list (`/products/:id` for one)               |
| `/categories`   | Category list                                        |
| `/payments`     | Payment list (`/payments?id_tx=...`)                 |
| `/filters`      | Filter list                                          |
| `/transactions` | Transaction list                                     |
| `/images/*.png` | Static images referenced by `image_url` in `db.json` |

Full-text search, sorting and pagination work out of the box, e.g.
`/products?name_like=tenda&_sort=price&_page=1&_limit=5`.

## Docker / Podman

Works with both **Docker Compose** and **Podman** (`podman compose`).

```bash
docker compose up --build      # or: podman compose up --build
```

| Host port | Why                                            |
| --------- | ---------------------------------------------- |
| `4000`    | Port baked into `db.json`'s absolute image URLs |
| `3000`    | Alias matching `EXPO_PUBLIC_API_URL` in the mobile app |

```bash
curl http://localhost:4000/products
curl -I http://localhost:4000/images/product-1.png
```

Change the published ports if they clash with something else:

```bash
MOCK_API_PORT=4001 MOCK_API_PORT_ALIAS=3001 docker compose up
```

`db.json` is bind-mounted from the host, so:

- **API writes persist** — `POST` / `PUT` / `DELETE` are written straight back to
  `db.json` in the repo. Use `git checkout db.json` to reset.
- **Host edits reload live** — edit `db.json` while the container runs and the
  server reloads automatically (`--watch`).

> The whole project directory is mounted at `/data` (rather than only
> `db.json`) because lowdb saves atomically via `rename`, which replaces a
> single-file bind mount inside the container and would silently discard every
> write. For the same reason the static assets are baked into the image at
> `/srv/public` so the mount cannot shadow them.

Start without Compose:

```bash
docker build -t pakdul-mock-api .
docker run --rm -p 4000:4000 -v "$PWD:/data:z" pakdul-mock-api
```

> **Podman notes**
>
> - The image name is fully qualified (`localhost/pakdul-mock-api`) and the base
>   image is `docker.io/library/node:20-alpine`, so no
>   `unqualified-search-registries` config is needed.
> - On SELinux hosts the bind mount uses `:z`; keep it if the container reports
>   `Permission denied`.
> - `podman-compose` 1.0.x needs the healthcheck in single-string `CMD-SHELL`
>   form; array forms get mangled.

## Without containers

The static root must contain an `images/` folder, so run it from this directory
and use `.` as the static root:

```bash
npx json-server@0.17.4 --host 0.0.0.0 --port 4000 --static . --watch db.json
```

## Notes

- json-server is pinned to **0.17.4** on purpose: the 1.x line dropped the
  `--static` flag and the `/db` route this mock relies on.
- Image URLs in `db.json` point at a fixed LAN IP (`http://10.240.32.166:4000`).
  Update them if the mock runs on a different host, otherwise the mobile app
  fetches images from the wrong machine.
