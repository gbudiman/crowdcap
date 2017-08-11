App.valmon_notifications = App.cable.subscriptions.create "ValmonNotificationsChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    # $('#messages').append data['message']
    valmon.update(data['message'])