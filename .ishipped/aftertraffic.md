---
title: "AfterTraffic"
summary: "How long you'd sit in traffic leaving now versus waiting a bit — a Seattle commute predictor for Windows Phone."
shipped: 2013-10-07
tags: [traffic, windows-phone, seattle, csharp, silverlight, live-tiles]
theme: midnight
icon: aftertraffic-icon.png
author:
  name: Dan Driscoll
  github: dandriscoll
  url: https://github.com/dandriscoll
---

## What is it?

Traffic apps tell you how bad it is right now. AfterTraffic answered a different question about a Seattle commute: how long will I sit in traffic if I leave now, and how much shorter is the drive if I wait? It queried WSDOT's travel-time service for one route across a run of departure times and charted the trip lengths together, so both answers sat side by side.

## Key Features

- **Leave now, or wait** — Trip length across the next three hours in ten-minute steps, or the whole day in half-hour steps, each drawn as a bar and labeled with how much slower it is than the best departure
- **52 Puget Sound routes** — Seattle, Bellevue, Redmond, Renton, Lynnwood, Issaquah, Federal Way and the rest, with I-90 and SR 520 counted separately
- **Named commutes** — Pick your morning route and the evening route fills in reversed; the app shows whichever direction matches the time of day
- **Self-updating live tiles** — Pin a commute and a background agent redraws the tile as a bar chart of the next 30 to 75 minutes, with "4 minutes faster in 45 minutes" on the back
- **Voice control** — "After Traffic, show work" opened that commute, with the phrase list rebuilt from your own commute names
