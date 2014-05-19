#!/usr/bin/env coffee

unless process.argv.length == 4
  console.error "Usage: mcrio-scaffold new-project 'A new project doing X'"
  process.exit 1

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
  year: '2014'
  author: 'Felix Rabe <felix@rabe.io>'
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
fs.chmodSync     "src/#{p.name}-cli.coffee", 0o755

console.log "Running 'npm install' ..."
exec 'npm install', (err, output) ->
  throw err if err
  console.log output

  exec 'npm test', (err, output) ->
    console.log output
    console.log err if err

    console.log "You've got a failing test to fix - have fun! ;-)"
