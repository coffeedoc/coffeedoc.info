# CoffeeDoc.info

Welcome to the [Codo](https://github.com/netzpirat/codo) Documentation Server as a service.
You'll find me online at [http://www.coffeedoc.info](http://www.coffeedoc.info).

## Development

The app is hosted on [nodejitsu](http://nodejitsu.com/) and consists of three drones:

### First drone: The coffeedoc.info website

This drone is located under the `coffeedoc` directory and is a simple [Express](https://github.com/visionmedia/express)
app that serves existing documentation and enqueues new requests for adding projects to the job queue.

You can start the first drone locally with:

```
cd coffeedoc
coffee app.coffee
```

and open it in your browser under [http://localhost:8080/](http://localhost:8080/)

### Second drone: The Kue webinterface

This drone is located under the `kue` directory and starts the [Kue](https://github.com/LearnBoost/kue) webinterface
for monitoring the jobs queue.

You can start the second drone locally with:

```
cd kue
coffee app.coffee
```

and open it in your browser under [http://localhost:3000/](http://localhost:3000/)

### Third drone: The job worker

This drone is located under the `worker` directory and processes the jobs that are placed onto the queue.

You can start the third drone locally with:

```
cd worker
coffee app.coffee
```

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
