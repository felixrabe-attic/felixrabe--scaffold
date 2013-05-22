fs     = require 'fs'
{exec} = require 'child_process'

CoffeeScript = require 'coffee-script'
mkdirp       = require 'mkdirp'

_is = (x, t) -> Object::toString.call(x) == "[object #{t}]"
Array.isArray   ?= (x) -> _is x, 'Array'
Object.isObject ?= (x) -> _is x, 'Object'
String.isString ?= (x) -> _is x, 'String'

String::repeat ?= (count) ->
  # http://stackoverflow.com/a/5450113
  return '' if count < 1
  result = ''
  pattern = @valueOf()
  while count > 0
    result += pattern if count & 1
    count >>= 1
    pattern += pattern
  result

libdir = './lib'
srcdir = './src'


String::u ?= (c) ->
  c.repeat @length


## TEMPLATES


exports.templates = (project) ->
  license: ->
    """
    The MIT License (MIT)

    Copyright (c) #{project.year} #{project.author}

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

    """

  readme: ->
    """
    #{project.name}
    #{project.name.u '='}

    #{project.description}.


    Installation
    ------------

        $ npm install #{project.name}


    Example
    -------

        ...


    Develop
    -------

        $ npm test


    License
    -------

    #{@license(project)}
    """  # the final newline is already provided by the license template

  package: ->
    """
    {
      "name": "#{project.npmName}",
      "version": "0.0.1",
      "description": "#{project.description}",
      "license": "MIT",
      "private": true,

      "author": "#{project.author}",
      "homepage": "#{project.homepage}",
      "repository": {
        "type": "git",
        "url": "#{project.github}"
      },

      "main": "./lib/#{project.name}.js",
      "bin": "./lib/#{project.name}-cli.js",

      "dependencies": {
      },

      "devDependencies": {
        "chai": "*",
        "coffee-script": "*",
        "mcrio-scaffold": "*",
        "mocha": "*"
      },

      "scripts": {
        "prepublish": "cake build",
        "test": "cake test"
      }
    }

    """

  cakefile: ->
    """
    require 'mcrio-scaffold'

    """

  gitignore: ->
    """
    .DS_Store

    /lib
    /node_modules

    """

  npmignore: ->
    """
    .DS_Store
    .git*

    /Cakefile
    /src
    /test

    """

  testhelper: ->
    """
    global.assert = require('chai').assert
    global.should = require('chai').should()

    """

  srcTest: ->
    """
    {fn} = require '../src/#{project.name}.coffee'

    describe 'Dummy Function', ->
      it 'should double its input', ->
        fn( 2).should.equal  4
        fn(-3).should.equal -6

    describe 'Testing', ->

      it 'should drive the implementation', ->
        should.exist tests  # TODO: this is expected to fail

    """

  srcLib: ->
    """
    exports.fn = (x) -> x * 2

    """

  srcCli: ->
    """
    #!/usr/bin/env coffee

    {fn} = require './#{project.name}'

    console.log "5 doubled is \#{fn 5}"

    """



## METHODS


compile = (sourceFile, outFile) ->
  fs.stat sourceFile, (err, stat) ->
    makeExecutable = !!(stat.mode & 0o100)

    fs.readFile sourceFile, 'utf-8', (error, coffeeCode) ->
      throw error if error

      javaScript = CoffeeScript.compile(coffeeCode)
      javaScript = '#!/usr/bin/env node\n' + javaScript if makeExecutable

      # outFile = sourceFile.replace '.coffee', '.js'
      fs.writeFile outFile, javaScript, 'utf8', ->
        if makeExecutable
          fs.chmodSync outFile, 0o755

if 'task' of global
  global.task 'clean', 'remove compiled output', ->
    if fs.existsSync libdir
      fs.readdir libdir, (err, files) ->
        for file in files
          fs.unlinkSync "#{libdir}/#{file}"

  global.task 'build', 'compile CoffeeScript files', ->
    global.invoke 'clean'
    mkdirp.sync libdir
    fs.readdir srcdir, (err, files) ->
      for file in files
        src = "#{srcdir}/#{file}"
        lib = "#{libdir}/#{file.replace /\.coffee$/, ''}.js"
        compile src, lib

  # http://danneu.com/posts/14-setting-up-mocha-testing-with-coffeescript-node-js-and-a-cakefile/

  global.task 'test', 'run tests', ->
    exec "NODE_ENV=test
      ./node_modules/.bin/mocha
      --compilers coffee:coffee-script
      --reporter spec
      --require coffee-script
      --require test/test-helper.coffee
      --colors
    ", (err, output) ->
      throw err if err
      console.log output
