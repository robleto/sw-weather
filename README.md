# Star Wars Weather

Weather data presented in a highly graphic interface shown in relation to various planets from the Star Wars saga.

![Star Wars weather](https://cdn.dribbble.com/userupload/16210951/file/original-d45b3cc6d42962dbb33d5e2667d71ca6.png?resize=1504x1178)

StarWarsWeather is a Next.js app that maps real-world weather conditions to Star Wars planets.

## Local Development

1. Install dependencies:

```bash
npm install
```

1. Create `.env.local` in the project root:

```bash
OPENWEATHERMAP_API_KEY=your_openweather_api_key
```

1. Start the app:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Environment Variables

- `OPENWEATHERMAP_API_KEY` (required): server-only key used by:
  - `GET /api/weather`
  - `GET /api/geocode`

Important migration note:

- `NEXT_PUBLIC_OPENWEATHERMAP_API_KEY` is no longer used.
- If you previously set that variable, move its value to `OPENWEATHERMAP_API_KEY` and remove the public one.

## Scripts

- `npm run dev` — start development server
- `npm run lint` — run lint checks
- `npm run build` — create production build
- `npm run start` — run production build locally

## API Endpoints

- `GET /api/weather?lat={lat}&lon={lon}`
- `GET /api/weather?address={cityOrQuery}`
- `GET /api/geocode?q={locationQuery}`

`/api/geocode` returns up to 5 normalized candidates and supports the location disambiguation UI.

## Code and Tools

This site was created with: **React**, **Next.js**, **Tailwind**, **Typescript**, **OpenWeatherAPI**, **HTML**, and **CSS**.

Tools used to build this site: **Figma**, **Illustrator**, **Photoshop**, **VS Code**, **Github**, **Netlify**, and **ChatGPT**.

## Author

Greg Robleto - [@robleto](https://www.github.com/robleto)
