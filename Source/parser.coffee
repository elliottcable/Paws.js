`require = require('./cov_require.js')(require)`
Paws = require './Paws.coffee'

class Paws.Execution

class SourceRange
  constructor: (@source, @begin, @end) ->

class Expression
  constructor: (@contents, @next) ->
  
  append: (expr) ->
    curr = this
    curr = curr.next while curr.next
    curr.next = expr

class Parser
  labelCharacters = /[^(){} \n]/ # Not currently supporting quote-delimited labels

  constructor: (@text) ->
    @i = 0

  with_range: (expr, begin, end) ->
    expr.source_range = new SourceRange(@text, begin, end || @i)
    if expr.contents? && !expr.contents.soure_range?
      expr.contents.source_range = expr.source_range
    expr

  character: (char) ->
    @text[@i] is char && ++@i

  whitespace: ->
    true while @character(' ') || @character('\n')
    true

  label: ->
    @whitespace()
    start = @i
    res = ''
    while @text[@i] && labelCharacters.test(@text[@i])
      res += @text[@i++]
    res && new Paws.Label(res)

  braces: (delim, constructor) ->
    start = @i
    if @whitespace() &&
        @character(delim[0]) &&
        (it = @expr()) &&
        @whitespace() &&
        @character(delim[1])
      new constructor(it)

  paren: -> @braces('()', (it) -> it)
  scope: -> @braces('{}', Paws.Execution)

  expr: ->
    start = @i
    substart = @i
    res = new Expression
    while sub = (@label() || @paren() || @scope())
      res.append(@with_range(new Expression(sub), substart))
      substart = @i
    @with_range(res, start)

  parse: ->
    @expr()

module.exports =
  parse: (text) ->
    parser = new Parser(text)
    parser.parse()
  
  Expression: Expression
  SourceRange: SourceRange

