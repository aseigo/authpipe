defmodule AuthPipe.Stage.TestSessionToken do
  use AuthPipe.Stage

  @token_value "12345"
  @token_key "session_token"

  def process(%{@token_key => @token_value}, auth_state, _opts), do: {:authorized, auth_state}
  def process(_, auth_state, _opts), do: {:next, auth_state}

  def authenticated(auth_state, _opts), do: Map.put(auth_state, @token_key, @token_value)

  def setup_account(account_info, _opts), do: account_info
  def lock_account(_account_info, _opts), do: :ok
  def remove_account(_account_info, _opts), do: :ok
end

defmodule AuthPipe.Stage.TestPassword do
  use AuthPipe.Stage
  
  @user "jane.doe"
  @pw   "password"

  require Logger
  def process(%{"user" => @user, "password" => @pw}, auth_state, _opts), do: {:next, auth_state}
  def process(%{"user" => @user}, auth_state, _opts), do: {:fail, :bad_password, auth_state}
  def process(_user_data, auth_state, _opts), do: {:fail, :unknown_user, auth_state}
end

defmodule AuthPipe.Stage.TestCaptcha do
  use AuthPipe.Stage

  def process(_client_data, auth_state, _opts), do: {:next, auth_state}
end


defmodule AuthDef do
  use AuthPipe
  auth_stage :test_session_token, required: false
  auth_stage :test_password, implicit: true
  auth_stage :test_captcha
end

defmodule AuthpipeTest do
  use ExUnit.Case
  doctest AuthPipe

  defp get_client_data(path) do
    {:ok, data} =
    File.read!(path)
    |> Poison.decode

    data
  end

  test "abort session when client does not support mandatory stages" do
    client_data = get_client_data("test/data/client_init_nocaptcha.json")
    {result, _reason, _state} = AuthDef.init_auth_session(client_data)
    assert result == :fail
  end

  test "allow session when client supports all mandatory stages" do
    client_data = get_client_data("test/data/client_init_password.json")
    {result, _state} = AuthDef.init_auth_session(client_data)
    assert result == :step
  end

  test "stepping through works" do
    client_data = get_client_data("test/data/client_init_password.json")
    {result_verb, _} = AuthDef.authenticate(client_data)
    assert :authorized == result_verb
  end

  test "fail on bad password" do
    client_data = get_client_data("test/data/client_bad_password.json")
    {result_verb, reason} = AuthDef.authenticate(client_data)
    assert :fail == result_verb
    assert :bad_password == reason
  end

  test "fail on bad user" do
    client_data = get_client_data("test/data/client_bad_user.json")
    {result_verb, reason} = AuthDef.authenticate(client_data)
    assert :fail == result_verb
    assert :unknown_user == reason
  end
end
