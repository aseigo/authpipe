# AuthPipe

AuthPipe provides a composable authentication pipeline for use with web apps
as well as other client or server use cases. It does not mandate http for
transmission, only json for the data format.

AuthPipe takes a stateful approach to authentication, in that
authentication sessions may be started and then continued in an ongoing
conversation with the client. This allows use not only over HTTP and other
stateless protocols, but also over long-running connections such as websockets.

Finally, with its plugin-based approach to authentication, the details of
how exactly an account is setup, verified, locked, removed, etc. can be
placed where it belongs: next to the functions in the pipeline that use
those mechanisms.i

So, for instance, the SQL password checker requires the
name of a users table and the id column in it, but will itself manage a
separate table for passwords. This allows best practice to be encoded into
the pipeline stages themselves, but also grants flexibility so moving from
SQL to LDAP can be a simple matter of changing up your authentication pipeline.

AuthPipe is heavily inspired by Plug, and as such uses a similar syntax for defining
authentication pipelines. For example:

  defmodule AuthDef do
    use AuthPipe

    auth_stage :session_token, required: false
    auth_stage :password, implicit: true
    auth_stage :captcha
  end

The above module defines an authentication pipeline that includes checking
for session tokens, passwords, and captchas. By defalt all stages of a pipeline
are required, and the client is responsible for starting the authentication
session with an init data block that advertises what it is capable of supporting:

  {
    "data": {
      "user": "jane.doe",
        "password": "password"
    },
      "init": {
        "v": 1,
        "methods": [
           "captcha"
        ]
    }
  }

In the AuthDef exampleabove , session tokens are not required and password checking
is implied which means that the client does not need to advertise special support
for it. Required modules which are not implicit and which the client does not 
explictly say it supports will block authentication from proceeding.

Steps in the pipeline, or stages, are run one after the other in the order
they are declared in the authentication definition. So in the above example,
tokens will be checked first, then passwords, and finally a captcha challenge
will be generated.

Each stage is expected to be implemented as a module with the name AuthPipe.Stage.<name>
where the name is the snake case version of the atom (in the pipeline definition) or
string (in the client init block). For example this;

  auth_stage: :my_awesome_stage

would require a module named `AuthPipe.Stage.MyAwesomeStage` to exist and
be available in the application.

Stages may:

  * approve or reject client initialization with `approve_spec/2`
  * process authentication data with `process/3`
  * perform post-authentication routines in `authenticated/2`
  * perform account management tasks with:
    * `setup_account/2`
    * `lock_acocunt/2`
    * `remove_account/2`

Only `process/3` is required, the rest are optional.

The idea is to offer authentication, including features such as two/multi-factor auth,
as a "detail" item abstracted away and shareable by your applications. By having
the ability to define multiple pipelines and determine how and when they are used,
AuthPipe can be used to authenticate web applications using the framework of your
choice, but also over websockets or even raw-tcp connections.

One motivating factor in the design was to allow use cases like the following:

  Authenticate with an email client against a regular ol' IMAP server
  The IMAP server uses an AuthPipe application providing a SASL auth
  Block the authentication waiting for user interaction
  User performas a 2nd-factor auth with a mobile device that approves that IMAP auth
  On success, proceed to check usual SASL credentials

This opens the door for web services built / hosted by you to become SSO and/or
authentication gateway systems.

Also ... you can use it to auth people to your website driven by Plug. Of course!

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `authpipe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:authpipe, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/authpipe](https://hexdocs.pm/authpipe).

