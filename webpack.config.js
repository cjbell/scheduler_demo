"use strict";

var path = require("path");
var CopyWebpackPlugin = require("copy-webpack-plugin");

function join(dest) { return path.resolve(__dirname, dest); }
function web(dest) { return join("web/static/" + dest); }

module.exports = {
  entry: [
    web("js/script.js")
  ],

  devtool: 'source-map',

  output: {
    path: join("priv/static/js"),
    filename: "bundle.js"
  },

  resolve: {
    modulesDirectories: [ "node_modules", __dirname + "/web/static/js" ],
    alias: {
      phoenix: __dirname + "/deps/phoenix/web/static/js/phoenix.js"
    }
  },

  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: "babel",
        query: {
          presets: ['es2015', 'react']
        }
      }
    ]
  },

  plugins: [
    new CopyWebpackPlugin([
      { from: "./web/static/assets" },
      { from: "./deps/phoenix_html/web/static/js/phoenix_html.js",
        to: "js/phoenix_html.js" }
    ])
  ]
}
