#!/usr/bin/env coffee

kue = require 'kue'
kue.app.set 'title', 'CoffeeDoc Queue'
console.log 'Kue web listening on port %d', 3000
kue.app.listen 3000
