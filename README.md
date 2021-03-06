Two step authentication - an example rails app
==============================================

How would I set up a rails app to have a second step in the authentication process. 
That is, the user enters a password, and is then prompted to enter a second item 
(a shared secret for example).

Start with a tried and tested authentication gem
------------------------------------------------

I’ve used Devise a lot. It works well, and can be adapted for a wide range of scenarios. 
There are other authentication gems that also work well. I’ll use Devise here, but as 
I’m not going to modify the way Devise works, it should be fairly easy to use the 
same two step strategy with another authentication gem.

Step into the authentication process
------------------------------------

Typically, a developer enables authentication on a controller's actions by adding a 
`before_action` hook to the controller. For Devise this will look like:

```ruby
before_action :authenticate_user!
```

This is the obvious place to hook into the process. 

My first thought was to overwrite the `authenticate_user!` method, call `super` and 
then call the second step process. However, I think this is a better option:


```ruby
def authenticate_user_with_second_step!
  authenticate_user!
  authentication_second_step!
end
```

There are two reasons why I think this is a better alternative:

1.  It leaves the original `authenticate_user!` method unmodified and therefore available 
    if require (as it will be later!)
2.  It tells a developer that the `before_action` hook is like they’d normally expect, 
    but with something different going on. If we put the new method in the Application 
    Controller, the developer should be able to identify the modification and understand 
    what is going on.

So with the new method in place, the controller `before_action` changes to:

```ruby
before_action authenticate_user_with_second_step!
```

The second step
---------------

So what do we need the `authentication_second_step!` method to do?

1.  Ensure the user is identified – usually it will be called via 
    `authenticate_user_with_second_step!` but I would not rely on that, so I’d first 
    check the user in logged in.
2.  Check whether the user has already successfully been through the second step, and if 
    so let them proceed
3.  Redirect the user to a second step form if they haven’t successfully completed this 
    step

So the method could look like this:

```ruby
def authentication_second_step!
  authenticate_user! unless user_signed_in?
  return true if current_user.second_step_token == session[:second_step_token]
  redirect_to new_second_step_path
end
```

Note that a second step token is being used to identify the user. We could use the user’s 
`id` here, but then if the session is hacked, the hacker can guess the next user’s `id` 
which may add an attack vector to your app.

Set up the user
---------------

First we need to create an attribute to store the second step token.

```ruby
rails g migration add_second_step_token_to_users second_step_token
```

Then in the User model create a `before_save` callback that will populate that attribute:

```ruby
before_save :generate_second_step_token

private
def generate_second_step_token
  self.second_step_token = SecureRandom.uuid unless second_step_token?
end
```

The Second Steps controller
---------------------------

The last part of the process is to create an endpoint for `new_second_step_path`. I 
would start by creating a new controller:

```ruby
rails g controller second_steps new
```

Modify the route entry in `config/routes.rb` to:

```ruby
resources :second_steps, only: [:new, :create]
```

The steps controller will have two actions: `new` will render the form with the second 
step input field(s), and `create` will process that input.

However, the first thing to do in the controller is ensure the user is logged in 
(in case someone tries to enter the app at this point directly).

```ruby 
before_action :authenticate_user!
```

This is an example of why it is better not to overwrite the `authenticate_user!` method – 
so we can use it where we need to ensure the user has complete just the first step 
of the authentication.

The `new` action can be fairly simple – I’ve used it to clear the session key, and render 
the form:

```ruby
def new
  session[:second_step_token] = nil
end
```

It is the `create` action that will do all the work. In this example, the user is just 
asked to enter the text “Foo”:

```ruby
def create
  if params[:foo] == 'Foo'
    session[:second_step_token] = current_user.second_step_token
    redirect_to root_path, notice: 'Second authentication step completed'
  else
    flash[:alert] = "That wasn't 'Foo'"
    render :new
  end
end
```

And with that in place, we now have two step authentication.

This app
--------

The code here is a very simple rails app, to which the steps above have been applied.

Other things to consider
------------------------

Currently, the authentication process always returns the user to root. If you need
the user to be able to enter or return to your app at any point, we'd need to 
capture the original intended url, and then redirect to that on successful completion
of the `second_steps#create` step. Devise captures this information, so a method to
grab the url from Devise and perhaps temporarily store it, may be needed.