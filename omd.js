// Generated by CoffeeScript 1.3.3
(function() {
  var Omd, fs, fse, grunt, highlight, indent, path, pyg, stripFileExtension,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  fs = require('fs');

  fse = require('fs-extra');

  grunt = require("grunt");

  highlight = require('pygments').colorize;

  String.prototype.tolower = function() {
    return this.toLowerCase();
  };

  String.prototype.toupper = function() {
    return this.toUpperCase();
  };

  String.prototype.ltrim = function() {
    return this.replace(/^\s+/g, "");
  };

  String.prototype.repeat = function(count) {
    return Array(count).join(this);
  };

  indent = function(level, spacesPerLevel) {
    if (spacesPerLevel == null) {
      spacesPerLevel = 2;
    }
    return ' '.repeat(level * spacesPerLevel);
  };

  pyg = require("pygments");

  stripFileExtension = function(filename) {
    var fsplit;
    fsplit = filename.split('.');
    fsplit.pop();
    return fsplit.join('.');
  };

  Omd = (function() {

    function Omd() {
      this.regExpLinks = /(\[(.*?)\]\(((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$])\)|\b((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$]))/ig;
      this.srcName = null;
      this.dstName = null;
      this.baseIndent = Array(5).join(' ');
      this.outL = [];
      this.spacesPerlevel = 2;
      this.cssFile = '/stylesheets/omd.css';
      this.inACodeBlock = 0;
    }

    Omd.prototype.indentSpaces = function(level) {
      var s;
      if (level == null) {
        level = 1;
      }
      s = '';
      if (level > 0) {
        s = '                                                   '.substr(0, level * this.spacesPerlevel);
      }
      return s;
    };

    Omd.prototype.firstNonSpacePosition = function(str) {
      var strLeftTrimmed;
      strLeftTrimmed = str.replace(/^\s+/g, "");
      if (!strLeftTrimmed.length) {
        0;

      }
      return str.length - strLeftTrimmed.length;
    };

    Omd.prototype.parseHeadingStyle = function(heading, level, levelStyles) {
      /*
          If a heading/line begins with # followed by o or u (order/unorder), then
          use it to style THAT level. It must be the first such mark for THAT level.
      */

      var strLevel, _ref;
      strLevel = level + '';
      if (heading[0] === '#' && (_ref = heading[1], __indexOf.call('oOuU', _ref) >= 0)) {
        levelStyles[strLevel] = "" + heading[1] + "l";
        heading = heading.substr(2).ltrim();
        this.inACodeBlock = 0;
      } else if (heading.slice(0, 3) === '```') {
        this.inACodeBlock = level;
        heading = '';
        levelStyles[strLevel] = "pre";
        levelStyles[(level + 1) + ''] = "";
      } else {
        levelStyles[strLevel] = "ul";
        this.inACodeBlock = 0;
      }
      return {
        heading: heading,
        level: level,
        levelStyles: levelStyles
      };
    };

    Omd.prototype.parseLines = function(srcLinesArray) {
      var currLevel, emitLevelStyleTag, heading, headingInfo, i, level, levelStyles, line, outL;
      currLevel = -1;
      levelStyles = {};
      outL = [];
      for (i in srcLinesArray) {
        line = srcLinesArray[i];
        heading = line.replace(/^\s+/g, "");
        emitLevelStyleTag = true;
        if (!heading.length) {
          continue;
        }
        level = ((line.length - heading.length) / this.spacesPerlevel) + 1;
        if (this.inACodeBlock && level > this.inACodeBlock) {
          outL.push(this.indentSpaces() + this.indentSpaces(currLevel + currLevel - 2) + '| ' + line.substr(this.inACodeBlock * this.spacesPerlevel));
          continue;
        } else if (this.inACodeBlock && level <= this.inACodeBlock) {
          this.inACodeBlock = 0;
          emitLevelStyleTag = false;
          currLevel = level - 2;
        }
        if (level !== currLevel) {
          if (level === 1 || currLevel === -1) {
            level = 1;
            headingInfo = this.parseHeadingStyle(heading, level, levelStyles);
            heading = headingInfo.heading;
            level = headingInfo.level;
            levelStyles = headingInfo.levelStyles;
            if (!this.inACodeBlock) {
              if (emitLevelStyleTag) {
                outL.push("" + levelStyles['1']);
              }
              outL.push(this.indentSpaces() + 'li');
              outL.push(this.indentSpaces(2) + '| ' + heading);
            } else {
              outL.push(("" + levelStyles['1'] + " ") + heading);
            }
            currLevel = 1;
          } else if (level > currLevel) {
            level = currLevel = currLevel + 1;
            headingInfo = this.parseHeadingStyle(heading, level, levelStyles);
            heading = headingInfo.heading;
            level = headingInfo.level;
            levelStyles = headingInfo.levelStyles;
            if (!this.inACodeBlock) {
              if (emitLevelStyleTag) {
                outL.push(this.indentSpaces(currLevel + currLevel - 2) + ("" + levelStyles[level]));
              }
              outL.push(this.indentSpaces(currLevel + currLevel - 1) + 'li');
              outL.push(this.indentSpaces(currLevel + currLevel) + '| ' + heading);
            } else {
              if (emitLevelStyleTag) {
                outL.push(this.indentSpaces(currLevel + currLevel - 2) + ("" + levelStyles[level] + " ") + heading);
              }
            }
          } else {
            currLevel = level;
            outL.push(this.indentSpaces(currLevel + currLevel - 1) + 'li');
            outL.push(this.indentSpaces(currLevel + currLevel) + '| ' + heading);
          }
        } else {
          outL.push(this.indentSpaces(currLevel + currLevel - 1) + 'li');
          outL.push(this.indentSpaces(currLevel + currLevel) + '| ' + heading);
        }
      }
      return outL;
    };

    Omd.prototype.prependLines = function(outL) {
      var jadeStr, line, _i, _len;
      jadeStr = "!!! 5\nhtml\n  head\n    meta(charset=\"utf-8\")\n    link(rel='stylesheet', media='screen', href='" + this.cssFile + "')\n  body(lang='en')\n    a(href=\"/\") Home | \n    a(href=\"/docs\") Docs\n";
      for (_i = 0, _len = outL.length; _i < _len; _i++) {
        line = outL[_i];
        jadeStr += this.baseIndent + line + "\n";
      }
      return jadeStr;
    };

    Omd.prototype.buildJade = function(outL) {
      fse.mkdirSync(this.dstPath);
      return fs.writeFileSync(this.dstName, this.prependLines(outL), 'utf8');
    };

    Omd.prototype.parseMarkdown = function(outL) {
      var i, line, linkTitle, linkUrl, match, spaces;
      i = 0;
      while (i < outL.length) {
        line = outL[i];
        match = this.regExpLinks.exec(line);
        if (match) {
          if (match[2]) {
            linkTitle = match[2];
            linkUrl = match[3];
          } else {
            linkTitle = match[1];
            linkUrl = match[1];
          }
          spaces = this.baseIndent + Array(this.firstNonSpacePosition(line) + 1).join(' ');
          line = line.replace(this.regExpLinks, "\n" + spaces + "a(href=\"" + linkUrl + "\") " + linkTitle + "\n" + spaces + "| ");
          outL[i] = line;
        }
        i++;
      }
      return outL;
    };

    Omd.prototype.parse = function(srcName, dstPath, callback) {
      var data, filename, srcLinesArray;
      this.srcName = srcName;
      this.dstPath = dstPath;
      filename = this.srcName.split(path.sep).pop();
      this.dstName = path.join(this.dstPath, filename.substr(0, filename.length - 4) + '.jade');
      data = fs.readFileSync(this.srcName, 'utf8');
      srcLinesArray = data.toString().split("\n");
      this.buildJade(this.parseMarkdown(this.parseLines(srcLinesArray)), function(err) {
        if (err) {
          return err;
        }
      });
      return callback();
    };

    Omd.prototype.buildIndex = function(basePath, srcPath, dstPath, callback) {
      var fPath, file, files, jadeFile, jadeStr, _i, _len;
      files = [];
      jadeStr = '';
      this.crawlForFiles(srcPath, function(callback) {
        return files = callback;
      });
      if (!files) {
        return null;
      }
      jadeStr = 'extends ../layout\n\nblock content\n  h1= title\n  a(href="/") Home\n  ul';
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        fPath = file.fPath;
        jadeStr += '    ';
        jadeStr += "\n    li\n      a(href=\"/" + basePath + "/" + fPath + "\") " + fPath;
      }
      jadeFile = path.join(dstPath, 'index.jade');
      fse.mkdirSync(dstPath);
      fs.writeFileSync(jadeFile, jadeStr, 'utf8');
      return callback;
    };

    Omd.prototype.crawlForFiles = function(srcPath, callback) {
      var files;
      this.srcPath = srcPath;
      files = [];
      grunt.file.recurse(this.srcPath, function(abspath, rootdir, subdir, fileName) {
        if (grunt.file.isMatch('*.omd', fileName)) {
          return files.push({
            subdir: subdir,
            fName: fileName,
            fPath: path.join(subdir, fileName.substr(0, fileName.length - 4)).replace(/\\/g, "/")
          });
        }
      });
      return callback(files);
    };

    return Omd;

  })();

  exports.Omd = Omd;

}).call(this);
