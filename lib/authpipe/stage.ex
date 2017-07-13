defmodule AuthPipe.Stage do
  @moduledoc "The behaviour for AuthPipe stages"

  # pre-authentication
  @callback approve_spec?(spec :: term, opts :: keyword) :: boolean

  # authentication
  @callback process(client_data :: map, auth_state :: map, opts :: keyword)
                    :: {:authorized, auth_state :: term} |
                       {:fail, reason :: atom, auth_state :: term} |
                       {:new_challenge, client_message :: term, auth_state :: term} |
                       {:next, auth_state :: term}

  # post-authentication
  @callback authenticated(auth_state :: map, opts :: keyword) :: any

  # account management
  @callback setup_account(account_info :: map, opts:: keyword) :: any
  @callback lock_account(account_info :: map, opts:: keyword) :: any
  @callback remove_account(account_info :: map, opts:: keyword) :: any

  defmacro __using__(_args) do
    quote do
      @behaviour AuthPipe.Stage

      def approve_spec?(_spec, _opts), do: true
      def authenticated(_auth_state, _opts), do: :ok
      def setup_account(account_info, _opts), do: account_info
      def lock_account(account_info, _opts), do: account_info
      def remove_account(account_info, _opts), do: account_info

      defoverridable [approve_spec?: 2,
                      authenticated: 2,
                      setup_account: 2,
                      lock_account: 2,
                      remove_account: 2]
    end
  end
end
