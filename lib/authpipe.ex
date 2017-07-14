defmodule AuthPipe do
  @moduledoc """
  AuthPipe is a framework for multi-factor authentication where the
  stages are modeled as a pipeline of discreet authentication
  modules.
  """

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  require Logger

  defmacro __using__(_opts) do
    quote do
      require Logger
      import AuthPipe, only: [auth_stage: 1, auth_stage: 2]
      Module.register_attribute(__MODULE__, :auth_stages, accumulate: true)
      @before_compile AuthPipe
    end
  end

  defmacro __before_compile__(env) do
    # collect all the stages that have been defined and which exist
    stages = Module.get_attribute(env.module, :auth_stages, [])
    stages = Enum.reduce(stages, [], &AuthPipe.canonicalize_stage/2)

    # memoize the stages that are requred to be supported by the client
    required_stages = Enum.reduce(stages, [], &AuthPipe.filter_required/2)

    Logger.debug "Stages: #{inspect stages}, required: #{inspect required_stages}"

    quote do
      def sigil_l(string, _), do: string

      defp __authpipe_approve_initialization(%{"init" => %{"methods" => supported_mechanisms}} = client_data)
        when is_list(supported_mechanisms) do
        __authpipe_approve_initialization_with(supported_mechanisms, client_data)
      end

      defp __authpipe_approve_initialization(client_data) do
        __authpipe_approve_initialization_with([], client_data)
      end

      defp __authpipe_approve_initialization_with(client_supports, client_data) do
        Enum.all?(unquote(required_stages),
                  fn stage -> Enum.member?(client_supports, stage) end) &&
        Enum.all?(unquote(Macro.escape(stages)),
                  fn {_name, module, opts} -> module.approve_spec?(client_data, opts) end)
      end

      defp __authpipe_do_next_stage(_client_data, %{stages: []} = state) do
        {:authorized, state}
      end

      defp __authpipe_do_next_stage(%{"data" => auth_data} = client_data,
                                    %{stages: [{_stage_name, module, opts}|next_stages]} = state) do
        case module.process(auth_data, state, opts) do
          {:next, state} -> __authpipe_do_next_stage(client_data, %{state| stages: next_stages})
          resp -> authenticate(client_data, resp)
        end
      end

      def init_auth_session(client_data) do
        case __authpipe_approve_initialization(client_data) do
          true -> {:step, %{stages: unquote(Macro.escape(stages))}}
          false -> {:fail, "Missing required client support", %{}}
        end
      end

      def authenticate(client_data) do
        authenticate(client_data, init_auth_session(client_data))
      end

      def authenticate(client_data, {:authorized, state}) do
        Logger.debug "The user is authorized"
        Enum.each unquote(Macro.escape(stages)),
                  fn {_name, module, opts} -> module.authenticated(state, opts) end
        :authorized
      end

      def authenticate(client_data, {:fail, reason, _state}) do
        # TODO: should be an opportunity for Stages to react to failure
        Logger.warn ~l"Authorization has FAILED #{inspect reason}"
        {:fail, reason}
      end

      def authenticate(client_data, {:new_challenge, client_message, _state}) do
        Logger.debug ~l"A request for a new challenge has been received! #{inspect client_message}"
        :more
        ## TODO: must send this to the client via the adapter
      end

      def authenticate(client_data, {:step, state}) do
        __authpipe_do_next_stage(client_data, state)
      end

      def authenticate(client_data, unexpected_resp) do
        Logger.debug ~l"Authorization error due to unknown response type: #{inspect unexpected_resp}"
        {:fail, "Unexpected response from stage"}
      end
    end
  end

  defmacro auth_stage(stage, opts \\ []) do
    quote do
      @auth_stages {unquote(stage), unquote(opts)}
    end
  end

  def canonicalize_stage({stage, opts}, acc) do
    as_string = Atom.to_string(stage)

    # convert some_stage_name to SomeStageName
    reduce_fun = fn component, acc -> acc <> String.capitalize(component) end
    name = Enum.reduce(String.split(as_string, "_"), "", reduce_fun)

    # prepend the common AuthPipe.Stage prefix
    module = Module.concat([:"AuthPipe.Stage", name])

    # then check it is actually loaded ...
    if Code.ensure_loaded?(module) do
      # ... before finally adding it to the pipeline
      [{stage, module, Enum.into(opts, %{})}|acc]
    else
      Logger.warn "Requested stage #{module} not available!"
      acc
    end
  end

  def filter_required({stage, _module, %{required: true, implicit: false}}, acc), do: [Atom.to_string(stage)|acc]
  def filter_required(_, acc), do: acc
end
