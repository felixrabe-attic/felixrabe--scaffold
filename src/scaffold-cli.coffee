#!/usr/bin/env coffee

fs = require 'fs'
{exec} = require 'child_process'

mkdirp = require 'mkdirp'

{templates} = require './scaffold'

p =
  name: process.argv[2]
  description: process.argv[3]

p =
  name: p.name
  description: p.description
  year: '2013'
  author: 'Felix Rabe'
  npmName: "mcrio-#{p.name}"
  homepage: "http://mcr.io/#{p.name}"
  github: "git://github.com/mcrio/#{p.name}.git"

templates = templates p

console.log "Project name: '#{p.name}'"
console.log "Description:  '#{p.description}'"
mkdirp.sync p.name
process.chdir p.name
console.log "Directory:    '#{process.cwd()}'"
mkdirp.sync 'src'
mkdirp.sync 'test'

fs.writeFileSync 'Cakefile',                 templates.cakefile()
fs.writeFileSync '.gitignore',               templates.gitignore()
fs.writeFileSync 'LICENSE',                  templates.license()
fs.writeFileSync '.npmignore',               templates.npmignore()
fs.writeFileSync 'package.json',             templates.package()
fs.writeFileSync 'README.md',                templates.readme()
fs.writeFileSync 'test/test-helper.coffee',  templates.testhelper()
fs.writeFileSync "test/#{p.name}.coffee",    templates.srcTest()
fs.writeFileSync "src/#{p.name}.coffee",     templates.srcLib()
fs.writeFileSync "src/#{p.name}-cli.coffee", templates.srcCli()

exec 'npm install', (err, output) ->
  throw err if err
  console.log output

  exec 'npm test', (err, output) ->
    # throw err if err
    console.log err
    console.log output

    console.log 'You got a failed test - have fun! ;-)'
