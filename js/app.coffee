jQuery ->
  API_URL = 'http://api.cloudcrontab.com/'

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
    el: $ '.content'

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

  class LoginView extends Backbone.View
    el: $ '.content-login'
    initialize: ->
      $(@el).removeClass 'hide'
    events: 'click button': 'login'
    login: ->
      email = $(@el).find('input#email').val()
      password = $(@el).find('input#password').val()
      $.ajax({
        type: "POST",
        url: API_URL + "user/api-token",
        crossDomain: true,
        contentType: "application/json",
        data: JSON.stringify({ email: email, password: password }),
        context: @}
      ).done (data) ->
        alert(data)

  ########
  # Router
  ########
  class CloudCrontabRouter extends Backbone.Router
    routes:
      "":     "tasks"
      "login":    "login"
      "help3":    "help3"
    initialize: ->
      console.log 'init'
    login: ->
      new LoginView
    tasks: ->
      if !isLoggedIn()
        return app.navigate 'login', {trigger: true}

      $('content').show()
      list_view = new ListView
    help3: ->
      alert 'help3'

  ########
  # Functions
  ########
  isLoggedIn = ->
    return !!localStorage.getItem 'api-key'
  setLogin = (token) ->
    localStorage.setItem 'api-key', token
  getLogin = ->
    localStorage.getItem 'api-key'

  ########
  # Start
  ########
  app = new CloudCrontabRouter()
  Backbone.history.start()