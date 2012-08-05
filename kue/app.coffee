#!/usr/bin/env coffee

kue = require 'kue'
kue.app.listen 3000
kue.app.set 'title', 'CoffeeDoc Queue'
