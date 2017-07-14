defmodule AuthPipe.Stage.EctoPassword.Schema do
  use Ecto.Schema

  @primary_key false
  schema "authpipe_stage_ectopassword" do
    field :user, :string
    field :password, :string
    field :active, :boolean, default: false
  end
end

defmodule AuthPipe.Stage.EctoPassword do
  use AuthPipe.Stage

  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset

  @password_table_name "authpipe_stage_ectopassword"
  @default_pw_length 32

  def process(%{"user" => user, "password" => password}, auth_state, %{repo: repo}) do
    query = from auth in @password_table_name,
            where: auth.user == ^user,
            where: auth.active,
            select: auth.password

    case repo.one(query) do
      nil -> {:fail, :no_such_user}
      hashed_password -> password_matches?(Comeonin.Bcrypt.checkpw(password, hashed_password),
                                             auth_state)
    end
  end

  def process(%{"user" => _, "password" => _}, auth_state, _opts), do: {:fail, :no_repo, auth_state}
  def process(%{"user" => _}, auth_state, _opts), do: {:fail, :missing_password, auth_state}
  def process(%{"password" => _}, auth_state, _opts), do: {:fail, :missing_user, auth_state}
  def process(_client_data, auth_state, _opts), do: {:fail, :missing_user, auth_state}

  def setup_account(account_info, %{repo: repo}) do
    # TODO: password rules? e.g. min size, ...
    # TODO: in case of a new account and no password .. ?
    account_info = 
    case Map.get account_info, :password do
      nil -> account_info
      value -> Map.put account_info, :password, Comeonin.Bcrypt.hashpwsalt value
    end

    %AuthPipe.Stage.EctoPassword.Schema{}
    |> cast(account_info, [:user, :password, :active])
    |> repo.insert!(on_conflict: :replace_all, conflict_target: :user)
  end

  def lock_account(_account_info, _opts), do: :ok
  def remove_account(_account_info, _opts), do: :ok

  defp password_matches?(true, auth_state), do: {:next, auth_state}
  defp password_matches?(_, auth_state), do: {:fail, :password_incorrect, auth_state}
end
