defmodule LmBackendWeb.Live.Setup do
  use LmBackendWeb, :live_view

  @impl true
  def mount(_param, session, socket) do
    user = session["user"]
    account_id = session["account"].id

    api_key = LmBackend.Accounts.get_api_key(user)

    agents = LmBackend.Accounts.AgentPresence.list(account_id)

    socket =
      socket
      |> assign(account_id: account_id)
      |> assign(api_key: api_key.key)
      |> assign(agents: agents)

    LmBackend.PubSub.subscribe_agent_presence(account_id)

    {:ok, socket}
  end

  @impl true
  def handle_info({:agent_presence, presence}, socket) do
    agents =
      socket.assigns.agents
      |> Enum.reject(&(&1.node_name == presence.node_name))
      |> then(&[presence | &1])

    {:noreply, assign(socket, agents: agents)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl mb-5">Setup</h2>
      <%!-- TODO: Host binary somewhere, link here --%>
      <p>
      To get started, download the agent from <.link class="link" navigate="#">here</.link>.
      Once downloaded, run the agent with the following environment variables set:
      </p>
      <pre id="instructions" class="bg-gray-300 p-2 my-3">
    LM_AGENT_DATA_DIR=/tmp/lm_agent \
    LM_ACCOUNT_ID=<%= @account_id %> \
    LM_API_KEY=<%= @api_key %> \
    ./agent_linux</pre>

      <.button id="copyToClipboard" phx-hook="CopyToClipboard" data-target="instructions" title="Copy to clipboard">
        <Heroicons.clipboard class="w-6 h-6" />
      </.button>

      <h3 class="mt-5 -mb-5 text-xl">
        Detected agents:
      </h3>

      <.table id="agents" rows={@agents}>
        <:col :let={agent} label="Name"><%= agent.node_name %></:col>
        <:col :let={agent} label="Last Seen"><%= agent.last_seen %></:col>
      </.table>

      <.link navigate={~p"/dashboards/new"}>
        <.button disabled={Enum.empty?(@agents)} class="disabled:bg-gray-400">Add Dashboard</.button>
      </.link>
    </div>
    """
  end
end
