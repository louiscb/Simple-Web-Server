defmodule Bench do
  def bench(host, port, number_requests) do
    start = Time.utc_now()
    mother = self()
    run(number_requests, host, port, mother)

    receive do
      :last_request ->
        finish = Time.utc_now()
        diff = Time.diff(finish, start, :millisecond)
        IO.puts("Benchmark: #{number_requests} requests in #{diff} ms")
    end
  end

  defp run(0, _, _, _), do: :ok
  defp run(n, host, port, mother) do
    spawn(fn()->request(n, host, port, mother) end)
    run(n-1, host, port, mother)
  end

  defp request(n, host, port, mother) do
    opt = [:list, active: false, reuseaddr: true]
    {:ok, server} = :gen_tcp.connect(host, port, opt)
    :gen_tcp.send(server, HTTP.get(host))
    {:ok, _reply} = :gen_tcp.recv(server, 0)
    :gen_tcp.close(server)
    if n == 1 do
      send(mother, :last_request)
    end
  end
end
