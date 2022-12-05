'use strict'

angular.module('swarmApp').factory 'Effect', (util) -> class Effect
  constructor: (@game, @parent, data) ->
    _.extend this, data
    if data.unittype?
      @unit = util.assert @game.unit data.unittype
    if data.unittype2?
      @unit2 = util.assert @game.unit data.unittype2
    if data.upgradetype?
      @upgrade = util.assert @game.upgrade data.upgradetype
  parentUnit: ->
    # parent can be a unit or an upgrade
    if @parent.unittype? then @parent else @parent.unit
  parentUpgrade: ->
    if @parent.unittype? then null else @parent
  hasParentStat: (statname, _default) ->
    @parentUnit().hasStat statname, _default
  parentStat: (statname, _default) ->
    @parentUnit().stat statname, _default

  onBuy: (level) ->
    @type.onBuy? this, @game, @parent, level
  onBuyUnit: (twinnum) ->
    @type.onBuyUnit? this, @game, @parent, twinnum

  calcStats: (stats={}, schema={}, level=@parent.count()) ->
    @type.calcStats? this, stats, schema, level
    return stats

  bank: -> @type.bank? this, @game
  cap: -> @type.cap? this, @game
  output: (level) -> @type.output? this, @game, undefined, level
  outputNext: -> @output @parent.count().plus 1
  power: ->
    ret = @parentStat('power', 1)
    # include, for example, "power.swarmwarp"
    upname = @parentUpgrade()?.name
    if upname
      ret = ret.times @parentStat("power.#{upname}", 1)
    return ret

angular.module('swarmApp').factory 'EffectType', -> class EffectType
  constructor: (data) ->
    _.extend this, data

###*
 # @ngdoc service
 # @name swarmApp.effect
 # @description
 # # effect
 # Factory in the swarmApp.
###
angular.module('swarmApp').factory 'EffectTypes', -> class EffectTypes
  constructor: (effecttypes=[]) ->
    @list = []
    @byName = {}
    for effecttype in effecttypes
      @register effecttype

  register: (effecttype) ->
    @list.push effecttype
    @byName[effecttype.name] = effecttype
    return this

angular.module('swarmApp').factory 'romanize', ->
  # romanize() from http://blog.stevenlevithan.com/archives/javascript-roman-numeral-converter
  # MIT licensed, according to a comment from the author - safe to copy here
  # coffeelint: disable=no_backticks
  `
  var romanize = function(num) {
    if (!+num)
      return false;
    var digits = String(+num).split(""),
      key = ["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM",
             "","X","XX","XXX","XL","L","LX","LXX","LXXX","XC",
             "","I","II","III","IV","V","VI","VII","VIII","IX"],
      roman = "",
      i = 3;
    while (i--)
      roman = (key[+digits.pop() + (i * 10)] || "") + roman;
    return Array(+digits.join("") + 1).join("M") + roman;
  }
  `
  # coffeelint: enable=no_backticks
  return romanize

