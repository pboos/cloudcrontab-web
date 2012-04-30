jQuery ->
  API_URL = 'http://api.cloudcrontab.com/'

  ########
  # Models
  ########
  class Task extends Backbone.Model
    url: API_URL + 'task'

  class Tasks extends Backbone.Collection
    url: API_URL + 'tasks'
    model: Task
    parse: (response) ->
      response.tasks

  #######
  # Views
  #######
  Backbone.View::close = ->
    @remove()
    @unbind()
    @undelegateEvents()

  class TaskView extends Backbone.View
    tagName: 'tr'
    initialize: ->
      _.bindAll @
      @model.bind 'change', @render
      @model.bind 'remove', @unrender
    render: ->
      template = Handlebars.compile($("#task").html())
      data =
        name: @model.get 'name'
        url: @model.get 'url'
        crontab: @model.get 'schedule-crontab'
      $(@el).html(template(data))
      @
    events:
      'click .delete': 'remove'
    remove: -> @model.destroy()
    unrender: =>
      $(@el).remove()

  class TaskListView extends Backbone.View
    initialize: ->
      _.bindAll @
      @collection = new Tasks
      @collection.bind 'add', @render
      @collection.bind 'change', @render
      @collection.fetch
        success: @render

    render: ->
      template = Handlebars.compile($("#tasks").html())
      $(@el).html(template({}))
      @collection.forEach (item) ->
        itemView = new TaskView model: item
        $('tbody').append itemView.render().el
      @

    events: 'click a.create': 'createTask'

    createTask: ->
      app.navigate 'task/create', {trigger: true}

  class CreateTaskView extends Backbone.View
    render: ->
      template = Handlebars.compile($("#task-create").html())
      $(@el).html(template())
    events:
      'click button': 'create'
    create: ->
      name = $(@el).find('input#name').val()
      url = $(@el).find('input#url').val()
      crontab = $(@el).find('input#crontab').val()
      that = @
      request = $.post API_URL + "task", { name: name, url: url, 'schedule-crontab': crontab }, (data) ->
        app.navigate '', {trigger: true}
      request.error (data) ->
        alert JSON.parse(data.responseText).details.message

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
        if typeof data == 'string'
          data = JSON.parse data
        setLogin email, data['api-token']
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
        $(@el).addClass 'dropdown'
        $(@el).html '''
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">''' + getEmail() + ''' <b class="caret"></b></a>
              <ul class="dropdown-menu">
                <li><a href="#logout">Logout</a></li>
              </ul>
          '''
      else
        $(@el).removeClass 'dropdown'
        $(@el).html '<a href=\'#login\'>Login</a>'


  ########
  # Router
  ########
  class CloudCrontabRouter extends Backbone.Router
    currentView: undefined
    routes:
      "":            "tasks"
      "login":       "login"
      "logout":      "logout"
      "register":    "register"
      "task/create": "task_create"

    initialize: ->
      console.log 'init'
      @appView = new AppView
    login: ->
      @appView.show new LoginView
    logout: ->
      logout()
      app.userBadge.render()
      app.navigate 'login', {trigger: true}
    register: ->
      @appView.show new RegisterView
    tasks: ->
      if !isLoggedIn()
        return app.navigate 'login', {trigger: true}
      @appView.show new TaskListView
    task_create: ->
      if !isLoggedIn()
        return app.navigate 'login', {trigger: true}
      @appView.show new CreateTaskView

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
  logout = ->
    localStorage.removeItem 'email'
    localStorage.removeItem 'api-key'
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