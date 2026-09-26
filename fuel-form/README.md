# Fuel & Form

A daily health tracker, built as an installable web app (PWA). It uses metric units, keeps all data on the device, and needs no account or server.

## Features

| Tab | What it does |
| --- | --- |
| **Today** | A "Daily Ledger" styled like a nutrition-facts panel, showing goal − food + exercise = calories left. It also has protein, carb and fat bars, meals logged by slot, an exercise log, a water tracker (250 ml glasses) and steps. A coach note suggests the next move, such as a high-protein food that fits your remaining calories. |
| **Prep** | A 7-day meal-prep plan built from 18 batch-cook recipes. The week is split into two batches, so food stays within safe fridge times. Portions scale to your calorie target. You can swap any recipe, log a prepped meal in one tap, and tick off a grocery list grouped by aisle. |
| **Progress** | Weigh-ins, a weight trend chart with a 7-day moving average and goal line, and a 14-day calorie chart against your goal. Also shows your logging streak, water-goal days, and your real pace estimated from logged food. |
| **Goal** | Profile (sex, age, height, weight, goal weight, activity level, pace). Shows BMR, maintenance, calorie target, macros, BMI, goal date, a "How to get there" roadmap and a milestone table. Also holds settings and backup/restore. |

Food search covers about 65 common foods. You can also add custom foods, which are saved for reuse. Exercise burn is estimated from 28 activities using MET values, or you can enter calories from a watch.

## The math

- **BMR**: Mifflin–St Jeor, `10·kg + 6.25·cm − 5·age + 5 (male) / −161 (female)`
- **Maintenance (TDEE)**: BMR × activity factor (1.2 / 1.375 / 1.55 / 1.725)
- **Target**: TDEE ± `pace × 7700 / 7`. Floors are 1,200 kcal (female) and 1,500 kcal (male), and the app warns when one is applied. Gain pace is capped at 0.5 kg/week.
- **Protein**: 2.0 g/kg when losing, 1.6 when maintaining and 1.8 when gaining. The reference weight is capped at BMI 27, so targets stay sensible at higher body weights.
- **Fat**: 27% of calories. **Carbs**: the remainder, with a minimum of 50 g.
- **Exercise**: `MET × 3.5 × kg / 200 × minutes`
- **Water**: 35 ml per kg.
- Targets recalculate from your latest weigh-in, so they adjust as your weight changes.

The app shows warnings when a goal BMI is below 18.5 or a loss pace is above 1% of body weight per week.

## Run it

It's a static site with no build step. Serve the folder over HTTP so the service worker and install prompt work:

```bash
cd fuel-form
npx http-server -c-1 .   # or: python3 -m http.server 8080
```

Open the URL on your phone and choose **Add to Home Screen** (iOS) or **Install app** (Android/Chrome). After the first visit it works offline.

On first launch the app shows a sample week so every screen has something in it. Tap **Start fresh** to clear it and enter your own details.

## Files

```
fuel-form/
├── index.html            # the whole app (HTML + CSS + JS, no dependencies)
├── manifest.webmanifest  # PWA metadata
├── sw.js                 # offline cache (network-first pages, cache-first assets)
└── icons/                # SVG + PNG app icons (192, 512, maskable)
```

Data is stored in `localStorage` under `fuelform.v1`. Use **Goal → Your data** to download, copy or restore a JSON backup.

> Estimates are a starting point, not medical advice.
