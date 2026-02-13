---
title: "ZorkBot"
summary: "An AIM chatbot that let you play Zork over instant message."
shipped: 2001-08-04
tags: [aim, chatbot, zork, fortran, perl]
theme: midnight
author:
  name: Dan Driscoll
  github: dandriscoll
  url: https://github.com/dandriscoll
---

## What is it?

ZorkBot was a chatbot on AOL Instant Messenger that let you play Zork by sending it IMs. It ran under the `zorkbot` AIM screen name with a Fortran backend and a Perl AIM adapter bridging the two. Game state was persisted locally on disk so you could pick up where you left off.

AIM's "warn" feature let users rate-limit a screen name into silence, so `zorkbotlet1` through `zorkbotlet9` were created to handle gameplay while `zorkbot` itself just assigned users to an available zorkbotlet. The whole thing ran on a server in a dorm room for a couple of years.
