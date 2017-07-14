defmodule Mix.Tasks.AuthPipe.GenEctoPasswordMigration do
  use Mix.Task

  @shortdoc "Creates the migration needed by the EctoPassword AuthPipe stage"

  @moduledoc """
  Creates the storage for the EctoPassword AuthPipe stage, where it keeps
  password and activation status information. Must provide the name of the repo as an argument
  """

  @doc false
  def run(args) do
    if Mix.Project.umbrella? do
      Mix.raise "mix authpipe.genectopasswordmigration can only be run inside an application directory"
    end

    {_opts, [repo], []} = OptionParser.parse(args)

    source = Application.app_dir :authpipe, "priv/migrations/ectopassword.exs"
    target = "priv/repo/migrations/#{timestamp()}_init_authpipe_ectopassword.exs"
    binding = [repo: repo]
    Mix.Generator.create_file(target, EEx.eval_file(source, binding))
    IO.puts "Don't forget to run `mix ectol.migrate!`"
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
