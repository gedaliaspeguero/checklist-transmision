# Checklist Transmisión en Vivo

Página de una sola pantalla para que el equipo marque el equipo listo o lo que falta, desde el enlace de WhatsApp, sin crear cuenta.

- `index.html` – la página.
- `config.js` – URL y anon key (pública) de Supabase.
- `supabase/schema.sql` – tabla `checklist_marcas` y funciones `checklist_marcar` / `checklist_reiniciar`.

## Poner en marcha

1. En Supabase (proyecto NumbersPro) → SQL Editor, pega y corre `supabase/schema.sql`.
2. En `config.js`, pega la anon key (Project Settings → API Keys).
3. Sube la carpeta a Netlify (arrastrarla a app.netlify.com/drop, o conectar el repo).

## Uso

- Enlace para el equipo: `https://<tu-sitio>.netlify.app`
- Enlace tuyo con botón para reiniciar la lista: `https://<tu-sitio>.netlify.app/#admin`
- Para editar los equipos, cambia el arreglo `SECCIONES` en `index.html`.
