jQuery ->
  ########
  # Models
  ########
  class Item extends Backbone.Model
    defaults:
      part1: 'Hello'
      part2: 'Backbone'

  class List extends Backbone.Collection
    model: Item


  #######
  # Views
  #######

  class ItemView extends Backbone.View
    tagName: 'li'
    initialize: ->
      _.bindAll @
      @model.bind 'change', @render
      @model.bind 'remove', @unrender
    render: ->
      $(@el).html """
        <span>#{@model.get 'part1'} #{@model.get 'part2'}!</span>
        <span class="swap">swap</span>
        <span class="delete">delete</span>
      """
      @
    events:
      'click .swap': 'swap'
      'click .delete': 'remove'
    remove: -> @model.destroy()
    swap: ->
      @model.set
        part1: @model.get 'part2'
        part2: @model.get 'part1'
    unrender: =>
      $(@el).remove()

  class ListView extends Backbone.View
    el: $ 'body'

    initialize: ->
      _.bindAll @
      @collection = new List
      @collection.bind 'add', @appendItem
      @counter = 0
      @render()

    render: ->
      $(@el).append '<button>Add item</button>'
      $(@el).append '<ul></ul>'

    addItem: ->
      @counter++
      item = new Item
      item.set part2: "#{item.get 'part2'} #{@counter}"
      @collection.add item

    appendItem: (item) ->
      item_view = new ItemView model: item
      $('ul').append item_view.render().el

    events: 'click button': 'addItem'

  list_view = new ListView

  ########
  # Router
  ########
  class CloudCrontabRouter extends Backbone.Router
    routes:
      "help":     "help"
      "help2":    "help2"
      "help3":    "help3"
    initialize: ->
      alert 'init'
    help: ->
      alert 'help'
    help2: ->
      alert 'help2'
    help3: ->
      alert 'help3'

  app = new CloudCrontabRouter();
  Backbone.history.start();