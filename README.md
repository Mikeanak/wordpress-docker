# WordPress Docker Static/Dynamic Content Project

This project enables web designers and developers to quickly package, seed, and serve static or dynamic HTML/CSS/JS content as a WordPress-backed website using Docker. With a few simple commands, you can:

- Develop and preview your custom landing pages, styles, and scripts in the `content/` directory.
- Seamlessly seed or restore a MySQL database for WordPress.
- Launch a fully functional WordPress+phpMyAdmin stack anywhere Docker is available.

> **Note:** The provided `docker compose` setup (`local_setup.yaml`) is intended for local testing and development only. **For production, you should only use the built WordPress container and connect it to your production database (e.g., AWS RDS). Do not use the local MySQL or phpMyAdmin containers in production.**

## Typical Designer Journey

1. **Clone the repository and open the `content/` directory.**
2. **Edit or add your HTML, CSS, and JS files.** For example, update `landing-page.html`, `style.css`, or add new scripts.
3. **Preview your changes locally:**
    - Run `make test` to build, seed, and launch the full stack with your content.
    - Visit `http://localhost:8080` to see your landing page, styled and interactive, powered by WordPress.
    - Visit `http://localhost:8081` to access phpMyAdmin (credentials in `master_key.txt`).
4. **Iterate:**
    - Update your content and rerun `make test` as needed.
    - NOTE: `make cleanup` command must be run between the tests!
5. **Deploy anywhere:**
    - Use the generated `local_setup.yaml` and your images to run the stack on any Docker host.

## Makefile Commands

- `make build` — Build the WordPress container with your content.
- `make db` — Build the MySQL container.
- `make test` — **Recommended:** Build both containers, generate credentials, create config files, and launch the full demo stack. Visit `http://localhost:8080` after running.
- `make cleanup` — Stop and remove all containers and the database volume. Use this before a fresh test or to reset your environment.
- `make help` — List all available make targets.

> **Tip:** The `make test` command is the fastest way to see your content live with a fresh WordPress install and seeded landing page.

## Running the Stack Manually

If you want to start the stack manually after building, use:

```
docker compose -f local_setup.yaml up -d
```

## Production Usage & RDS Example

For production, run only the WordPress container and connect it to your managed database (e.g., AWS RDS). You need to provide an `env.yaml` file with your RDS connection details and mount it to `/config/env.yaml` in the container.

Example `env.yaml` for RDS:

```yaml
db_host: your-rds-endpoint.amazonaws.com
db_port: 3306
db_name: your_db_name
db_user: your_db_user
db_password: your_db_password
site_url: https://your-production-domain.com
```

Run the container in production:

```
docker run -d -p 80:80 \
  -v /path/to/your/env.yaml:/config/env.yaml:ro \
  your-wordpress-image:latest
```

## Accessing phpMyAdmin (Local Only)

- After running `make test`, phpMyAdmin is available at [http://localhost:8081](http://localhost:8081).
- The phpMyAdmin username is shown in `master_key.txt` (usually `phpmyadmin`).
- The phpMyAdmin password is also in `master_key.txt` (generated at build time).
- Example:
  - `phpmyadmin_user: phpmyadmin`
  - `phpmyadmin_password: <your-random-password>`

## Startup Time Note

> **Note:** It may take up to 1 minute (or longer for large content) before WordPress connects to the database and is ready to serve. You can watch the WordPress container logs for the line:
>
> `Apache/2.4.66 (Debian) PHP/8.2.25 configured -- resuming normal operations`
>
> This indicates the site is ready to use.

## Dependencies

- **Docker daemon** (with BuildKit/buildx support)
- **make** command available
- **docker-compose** (v1 or v2 plugin)
- (Optional) Run `install_buildx.sh` if you need to set up Docker Buildx on your system

## JavaScript Support Example

The landing page template in `content/landing-page.html` includes a button and a simple JS script to demonstrate out-of-the-box JavaScript support:

```html
<button id="js-demo-btn">Click me</button>
<script>
document.getElementById('js-demo-btn').onclick = function() {
  alert('Yay, JS works!');
};
</script>
```

You can add or modify any JS/CSS/HTML in the `content/` directory and it will be included in your WordPress-backed site.

---

Happy designing and deploying!
