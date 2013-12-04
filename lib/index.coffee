glob = require 'glob'
async = require 'async'
archiver = require 'archiver'
extend = require 'lodash.assign'
fs = require 'fs'

module.exports = do ->
  options     = level: 9
  initialized = false
  type        = 'zip'
  zip         = undefined
  out         = undefined
  fileList    = []
  fileStack   = []
  initialize = ->
    zip = archiver type, options
    initialized = true

  return {
    getStream: ->
      return out

    setOptions: (opt) ->
      extend(options, opt)

    setType: (type='zip') ->
      type = type

    setOutput: (path) ->
      if out?
        out.end()
      out = fs.createWriteStream path

    add: (path, callback) ->
      if not initialized
        initialize()

      glob path, (err, files) ->
        callback err if err
        files.forEach (file, i) ->
          fs.stat file, (err, stats) ->
            if stats.isFile()
              do (file) ->
                fileList.push file
                fileStack.push (cb) ->
                  zip.append(fs.createReadStream(file), name: file, cb)

            if i is files.length-1
              callback()

    getFiles: ->
      return fileList

    compress: (callback) ->
      if not initialized
        initialize()

      zip.pipe out

      async.parallel fileStack, (err) ->
        zip.finalize callback
  }