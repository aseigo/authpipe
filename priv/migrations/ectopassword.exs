defmodule <%= repo %>.Migrations.EctoPassword do
  use Ecto.Migration

  def change do
    create table(:authpipe_stage_ectopassword, primary_key: false) do
      add :user, :text, primary_key: true, null: false
      add :password, :text, null: false, default: ""
      add :active, :boolean, default: false
    end
  end
end
