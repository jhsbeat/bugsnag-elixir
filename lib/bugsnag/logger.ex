defmodule Bugsnag.Logger do
  require Bugsnag
  require Logger

  use GenEvent

  def init(_mod, []), do: {:ok, []}

  def handle_call({:configure, new_keys}, _state) do
    {:ok, :ok, new_keys}
  end

  def handle_event({_level, gl, _event}, state)
  when node(gl) != node() do
    IO.puts "handle_event node(gl) != node()"
    {:ok, state}
  end

  def handle_event({:error, gl, event}, state) do
    IO.puts "handle_event :error"
    handle_event({:error_report, gl, event}, state)
  end

  def handle_event({:error_report, _gl, {_pid, _type, [message | _]}}, state)
  when is_list(message) do
    IO.puts "handle_event :error_report"
    try do
      error_info = message[:error_info]

      case error_info do
        {_kind, {exception, stacktrace}, _stack} when is_list(stacktrace) ->
          Bugsnag.report(exception, stacktrace: stacktrace)
        {_kind, exception, stacktrace} ->
          Bugsnag.report(exception, stacktrace: stacktrace)
      end
    rescue
      ex ->
        error_type = Exception.normalize(:error, ex).__struct__
                      |> Atom.to_string
                      |> String.replace(~r{\AElixir\.}, "")

        reason = Exception.message(ex)

        Logger.warn "Unable to notify Bugsnag #{error_type}: #{reason}"
    end

    {:ok, state}
  end

  def handle_event({level, _gl, {_pid, _type, [message | _]}}, state) do
    IO.puts "handle_event else START"
    IO.puts "level: #{level}" 
    IO.inspect message
    IO.puts "handle_event else END"

    {:ok, state}
  end
end
