defmodule <%= repo %>.Migrations.EctoPassword do
  use Ecto.Migration

  def change do
    create table(:authpipe_stage_ectopassword, primary_key: false) do
      add :user, :text
      add :password, :text
      add :active, :boolean
    end
  end
end
