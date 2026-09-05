config: {
  context7 = {
    type = "remote";
    url = "https://mcp.context7.com/mcp";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder."llm/context7_apikey"}";
    };
    enabled = true;
  };

  deepwiki = {
    type = "remote";
    url = "https://mcp.deepwiki.com/mcp";
    headers = { };
    enabled = false;
  };

  exa = {
    type = "remote";
    url = "https://mcp.exa.ai/mcp";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder."llm/exa_apikey"}";
    };
    enabled = true;
  };

  capacities = {
    type = "remote";
    url = "https://api.capacities.io/mcp";
    headers = { };
    enabled = true;
  };

  linear = {
    type = "remote";
    url = "https://mcp.linear.app/mcp";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder."llm/linear_apikey"}";
    };
    enabled = true;
  };

  tavily = {
    type = "remote";
    url = "https://mcp.tavily.com/mcp";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder."llm/tavily_apikey"}";
    };
    enabled = false;
  };

  ticktick = {
    type = "remote";
    url = "https://mcp.ticktick.com";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder."llm/ticktick_apikey"}";
    };
    enabled = true;
  };
}
