`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'

describe "Paws' utilities:", ->
   utilities = require "../Source/utilities.coffee"
   it 'should exist', ->
      expect(utilities).to.be.ok()
   
   describe 'chain()', ->
      composed = utilities.chain -> 'whee'
      it 'should always return the `this` value', ->
         object = new Object
         expect(composed.call object).to.be object
   
   describe 'modifier()', ->
      composed = utilities.modifier (foo) -> return 'yep' if foo == 'foo'
      it 'should return the return-value of the body ...', ->
         expect(composed 'foo').to.be 'yep'
      it '... unless the body returns nothing', ->
         object = new Object
         expect(composed object).to.be object
   
   
   describe 'constructify()', ->
      it 'basically works', ->
         expect(constructify).to.be.ok()
         expect(-> constructify ->).to.not.throwException()
         Ctor = constructify ->
         expect(-> new Ctor).to.not.throwException()
      
      it "causes constructors it's called on to always return instances", ->
         Ctor = constructify ->
         expect(new Ctor).to.be.a Ctor
         expect(Ctor()).to.be.a Ctor
   
   
   describe 'parameterizable()', ->
      utilities.parameterizable class Twat
         constructor: -> return this
      
      it 'should create a parameterizable constructor', ->
         constructor = new Twat.with(foo: 'bar')
         expect(constructor).to.be.a 'function'
         expect(constructor()).to.be.a Twat
         expect(constructor()._.foo).to.be 'bar'
      
      it 'should provide parameterizable methods', ->
         twat = new Twat
         expect(twat.with(foo: 'bar')).to.be twat
         expect(twat._.foo).to.be 'bar'
      
      it 'should not leave cruft around on the object', (complete) ->
         twat = new Twat.with({})()
         setTimeout => # *Intentionally* using setTimeout instead of nextTick
            expect(twat._).to.be undefined
            complete()
         , 0
   
   describe 'delegated()', ->
      class Delegatee
         shadowed: ->
         operate: (arg) -> return [this, arg]
      
      correct_shadowed = ->
      utilities.delegated('foo', Delegatee) class Something
         shadowed: correct_shadowed
         constructor: (@foo) ->
      
      it 'should delegate calls to missing methods, if possible', ->
         something = new Something(new Delegatee)
         expect(Something::operate).to.be.ok()
         expect(-> something.operate()).to.not.throwException()
         expect(something.operate 123).to.eql [something.foo, 123]
      
      it 'should not shadow re-implemented methods', ->
         expect(Something::shadowed).to.be correct_shadowed
   
   
   describe.skip 'runInNewContext()', ->
      run = utilities.runInNewContext
      it 'should not error out', ->
         expect(-> run 'true')    .to.not.throwException()
         expect(-> run 'Function').to.not.throwException()
      
      it 'should return values', ->
         expect(run '42').to.be 42
      it 'should return functions', ->
         expect(run 'Function').to.be.a 'function'
      
      it 'should expose the passed sandbox', ->
         sandbox = {foo: new Object}
         expect(run '(function(){ return foo })()', sandbox).to.be sandbox.foo
      
      it 'should mirror updates to values in the passed sandbox', ->
         sandbox = new Object
         run '(function(){ foo = 456 })()', sandbox
         expect(sandbox.foo).to.be 456
      
      
      it 'should use a new JavaScript execution-context', ->
         # FIXME: The following test currently fails on Testling, for reasons unknown.
         expect(run 'Object').to.not.be Object
         expect(run 'new Object').to.not.be.an Object
         
         expect(run 'Function').to.not.be Function
         expect(run 'new Object').to.not.be.an Object
      
      describe '(regressions)', ->
         it 'should expose expected globals to eval-bodies /re #4', ->
            $Function = run 'Function'
            $func = new $Function "return Object"
            expect(-> $func()).to.not.throwException()
            expect($func()).to.be.a 'function'
   
   if process.browser then describe.skip '#runInNewContext (client)', ->
      it 'should not leave trash in the DOM', ->
         iframes = window.document.getElementsByTagName 'iframe'
         expect(iframes).to.be.empty()
   
   
   subclassTests = (canHaveAccessors) -> ->
      sub = utilities.subclass
      beforeEach -> utilities.hasPrototypeAccessors(canHaveAccessors)
      
      it 'should return functions', ->
         expect(sub Function).to.be.a 'function'
         expect(sub Function).to.not.be Function
      
      it 'should return operable constructors', ->
         Fan = sub Function
         expect(new Fan).to.be.a Fan
      
      if (canHaveAccessors)
         it 'should instantiate descendants into the local context\'s inheritance-tree', ->
            Fan = sub Function
            expect(new Fan).to.be.an Object
            expect(new Fan).to.be.a  Function
      
      it 'should support a function-body for the constructor', ->
         Fan = sub Function, (stuff) -> this.stuff = stuff; this
         expect(new Fan('foo').stuff).to.be 'foo'
      
      it 'should support a function-body for the descendant', ->
         Fan = sub Function,
            ->
            (arg) -> arg + 'bar'
         
         fan = new Fan
         expect( fan('foo') ).to.be 'foobar'
      
      it 'should maintain the prototype-chain as expected', ->
         Fan = sub Function
         Fan.prototype.method = (foo) -> this.foo = foo
         
         fan = new Fan
         expect(-> fan.method 'bar').to.not.throwError()
         expect(fan.foo).to.be 'bar'
      
   describe.skip 'subclass() (via __proto__)', subclassTests true if utilities.hasPrototypeAccessors()
   describe.skip 'subclass() (via a foreign context)', subclassTests false
