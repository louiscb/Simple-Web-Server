defmodule Server do
  def start(port) do
    Process.register(spawn(fn -> init(port) end),:server)
  end

  def stop() do
    Process.exit(Process.whereis(:server), "Kill Server")
  end

  def init(port) do
    opt = [:list, active: false, reuseaddr: true]
    IO.write("Starting server... \n")
    case :gen_tcp.listen(port, opt) do
      {:ok, listen} ->
        handler(listen)
        :gen_tcp.close(listen)
        :ok
      {:error, error} ->
        error
    end
  end

  def handler(listen) do
    IO.write("Waiting for clients... \n")
    case :gen_tcp.accept(listen) do
      {:ok, client} ->
        request(client)
        handler(listen)
      {:error, error} ->
        error
    end
  end

  def request(client) do
    IO.write("Received client... \n")
    recieve = :gen_tcp.recv(client, 0)
    case recieve do
      {:ok, str} ->
        req = HTTP.parse_request(str)
        IO.inspect(req)
        response = reply(req)
        #IO.inspect response
        :gen_tcp.send(client, response)
        :gen_tcp.close(client)
      {:error, error} ->
        IO.puts("SERVER ERROR: #{error} \n")
    end
  end

  def reply(request) do
    time = get_time()
    :timer.sleep(10)
    HTTP.ok("<html> #{time} </html>")
  end

  def get_time do
    {{year, month, day}, {hour, minute, second}} = :calendar.universal_time()
    time = {hour, ':' , minute, ':', second}
    Enum.join(Tuple.to_list(time))
  end
end
