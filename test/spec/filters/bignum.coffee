'use strict'

describe 'Filter: bignum', ->

  # load the filter's module
  beforeEach module 'swarmApp'

  # initialize a new instance of the filter before each test
  bignum = {}
  longnum = {}
  options = {}
  toLocaleString = Number.prototype.toLocaleString
  beforeEach inject ($filter, _options_) ->
    bignum = $filter 'bignum'
    longnum = $filter 'longnum'
    options = _options_
    # hack to make phantomJS work
    # https://stackoverflow.com/questions/2901102/how-to-print-a-number-with-commas-as-thousands-separators-in-javascript
    Number.prototype.toLocaleString = ->
      return this.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

  afterEach ->
    Number.prototype.toLocaleString = toLocaleString

  it 'should format numbers', ->
    expect(bignum 1).toBe '1'
    expect(bignum 10).toBe '10'
    expect(bignum 100).toBe '100'
    # toLocaleString works in browsers, but not node :(
    expect(bignum 1000).toBe '1,000'
    expect(bignum 10000).toBe '10,000'
    expect(bignum 11111).toBe '11,111'
    expect(bignum 100000).toBe '100K'
    expect(bignum 111111).toBe '111K'
    expect(bignum 1e6).toBe '1.00M'
    expect(bignum 1111111).toBe '1.11M'
    expect(bignum 1100000).toBe '1.10M'
    expect(bignum 1e7).toBe '10.0M'
    expect(bignum 11111111).toBe '11.1M'
    expect(bignum 1e8).toBe '100M'
    expect(bignum 111111111).toBe '111M'
    expect(bignum 1e9).toBe '1.00B'
    expect(bignum 1111111111).toBe '1.11B'
    expect(bignum 1e10).toBe '10.0B'
    expect(bignum 11111111111).toBe '11.1B'
    expect(bignum 1e11).toBe '100B'
    expect(bignum 111111111111).toBe '111B'
    expect(bignum 1e12).toBe '1.00T'
    expect(bignum 1111111111111).toBe '1.11T'
    expect(bignum 1e13).toBe '10.0T'
    expect(bignum 11111111111111).toBe '11.1T'
    expect(bignum 1e14).toBe '100T'
    expect(bignum 111111111111111).toBe '111T'
    expect(bignum 1e15).toBe '1.00Qa'
    expect(bignum 1111111111111111).toBe '1.11Qa'
    expect(bignum 1e16).toBe '10.0Qa'
    expect(bignum 11111111111111111).toBe '11.1Qa'
    expect(bignum 1e17).toBe '100Qa'
    expect(bignum 111111111111111111).toBe '111Qa'
    expect(bignum 1e18).toBe '1.00Qi'
    expect(bignum 1111111111111111111).toBe '1.11Qi'
    expect(bignum 1e19).toBe '10.0Qi'
    expect(bignum 11111111111111111111).toBe '11.1Qi'
    expect(bignum 1e20).toBe '100Qi'
    expect(bignum 111111111111111111111).toBe '111Qi'
    expect(bignum 1e21).toBe '1.00Sx'
    expect(bignum 1111111111111111111111).toBe '1.11Sx'
    expect(bignum 1e22).toBe '10.0Sx'
    expect(bignum 11111111111111111111111).toBe '11.1Sx'
    expect(bignum 1e23).toBe '100Sx'
    expect(bignum 111111111111111111111111).toBe '111Sx'
    expect(bignum 1e24).toBe '1.00Sp'
    expect(bignum 1111111111111111111111111).toBe '1.11Sp'
    expect(bignum 1e25).toBe '10.0Sp'
    expect(bignum 11111111111111111111111111).toBe '11.1Sp'
    expect(bignum 1e26).toBe '100Sp'
    expect(bignum 111111111111111111111111111).toBe '111Sp'
    expect(bignum 1e27).toBe '1.00Oc'
    expect(bignum 1111111111111111111111111111).toBe '1.11Oc'
    expect(bignum 1e28).toBe '10.0Oc'
    expect(bignum 11111111111111111111111111111).toBe '11.1Oc'
    expect(bignum 1e29).toBe '100Oc'
    expect(bignum 111111111111111111111111111111).toBe '111Oc'
    expect(bignum 1e30).toBe '1.00No'
    expect(bignum 1111111111111111111111111111111).toBe '1.11No'
    expect(bignum 1e31).toBe '10.0No'
    expect(bignum 11111111111111111111111111111111).toBe '11.1No'
    expect(bignum 1e32).toBe '100No'
    expect(bignum 111111111111111111111111111111111).toBe '111No'
    expect(bignum 1e33).toBe '1.00Dc'
    expect(bignum 1111111111111111111111111111111111).toBe '1.11Dc'
    expect(bignum 1e34).toBe '10.0Dc'
    expect(bignum 11111111111111111111111111111111111).toBe '11.1Dc'
    expect(bignum 1e35).toBe '100Dc'
    expect(bignum 111111111111111111111111111111111111).toBe '111Dc'
    expect(bignum 1e36).toBe '1.00UDc'
    expect(bignum 1111111111111111111111111111111111111).toBe '1.11UDc'
    expect(bignum 1e37).toBe '10.0UDc'
    expect(bignum 11111111111111111111111111111111111111).toBe '11.1UDc'
    expect(bignum 1e38).toBe '100UDc'
    expect(bignum 111111111111111111111111111111111111111).toBe '111UDc'
    # it'd be nice to remove these trailing zeros.
    # tried it: no it's not, the number length changes and is distracting
    # large numbers no longer change to scientific-e
    #expect(bignum 1e36).toBe '1.00e36'
    #expect(bignum 110e34).toBe '1.10e36'
    #expect(bignum 1111111111111111111111111111111111111).toBe '1.11e36'
    #expect(bignum 1e37).toBe '1.00e37'
    #expect(bignum 11111111111111111111111111111111111111).toBe '1.11e37'
    
  it 'should use other number formats', ->
    expect(options.notation()).toBe 'standard-decimal'
    expect(bignum 123456789).toBe '123M'
    expect(longnum 123456789).toBe '123.456 million'
    expect(bignum 123456789e30).toBe '123UDc'
    expect(longnum 123456789e30).toBe '123.456 undecillion'
    options.notation 'scientific-e'
    expect(bignum 123456789).toBe '1.23e8'
    expect(longnum 123456789).toBe '1.23456e8'
    expect(bignum 123456789e30).toBe '1.23e38'
    expect(longnum 123456789e30).toBe '1.23456e38'
    options.notation 'hybrid'
    expect(bignum 123456789).toBe '123M'
    expect(longnum 123456789).toBe '123.456 million'
    expect(bignum 123456789e30).toBe '1.23e38'
    expect(longnum 123456789e30).toBe '1.23456e38'
    options.notation 'engineering'
    expect(bignum 123456789).toBe '123E6'
    expect(bignum 12345678).toBe '12.3E6'
    expect(bignum 1234567).toBe '1.23E6'
    expect(bignum 100000000).toBe '100E6'
    expect(bignum 10000000).toBe '10.0E6'
    expect(bignum 1000000).toBe '1.00E6'
    expect(longnum 123456789).toBe '123.456E6'
    expect(longnum 12345678).toBe '12.3456E6'
    expect(longnum 1234567).toBe '1.23456E6'
    expect(bignum 123456789e30).toBe '123E36'
    expect(longnum 123456789e30).toBe '123.456E36'

  it 'should support Bignumbers', ->
    expect(bignum new Decimal('2.3e+500') ).toBe '2.30e500'
    expect(bignum new Decimal('2.3e+1234') ).toBe '2.30e1234'
    expect(bignum new Decimal('1e+100000') ).toBe '1.00e100000'
    options.notation 'engineering'
    expect(bignum new Decimal('2.3e+500') ).toBe '230E498'
    expect(bignum new Decimal('2.3e+1234') ).toBe '23.0E1233'
    expect(bignum new Decimal('1e+100000') ).toBe '10.0E99999'


  it 'rounds down, preventing things like "1.00e+3M", bug #245', ->
    expect(bignum 1000000000).toBe '1.00B'
    expect(bignum 1000000000-1).toBe '999M'
