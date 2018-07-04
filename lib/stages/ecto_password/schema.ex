defmodule AuthPipe.Stage.EctoPassword.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "authpipe_stage_ectopassword" do
    field :user, :string, primary_key: true
    field :password, :string
    field :active, :boolean, default: false
  end
end
