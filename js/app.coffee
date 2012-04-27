jQuery ->
  API_URL = 'http://api.cloudcrontab.com/'

  ########
  # Models
  ########
  class Task extends Backbone.Model

  class Tasks extends Backbone.Collection
    url: API_URL + 'tasks'
    model: Task


  #######
  # Views
  #######
  Backbone.View::close = ->
    @remove()
    @unbind()
    @undelegateEvents()

  class TaskView extends Backbone.View
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

  class TaskListView extends Backbone.View
    el: $ '.container#content'

    initialize: ->
      _.bindAll @
      @collection = new Tasks
      @collection.bind 'add', @appendItem
      @counter = 0
      @render()

    render: ->
      $(@el).append '<button>Add item</button>'
      $(@el).append '<ul></ul>'

    addItem: ->
      @counter++
      item = new Task
      item.set part2: "#{item.get 'part2'} #{@counter}"
      @collection.add item

    appendItem: (item) ->
      item_view = new TaskView model: item
      $('ul').append item_view.render().el

    events: 'click button': 'addItem'

  class LoginView extends Backbone.View
    render: ->
      template = Handlebars.compile($("#login").html())
      $(@el).html(template({title: 'Login', button: 'Login'}))
    events:
      'click button': 'login'
      'click a.register': 'register'
    login: ->
      email = $(@el).find('input#email').val()
      password = $(@el).find('input#password').val()
      that = @
      request = $.post API_URL + "user/api-token", { email: email, password: password }, (data) ->
        setLogin email, JSON.parse(data)['api-token']
        app.userBadge.render()
        app.navigate '', {trigger: true}
      request.error (err) ->
        alert 'Login failed'
    register: ->
      app.navigate 'register', {trigger: true}

  class RegisterView extends Backbone.View
    render: ->
      template = Handlebars.compile($("#login").html())
      $(@el).html(template({title: 'Register', button: 'Register', register: true}))
      $(@el).find('a.register').hide()
    events:
      'click button': 'register'
    register: ->
      name = $(@el).find('input#name').val()
      email = $(@el).find('input#email').val()
      password = $(@el).find('input#password').val()
      that = @
      request = $.post API_URL + "user", { name: name, email: email, password: password }, (data) ->
        console.log(data)
      request.error ->
        alert 'error!'

  class UserBadgeView extends Backbone.View
    el: $ 'ul.nav li.userbadge'
    initialize: ->
      @render()
    render: ->
      if isLoggedIn()
        $(@el).html getEmail
      else
        $(@el).html '<a href=\'#login\'>Login</a>'


  ########
  # Router
  ########
  class CloudCrontabRouter extends Backbone.Router
    currentView: undefined
    routes:
      "":     "tasks"
      "login":    "login"
      "register":    "register"

    initialize: ->
      console.log 'init'
      @appView = new AppView
    login: ->
      @appView.show new LoginView
    register: ->
      @appView.show new RegisterView
    tasks: ->
      if !isLoggedIn()
        return app.navigate 'login', {trigger: true}
      # @appView.show new TaskListView
      request = $.get API_URL + "tasks", (data) ->
        console.log data
      request.error (err) ->
        console.log err
    help3: ->
      alert 'help3'

  class AppView
    show: (view) ->
      if @currentView
        @currentView.close()
      @currentView = view
      @currentView.render()
      $(".container#content").html @currentView.el

  ########
  # Functions
  ########
  isLoggedIn = ->
    return !!localStorage.getItem 'api-key'
  setLogin = (email, token) ->
    localStorage.setItem 'email', email
    localStorage.setItem 'api-key', token
    setUpAjaxAuth()
  getToken = ->
    localStorage.getItem 'api-key'
  getEmail = ->
    localStorage.getItem 'email'

  setUpAjaxAuth = ->
    if !isLoggedIn
      return
    $.ajaxSetup 
      beforeSend: (xhr, settings) ->
        settings.url = settings.url + '?token=' + getToken()
        #dataobj = JSON.parse(xhr.data || '{}')
        #dataobj.token = getToken()
        #console.log JSON.stringify dataobj
        #xhr.data = JSON.stringify dataobj

  ########
  # Start
  ########
  setUpAjaxAuth()
  app = new CloudCrontabRouter
  app.userBadge = new UserBadgeView
  Backbone.history.start()