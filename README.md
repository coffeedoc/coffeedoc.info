# CoffeeDoc.info

Welcome to the [Codo](https://github.com/netzpirat/codo) documentation server as a service.
You'll find me online at [http://www.coffeedoc.info](http://www.coffeedoc.info).

**This is a prototype and under heavy development. It's not even working right now, so please come back later!**

## Development

The app is hosted on [nodejitsu](http://nodejitsu.com/) and consists of two drones:

### The express website

This drone is located under the `site` directory and is a simple [Express](https://github.com/visionmedia/express)
app that serves existing documentation and enqueues new requests for adding projects to the job queue.

You can start the first drone locally with:

```
cd website
coffee app.coffee
```

and open it in your browser under [http://localhost:8080/](http://localhost:8080/)

### The kue jobs queue

This drone is located under the `queue` directory and starts the [Kue](https://github.com/LearnBoost/kue) web interface
for monitoring the jobs queue and waits for working the incoming jobs off.

You can start the second drone locally with:

```
cd kue
coffee app.coffee
```

and open it in your browser under [http://localhost:3000/](http://localhost:3000/)

## Author

* [Michael Kessler](https://github.com/netzpirat) ([@netzpirat](http://twitter.com/#!/netzpirat), [mksoft.ch](https://mksoft.ch))

## License

(The MIT License)

Copyright (c) 2012 Michael Kessler

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