angular.module('swarmApp').factory 'effecttypes', (EffectType, EffectTypes, util, seedrand, $log, romanize) ->
  ONE = new Decimal(1)

  effecttypes = new EffectTypes()
  # Can't write functions in our spreadsheet :(
  # TODO: move this to upgrade parsing. this only asserts at runtime if a conflict happens, we want it to assert at loadtime
  validateSchema = (stat, schema, operation) ->
    schema[stat] ?= operation
    util.assert schema[stat] == operation, "conflicting stat operations. expected #{operation}, got #{schema[stat]}", stat, schema, operation
  effecttypes.register
    name: 'addUnit'
    onBuy: (effect, game) ->
      effect.unit._addCount @output effect, game
    onBuyUnit: (effect, game, boughtUnit, num) ->
      effect.unit._addCount @output effect, game, num
    output: (effect, game, num=1) ->
      effect.power().times(effect.val).times(num)
  effecttypes.register
    name: 'addUnitByVelocity'
    onBuy: (effect, game) ->
      effect.unit._addCount @output effect, game
    output: (effect, game) ->
      effect.unit.velocity().times(effect.val).times(effect.power())
  effecttypes.register
    name: 'addUnitTimed'
    onBuy: (effect, game, parent, level) ->
      thresholdMillis = effect.val2 * 1000
      if !effect.unit2? or effect.unit2.isVisible()
        if effect.unit.isAddUnitTimerReady thresholdMillis
          # TODO this should be @output
          effect.unit._addCount effect.val
          effect.unit.setAddUnitTimer()
  effecttypes.register
    name: 'addUnitRand'
    onBuy: (effect, game, parent, level) ->
      out = @output effect, game, parent, level
      if out.spawned
        if effect.unit.count().isZero()
          # first spawn. Show tutorial text, this session only. This is totally hacky.
          game.cache.firstSpawn[effect.unit.name] = game.now
        effect.unit._addCount out.qty
    output: (effect, game, parent=effect.parent, level=parent.count()) ->
      # minimum level needed to spawn units. Also, guarantees a spawn at exactly this level.
      minlevel = effect.parentStat "random.minlevel.#{parent.name}"
      if level.greaterThanOrEqualTo minlevel
        stat_each = effect.parentStat 'random.each', 1
        # chance of any unit spawning at all. base chance set in spreadsheet with statinit.
        prob = effect.parentStat 'random.freq'
        # quantity of units spawned, if any spawn at all.
        minqty = 0.9
        maxqty = 1.1
        qtyfactor = effect.val
        baseqty = stat_each.times Decimal.pow qtyfactor, level
        # consistent random seed. No savestate scumming.
        game.session.state.date.restarted ?= game.session.state.date.started
        seed = "[#{game.session.state.date.restarted.getTime()}, #{effect.parent.name}, #{level}]"
        rng = seedrand.rng seed
        # at exactly minlevel, a free spawn is guaranteed, no random roll
        # guarantee a spawn every 8 levels too, so people don't get long streaks of bad rolls
        # TODO: remove the 8-levels guaranteed spawns, inspect previous spawns to look for failing streaks and increase odds based on that.
        roll = rng()
        isspawned = level.equals(minlevel) or level.modulo(8).equals(0) or new Decimal(roll+'').lessThan(prob)
        #$log.debug 'roll to spawn: ', level, roll, prob, isspawned
        roll2 = rng()
        modqty = minqty + (roll2 * (maxqty - minqty))
        # toPrecision: decimal.js insists on this precision, and it'll parse the string output.
        # decimal.js would rather we use Decimal.random(), but we can't seed that.
        qty = baseqty.times(modqty+'').ceil()
        #$log.debug 'spawned. roll for quantity: ', {level:level, roll:roll2, modqty:modqty, baseqty:baseqty, qtyfactor:qtyfactor, qty:qty, stat_each:stat_each}
        return spawned:isspawned, baseqty:baseqty, qty:qty
      return spawned:false, baseqty:new Decimal(0), qty:new Decimal(0)
  effecttypes.register
    name: 'compoundUnit'
    bank: (effect, game) ->
      base = effect.unit.count()
      if effect.unit2?
        base = base.plus effect.unit2.count()
      return base
    cap: (effect, game) ->
      # empty, not zero
      if effect.val2 == '' or not effect.val2?
        return undefined
      velocity = effect.unit.velocity()
      if effect.unit2?
        velocity = velocity.plus effect.unit2.velocity()
      return velocity.times(effect.val2).times(effect.power())
    output: (effect, game) ->
      base = @bank effect, game
      ret = base.times(effect.val - 1)
      if (cap = @cap effect, game)?
        ret = Decimal.min ret, cap
      return ret
    onBuy: (effect, game) ->
      effect.unit._addCount @output effect, game
  effecttypes.register
    name: 'addUpgrade'
    onBuy: (effect, game) ->
      effect.upgrade._addCount @output effect, game
    output: (effect, game) ->
      effect.power().times(effect.val)
  effecttypes.register
    name: 'skipTime'
    onBuy: (effect) ->
      effect.game.skipTime @output(effect).toNumber(), 'seconds'
    output: (effect) ->
      effect.power().times(effect.val)

  effecttypes.register
    name: 'multStat'
    calcStats: (effect, stats, schema, level) ->
      validateSchema effect.stat, schema, 'mult'
      stats[effect.stat] = (stats[effect.stat] ? ONE).times(Decimal.pow effect.val, level)
  effecttypes.register
    name: 'expStat'
    calcStats: (effect, stats, schema, level) ->
      validateSchema effect.stat, schema, 'mult'
      stats[effect.stat] = (stats[effect.stat] ? ONE).times(Decimal.pow(level, effect.val).times(effect.val2).plus(1))
  effecttypes.register
    name: 'asympStat'
    calcStats: (effect, stats, schema, level) ->
      # val: asymptote max; val2: 1/x weight
      # asymptote min: 1, max: effect.val
      validateSchema effect.stat, schema, 'mult' # this isn't multstat, but it's commutative with it
      weight = level.times effect.val2
      util.assert not weight.isNegative(), 'negative asympStat weight'
      #stats[effect.stat] *= 1 + (effect.val-1) * (1 - 1 / (1 + weight))
      stats[effect.stat] = (stats[effect.stat] ? ONE).times ONE.plus (new Decimal(effect.val).minus(1)).times(ONE.minus(ONE.dividedBy(weight.plus 1)))
  effecttypes.register
    name: 'logStat'
    calcStats: (effect, stats, schema, level) ->
      # val: log multiplier; val2: log base
      # minimum value is 1.
      validateSchema effect.stat, schema, 'mult' # this isn't multstat, but it's commutative with it
      #stats[effect.stat] *= (effect.val3 ? 1) * (Math.log(effect.val2 + effect.val * level)/Math.log(effect.val2) - 1) + 1
      stats[effect.stat] = (stats[effect.stat] ? ONE).times(new Decimal(effect.val3 ? 1).times(Decimal.log(level.times(effect.val).plus(effect.val2)).dividedBy(Decimal.log(effect.val2)).minus(1)).plus(1))
  effecttypes.register
    name: 'addStat'
    calcStats: (effect, stats, schema, level) ->
      validateSchema effect.stat, schema, 'add'
      stats[effect.stat] = (stats[effect.stat] ? new Decimal 0).plus(new Decimal(effect.val).times level)
  # multStat by a constant, level independent
  effecttypes.register
    name: 'initStat'
    calcStats: (effect, stats, schema, level) ->
      validateSchema effect.stat, schema, 'mult'
      stats[effect.stat] = (stats[effect.stat] ? ONE).times(effect.val)
  effecttypes.register
    name: 'multStatPerAchievementPoint'
    calcStats: (effect, stats, schema, level) ->
      validateSchema effect.stat, schema, 'mult'
      points = effect.game.achievementPoints()
      stats[effect.stat] = (stats[effect.stat] ? ONE).times(Decimal.pow ONE.plus(new Decimal(effect.val).times(points)), level)
  effecttypes.register
    name: 'suffix'
    calcStats: (effect, stats, schema, level) ->
      # using calcstats for this is so hacky....
      if level.isZero()
        suffix = ''
      else if level.lessThan(3999)
        # should be safe to assume suffix levels are below 1e308
        suffix = romanize(level.plus(1).toNumber())
      if not suffix?
        # romanize lists a bunch of Ms past this point; just use regular numbers instead
        suffix = level.plus(1).toString()
      effect.unit.suffix = suffix
      stats.empower = (stats.empower ? new Decimal 0).plus(level)
  return effecttypes
