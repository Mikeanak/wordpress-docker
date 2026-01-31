# WordPress Docker Static/Dynamic Content Project

This project enables web designers and developers to quickly package, seed, and serve static or dynamic HTML/CSS/JS content as a WordPress-backed website using Docker. With a few simple commands, you can:

- Develop and preview your custom landing pages, styles, and scripts in the `content/` directory.
- Seamlessly seed or restore a MySQL database for WordPress.
- Launch a fully functional WordPress+phpMyAdmin stack anywhere Docker is available.

## Typical Designer Journey

1. **Clone the repository and open the `content/` directory.**
2. **Edit or add your HTML, CSS, and JS files.** For example, update `landing-page.html`, `style.css`, or add new scripts.
3. **Preview your changes locally:**
    - Run `make test` to build, seed, and launch the full stack with your content.
    - Visit `http://localhost:8080` to see your landing page, styled and interactive, powered by WordPress.
4. **Iterate:**
    - Update your content and rerun `make test` as needed.
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

## Dependencies

- **Docker daemon** (with BuildKit/buildx support)
- **make** command available
- **docker-compose** (v1 or v2 plugin)
- (Optional) Run `install_buildx.sh` if you need to set up Docker Buildx on your system

## JavaScript Support Example

The landing page template in `content/landing-page.html` includes a button and a simple JS script to demonstrate out-of-the-box JavaScript support:

```html
<button id="demo-btn">Click me!</button>
<script>
document.getElementById('demo-btn').onclick = function() {
  alert('JS is working!');
};
</script>
```

You can add or modify any JS/CSS/HTML in the `content/` directory and it will be included in your WordPress-backed site.

---

Happy designing and deploying!
